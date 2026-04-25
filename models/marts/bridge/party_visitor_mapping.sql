{{
    config(
        materialized='incremental',
        partition_by={
            'field': 'first_seen_date',
            'data_type': 'date',
            'granularity': 'day'
        },
        cluster_by=['party_sk', 'visitor_sk'],
        incremental_strategy='merge',
        unique_key=['party_sk', 'visitor_sk'],
        full_refresh=false
    )
}}

with party_visitor_pairs as (
    select distinct
        party_id,
        stitched_visitor_id as visitor_id,
        min(event_date) over (partition by party_id, stitched_visitor_id) as first_seen_date,
        min(event_timestamp) over (partition by party_id, stitched_visitor_id) as first_seen_ts,
        max(event_timestamp) over (partition by party_id, stitched_visitor_id) as last_seen_ts,
        approx_count_distinct(session_id) over (partition by party_id, stitched_visitor_id) as session_count,
        count(*) over (partition by party_id, stitched_visitor_id) as event_count,
        max(case when party_id_source = 'crm' then 1 else 0 end) over (partition by party_id) as has_crm_id,
        max(case when party_id_source = 'loyalty' then 1 else 0 end) over (partition by party_id) as has_loyalty_id,
        max(case when party_id_source = 'login' then 1 else 0 end) over (partition by party_id) as has_login_id
    from {{ ref('stg_adobe_events') }}
    where event_date >= date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 30 day)
      and party_id is not null
),

enriched as (
    select
        pvp.party_id,
        pvp.visitor_id,
        {{ generate_surrogate_key(['pvp.party_id', 'cast(pvp.first_seen_ts as string)']) }} as party_sk,
        {{ generate_surrogate_key(['pvp.visitor_id', 'cast(pvp.first_seen_ts as string)']) }} as visitor_sk,
        pvp.first_seen_date,
        pvp.first_seen_ts,
        pvp.last_seen_ts,
        pvp.session_count,
        pvp.event_count,
        case 
            when pvp.has_crm_id = 1 then 'crm_enriched'
            when pvp.has_loyalty_id = 1 then 'loyalty_enriched'
            when pvp.has_login_id = 1 then 'login_enriched'
            else 'anonymous'
        end as identity_confidence_level,
        count(*) over (partition by pvp.party_id) as total_visitors_for_party,
        row_number() over (partition by pvp.party_id order by pvp.first_seen_ts) as visitor_sequence,
        current_timestamp() as _loaded_at
    from party_visitor_pairs pvp
)

select * from enriched
