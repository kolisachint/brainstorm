{{
    config(
        materialized='incremental',
        partition_by={
            'field': 'valid_from',
            'data_type': 'timestamp',
            'granularity': 'day'
        },
        cluster_by=['party_id', 'is_current'],
        incremental_strategy='merge',
        unique_key=['party_sk', 'valid_from'],
        full_refresh=false
    )
}}

with party_events as (
    select *
    from {{ ref('stg_adobe_events') }}
    where event_date >= date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 30 day)
),

party_metrics as (
    select
        party_id,
        min(event_timestamp) as first_seen_ts,
        max(event_timestamp) as last_seen_ts,
        approx_count_distinct(session_id) as lifetime_sessions,
        count(*) as lifetime_events,
        count(distinct event_date) as lifetime_active_days,
        approx_count_distinct(stitched_visitor_id) as cross_device_visitors,
        max(geo_country) as preferred_country,
        max(browser_name) as preferred_browser,
        max(traffic_source) as preferred_channel,
        sum(coalesce(revenue, 0)) as lifetime_revenue,
        max(is_late_arrival) as has_late_arrivals
    from party_events
    where party_id is not null
    group by 1
),

party_mapping_enriched as (
    select
        pvp.party_id,
        array_agg(pvp.visitor_id order by
            case pvp.party_id_source
                when 'crm' then 1
                when 'loyalty' then 2
                when 'login' then 3
                when 'mcid' then 4
                else 5
            end
            limit 1
        )[offset(0)] as primary_visitor_id,
        count(distinct pvp.visitor_id) as visitor_id_count,
        count(distinct pvp.mcid) as mcid_count
    from {{ ref('party_visitor_mapping') }} pvp
    group by 1
),

new_profiles as (
    select
        {{ generate_surrogate_key(['p.party_id', 'cast(p.first_seen_ts as string)']) }} as party_sk,
        p.party_id,
        p.first_seen_ts,
        p.last_seen_ts,
        p.lifetime_sessions,
        p.lifetime_events,
        p.lifetime_active_days,
        p.cross_device_visitors,
        pme.primary_visitor_id,
        pme.visitor_id_count,
        pme.mcid_count,
        p.preferred_country,
        p.preferred_browser,
        p.preferred_channel,
        p.lifetime_revenue,
        current_timestamp() as valid_from,
        timestamp('9999-12-31 23:59:59') as valid_to,
        true as is_current,
        p.has_late_arrivals
    from party_metrics p
    left join party_mapping_enriched pme on p.party_id = pme.party_id
)

select * from new_profiles
