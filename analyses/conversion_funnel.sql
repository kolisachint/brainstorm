-- Conversion Funnel Analysis
-- Multi-step conversion funnel from landing to purchase

with funnel_steps as (
    select
        visitor_id,
        session_id,
        max(case when page_type = 'home' then 1 else 0 end) as step_1_home,
        max(case when page_type = 'product' then 1 else 0 end) as step_2_product,
        max(case when page_type = 'cart' then 1 else 0 end) as step_3_cart,
        max(case when page_type = 'checkout' then 1 else 0 end) as step_4_checkout,
        max(case when revenue > 0 then 1 else 0 end) as step_5_purchase
    from {{ ref('fct_events') }} e
    left join {{ ref('dim_pages') }} p on e.page_sk = p.page_sk
    where event_date between date_sub(current_date(), interval 7 day) and current_date()
    group by 1, 2
)

select
    count(*) as total_sessions,
    sum(step_1_home) as step_1_home,
    sum(step_2_product) as step_2_product,
    sum(step_3_cart) as step_3_cart,
    sum(step_4_checkout) as step_4_checkout,
    sum(step_5_purchase) as step_5_purchase,
    round(sum(step_1_home) * 100.0 / count(*), 2) as pct_step_1,
    round(sum(step_2_product) * 100.0 / sum(step_1_home), 2) as pct_step_2,
    round(sum(step_3_cart) * 100.0 / sum(step_2_product), 2) as pct_step_3,
    round(sum(step_4_checkout) * 100.0 / sum(step_3_cart), 2) as pct_step_4,
    round(sum(step_5_purchase) * 100.0 / sum(step_4_checkout), 2) as pct_step_5
from funnel_steps
