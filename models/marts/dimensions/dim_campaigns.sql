{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['campaign_sk'],
        full_refresh=false
    )
}}

with campaigns as (
    select
        campaign_sk,
        campaign_id,
        campaign_source,
        campaign_medium,
        case
            when campaign_id like '%utm_%' then 'parsed'
            when campaign_id is not null then 'custom'
            else 'none'
        end as campaign_type,
        current_timestamp() as etl_processed_at
    from {{ ref('stg_adobe_events') }}
    {% if is_incremental() %}
    where event_date >= date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 7 day)
      and campaign_id is not null
    {% else %}
    where campaign_id is not null
    {% endif %}
    qualify row_number() over (partition by campaign_sk order by event_timestamp desc) = 1
)

select * from campaigns
