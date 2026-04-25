{{
    config(
        materialized='incremental',
        partition_by={
            'field': 'event_date',
            'data_type': 'date',
            'granularity': 'day'
        },
        cluster_by=['visitor_id', 'session_id'],
        incremental_strategy='insert_overwrite',
        full_refresh=false
    )
}}

with raw_data as (
    select
        concat(hitid_high, '-', hitid_low) as hit_id,
        concat(coalesce(post_visid_high, visid_high), '-', coalesce(post_visid_low, visid_low)) as visitor_id,
        marketing_cloud_visitor_id as mcid,
        coalesce(marketing_cloud_visitor_id, concat(coalesce(post_visid_high, visid_high), '-', coalesce(post_visid_low, visid_low))) as stitched_visitor_id,
        concat(coalesce(marketing_cloud_visitor_id, concat(coalesce(post_visid_high, visid_high), '-', coalesce(post_visid_low, visid_low))), '-', cast(visit_num as string)) as session_id,
        timestamp_seconds(hit_time_gmt) as event_timestamp,
        dt as event_date,
        extract(hour from timestamp_seconds(hit_time_gmt)) as event_hour,
        visit_num as session_number,
        visit_page_num as page_sequence_in_session,
        case 
            when page_event = 0 then 'page_view'
            when page_event = 10 then 'link_click'
            when page_event = 11 then 'download'
            when page_event = 12 then 'exit_link'
            when page_event = 13 then 'custom_link'
            else 'other'
        end as event_type,
        split(coalesce(post_event_list, event_list), ',') as event_list,
        post_page_url as page_url,
        post_pagename as page_name,
        net.host(post_page_url) as page_host,
        net.path(post_page_url) as page_path,
        post_referrer as referrer_url,
        net.host(post_referrer) as referrer_host,
        case 
            when post_referrer is null then 'direct'
            when post_search_engine is not null then 'organic_search'
            when post_campaign is not null then 'paid'
            else 'referral'
        end as traffic_source,
        post_search_engine as search_engine,
        post_keywords as search_keywords,
        post_campaign as campaign_id,
        post_campaign_source as campaign_source,
        post_campaign_medium as campaign_medium,
        coalesce(post_campaign_source, case when post_referrer is null then 'direct' when post_search_engine is not null then 'organic_search' when post_campaign is not null then 'paid' else 'referral' end) as attributed_source,
        country as geo_country,
        region as geo_region,
        city as geo_city,
        geo_zip as geo_postal_code,
        browser as browser_name,
        os as operating_system,
        mobile_id is not null as is_mobile,
        {{ calculate_revenue_from_products('post_product_list') }} as revenue,
        coalesce(
            nullif(trim(post_evar1), ''),
            nullif(trim(post_evar20), ''),
            nullif(trim(post_evar5), ''),
            nullif(marketing_cloud_visitor_id, ''),
            concat(coalesce(post_visid_high, visid_high), '-', coalesce(post_visid_low, visid_low))
        ) as party_id,
        case 
            when post_evar1 is not null and trim(post_evar1) != '' then 'crm'
            when post_evar20 is not null and trim(post_evar20) != '' then 'loyalty'
            when post_evar5 is not null and trim(post_evar5) != '' then 'login'
            when marketing_cloud_visitor_id is not null then 'mcid'
            else 'legacy_visitor'
        end as party_id_source,
        post_evar1, post_evar2, post_evar3, post_evar4, post_evar5,
        post_evar10, post_evar20, post_evar50,
        post_prop1, post_prop2, post_prop3, post_prop4, post_prop5,
        nullif(post_evar1, '') as party_id,
        case when nullif(post_evar1, '') is not null
             then {{ generate_surrogate_key(['nullif(post_evar1, \'\')']) }}
        end as party_sk,
        {{ generate_surrogate_key(['net.path(post_page_url)', 'post_pagename']) }} as page_sk,
        {{ generate_surrogate_key(['browser', 'os', 'cast(mobile_id is not null as string)']) }} as device_sk,
        {{ generate_surrogate_key(['country', 'region', 'city']) }} as geo_sk,
        {{ generate_surrogate_key(['coalesce(post_campaign_source, case when post_referrer is null then \'direct\' when post_search_engine is not null then \'organic_search\' when post_campaign is not null then \'paid\' else \'referral\' end)', 'case when post_referrer is null then \'direct\' when post_search_engine is not null then \'organic_search\' when post_campaign is not null then \'paid\' else \'referral\' end']) }} as channel_sk,
        {{ generate_surrogate_key(['post_campaign']) }} as campaign_sk,
        false as is_late_arrival,
        current_timestamp() as _loaded_at
    from {{ source('adobe_raw', 'hit_data') }}
    where (exclude_hit is null or exclude_hit = 0)
    {% if is_incremental() %}
      and dt between date_sub('{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}', interval 14 day)
                   and '{{ var("partition_date", run_started_at.strftime("%Y-%m-%d")) }}'
    {% endif %}
),

deduplicated as (
    select * except(rn)
    from (
        select *, row_number() over (partition by hit_id order by _loaded_at desc) as rn
        from raw_data
    )
    where rn = 1
)

select * from deduplicated
