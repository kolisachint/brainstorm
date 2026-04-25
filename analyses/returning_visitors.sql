-- Returning Visitors Analysis
-- New vs returning visitor metrics

with visitor_first_seen as (
    select
        visitor_id,
        min(session_date) as first_session_date
    from {{ ref('session_fact') }}
    group by 1
)

select
    s.session_date,
    case
        when s.session_date = v.first_session_date then 'new'
        else 'returning'
    end as visitor_type,
    count(distinct s.visitor_id) as visitors,
    count(*) as sessions,
    avg(s.pageviews) as avg_pageviews,
    avg(s.duration_sec) as avg_duration_sec,
    sum(s.session_revenue) as total_revenue
from {{ ref('session_fact') }} s
join visitor_first_seen v on s.visitor_id = v.visitor_id
where s.session_date between date_sub(current_date(), interval 30 day) and current_date()
group by 1, 2
order by 1 desc, 2
