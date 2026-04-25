-- Sessions Overview
-- Session-level metrics with channel and device breakdowns

select
    s.session_date,
    c.channel_type,
    d.device_type,
    count(*) as sessions,
    avg(s.duration_sec) as avg_session_duration_sec,
    avg(s.pageviews) as avg_pageviews_per_session,
    sum(case when s.bounce_flag then 1 else 0 end) / count(*) as bounce_rate,
    sum(s.session_revenue) as total_revenue
from {{ ref('session_fact') }} s
left join {{ ref('dim_channel') }} c on s.channel_sk = c.channel_sk
left join {{ ref('dim_device') }} d on s.device_sk = d.device_sk
where s.session_date between date_sub(current_date(), interval 30 day) and current_date()
group by 1, 2, 3
order by 1 desc, 4 desc
