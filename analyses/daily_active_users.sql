select
    event_date,
    count(distinct visitor_id) as daily_active_users,
    count(*) as total_events,
    count(distinct session_id) as total_sessions,
    sum(revenue) as daily_revenue
from {{ ref('fct_events') }}
where event_date between date_sub(current_date(), interval 30 day) and current_date()
group by 1
order by 1 desc
