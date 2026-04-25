{{
    config(
        materialized='incremental',
        partition_by={
            'field': 'session_start_timestamp',
            'data_type': 'timestamp',
            'granularity': 'day'
        },
        cluster_by=['visitor_id', 'session_id'],
        incremental_strategy='insert_overwrite',
        full_refresh=false
    )
}}

with session_events as (
    select
        session_id,
        stitched_visitor_id as visitor_id,
        party_id,
        party_id_source,
        event_timestamp,
        page_sequence_in_session,
        page_name,
        page_path,
        traffic_source,
        campaign_id,
        geo_country,
        geo_region,
        geo_city,
        browser_name,
        operating_system,
        is_mobile,
        revenue,
        event_type,
        is_late_arrival,
        page_sk,
        device_sk,
        channel_sk,
        geo_sk,
        campaign_sk
    from {{ ref('stg_adobe_events') }}
    where event_date >= date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 14 day)
),

session_first_hit as (
    select
        session_id,
        visitor_id,
        party_id,
        party_id_source,
        page_name as landing_page,
        page_path as landing_page_path,
        traffic_source,
        campaign_id,
        geo_country,
        geo_region,
        geo_city,
        browser_name,
        operating_system,
        is_mobile,
        page_sk as landing_page_sk,
        device_sk,
        channel_sk,
        geo_sk,
        campaign_sk
    from session_events
    qualify row_number() over (partition by session_id order by event_timestamp asc, page_sequence_in_session asc) = 1
),

session_last_hit as (
    select
        session_id,
        page_name as exit_page,
        page_path as exit_page_path,
        page_sk as exit_page_sk
    from session_events
    qualify row_number() over (partition by session_id order by event_timestamp desc, page_sequence_in_session desc) = 1
),

session_aggs as (
    select
        session_id,
        min(event_timestamp) as session_start_timestamp,
        max(event_timestamp) as session_end_timestamp,
        date(min(event_timestamp)) as session_date,
        timestamp_diff(max(event_timestamp), min(event_timestamp), second) as duration_sec,
        count(*) as pageviews,
        countif(event_type = 'page_view') as page_view_count,
        countif(event_type != 'page_view') as event_count,
        sum(coalesce(revenue, 0)) as session_revenue,
        max(is_late_arrival) as is_late_arrival,
        count(*) = 1 as bounce_flag
    from session_events
    group by 1
)

select
    a.session_id,
    a.visitor_id,
    f.party_id,
    f.party_id_source,
    a.session_start_timestamp,
    a.session_end_timestamp,
    a.session_date,
    a.duration_sec,
    a.pageviews,
    a.page_view_count,
    a.event_count,
    a.session_revenue,
    a.is_late_arrival,
    a.bounce_flag,
    f.landing_page,
    f.landing_page_path,
    f.traffic_source,
    f.campaign_id,
    f.geo_country,
    f.geo_region,
    f.geo_city,
    f.browser_name,
    f.operating_system,
    f.is_mobile,
    f.landing_page_sk,
    f.device_sk,
    f.channel_sk,
    f.geo_sk,
    f.campaign_sk,
    l.exit_page,
    l.exit_page_path,
    l.exit_page_sk
from session_aggs a
left join session_first_hit f using (session_id)
left join session_last_hit l using (session_id)
