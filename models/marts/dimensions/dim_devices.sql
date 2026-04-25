{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['device_sk'],
        full_refresh=false
    )
}}

with devices as (
    select
        device_sk,
        browser_name as browser,
        operating_system as os,
        case
            when is_mobile then 'mobile'
            when browser_name like '%Tablet%' or browser_name like '%iPad%' then 'tablet'
            else 'desktop'
        end as device_type,
        is_mobile,
        current_timestamp() as etl_processed_at
    from {{ ref('stg_adobe_events') }}
    {% if is_incremental() %}
    where event_date >= date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 7 day)
    {% endif %}
    qualify row_number() over (partition by device_sk order by event_timestamp desc) = 1
)

select * from devices
