-- Revenue by Channel
-- Revenue attribution by marketing channel

select
    s.session_date,
    c.channel_name,
    c.channel_type,
    c.channel_group,
    count(distinct s.visitor_id) as unique_visitors,
    count(*) as sessions,
    sum(s.session_revenue) as total_revenue,
    avg(s.session_revenue) as avg_revenue_per_session,
    sum(s.session_revenue) / count(distinct s.visitor_id) as revenue_per_visitor
    from {{ ref('fct_sessions') }} s
    left join {{ ref('dim_channels') }} c on s.channel_sk = c.channel_sk
where s.session_date between date_sub(current_date(), interval 30 day) and current_date()
  and s.session_revenue > 0
group by 1, 2, 3, 4
order by 1 desc, 5 desc
