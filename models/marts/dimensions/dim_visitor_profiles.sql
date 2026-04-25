{{
    config(
        materialized='incremental',
        partition_by={
            'field': 'valid_from',
            'data_type': 'timestamp',
            'granularity': 'day'
        },
        cluster_by=['visitor_id', 'is_current'],
        incremental_strategy='merge',
        unique_key=['visitor_sk', 'valid_from'],
        full_refresh=false
    )
}}

with recent_events as (
    select *
    from {{ ref('stg_adobe_events') }}
    where event_date >= date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 14 day)
),

visitor_metrics as (
    select
        stitched_visitor_id as visitor_id,
        min(event_timestamp) as first_seen_ts,
        max(event_timestamp) as last_seen_ts,
        approx_count_distinct(session_id) as lifetime_sessions,
        count(*) as lifetime_events,
        count(distinct event_date) as lifetime_visits,
        max(geo_country) as preferred_country,
        max(browser_name) as preferred_browser,
        max(traffic_source) as preferred_channel,
        sum(coalesce(revenue, 0)) as lifetime_revenue,
        max(is_late_arrival) as has_late_arrivals
    from recent_events
    group by 1
),

new_profiles as (
    select
        {{ generate_surrogate_key(['visitor_id', 'cast(first_seen_ts as string)']) }} as visitor_sk,
        visitor_id,
        first_seen_ts,
        last_seen_ts,
        lifetime_sessions,
        lifetime_events,
        lifetime_visits,
        preferred_country,
        preferred_browser,
        preferred_channel,
        lifetime_revenue,
        current_timestamp() as valid_from,
        timestamp('9999-12-31 23:59:59') as valid_to,
        true as is_current,
        has_late_arrivals
    from visitor_metrics
)

select * from new_profiles
