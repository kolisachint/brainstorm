{{
    config(
        materialized='incremental',
        partition_by={
            'field': 'first_seen_date',
            'data_type': 'date',
            'granularity': 'day'
        },
        cluster_by=['party_id', 'visitor_id'],
        incremental_strategy='merge',
        unique_key=['party_id', 'visitor_id'],
        full_refresh=false
    )
}}

with identity_events as (
    select
        party_id,
        stitched_visitor_id as visitor_id,
        mcid,
        visitor_id as legacy_visitor_id,
        party_id_source,
        min(event_timestamp) as first_seen_ts,
        max(event_timestamp) as last_seen_ts,
        min(event_date) as first_seen_date,
        max(event_date) as last_seen_date,
        approx_count_distinct(session_id) as session_count,
        count(*) as event_count,
        count(distinct event_date) as active_days,
        max(geo_country) as last_known_country,
        max(browser_name) as last_known_browser,
        max(operating_system) as last_known_os,
        max(is_mobile) as last_known_is_mobile
    from {{ ref('stg_adobe_events') }}
    where event_date >= date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 30 day)
      and party_id is not null
    group by 
        party_id, 
        stitched_visitor_id, 
        mcid, 
        visitor_id, 
        party_id_source
)

select
    party_id,
    visitor_id,
    mcid,
    legacy_visitor_id,
    party_id_source as identity_source,
    first_seen_ts,
    last_seen_ts,
    first_seen_date,
    last_seen_date,
    session_count,
    event_count,
    active_days,
    last_known_country,
    last_known_browser,
    last_known_os,
    last_known_is_mobile,
    case 
        when first_seen_ts = last_seen_ts then 'single_session'
        when active_days = 1 then 'single_day_multi_session'
        else 'multi_day_returning'
    end as visitor_relationship_type,
    current_timestamp() as _loaded_at
from identity_events
