{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['page_sk'],
        full_refresh=false
    )
}}

with pages as (
    select
        page_sk,
        page_path,
        page_name,
        page_host,
        case
            when page_path = '/' then 'home'
            when page_path like '%/search%' then 'search'
            when page_path like '%/product/%' then 'product'
            when page_path like '%/category/%' then 'category'
            when page_path like '%/cart%' then 'cart'
            when page_path like '%/checkout%' then 'checkout'
            when page_path like '%/account%' then 'account'
            else 'content'
        end as page_type,
        split(page_path, '/')[safe_offset(1)] as page_section,
        split(page_path, '/')[safe_offset(2)] as page_subsection,
        current_timestamp() as etl_processed_at
    from {{ ref('stg_adobe_events') }}
    {% if is_incremental() %}
    where event_date >= date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 7 day)
    {% endif %}
    and page_path is not null
    qualify row_number() over (partition by page_sk order by event_timestamp desc) = 1
)

select distinct * from pages
