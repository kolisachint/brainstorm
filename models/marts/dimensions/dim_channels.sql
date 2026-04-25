{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['channel_sk'],
        full_refresh=false
    )
}}

with channels as (
    select
        channel_sk,
        attributed_source as channel_name,
        traffic_source as channel_type,
        case
            when traffic_source = 'paid' then 'paid'
            when traffic_source = 'organic_search' then 'organic'
            when traffic_source = 'referral' then 'organic'
            else traffic_source
        end as channel_group,
        current_timestamp() as etl_processed_at
    from {{ ref('stg_adobe_events') }}
    {% if is_incremental() %}
    where event_date >= date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 7 day)
    {% endif %}
    qualify row_number() over (partition by channel_sk order by event_timestamp desc) = 1
)

select distinct * from channels
