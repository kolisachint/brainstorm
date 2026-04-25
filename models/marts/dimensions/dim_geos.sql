{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['geo_sk'],
        full_refresh=false
    )
}}

with geos as (
    select
        geo_sk,
        geo_country as country,
        geo_region as region,
        geo_city as city,
        geo_postal_code as postal_code,
        current_timestamp() as etl_processed_at
    from {{ ref('stg_adobe_events') }}
    {% if is_incremental() %}
    where event_date >= date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 7 day)
    {% endif %}
    qualify row_number() over (partition by geo_sk order by event_timestamp desc) = 1
)

select distinct * from geos
