{{
    config(
        materialized='incremental',
        partition_by={
            'field': 'event_timestamp',
            'data_type': 'timestamp',
            'granularity': 'day'
        },
        cluster_by=['visitor_id', 'session_id'],
        incremental_strategy='insert_overwrite',
        full_refresh=false
    )
}}

select
    hit_id as event_id,
    stitched_visitor_id as visitor_id,
    party_id,
    party_id_source,
    session_id,
    event_timestamp,
    event_date,
    event_type,
    event_list,
    page_name,
    page_url,
    revenue,
    traffic_source,
    campaign_id,
    party_id,
    party_sk,
    is_late_arrival,
    page_sk,
    device_sk,
    channel_sk,
    geo_sk,
    campaign_sk
from {{ ref('stg_adobe_events') }}
where event_date >= date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 14 day)
