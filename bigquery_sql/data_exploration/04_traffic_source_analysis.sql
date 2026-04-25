DECLARE check_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);

SELECT
  traffic_source,
  campaign_id,
  COUNT(DISTINCT visitor_id) as unique_visitors,
  COUNT(DISTINCT session_id) as sessions,
  COUNT(*) as total_events,
  SUM(revenue) as total_revenue,
  ROUND(SUM(revenue) / NULLIF(COUNT(DISTINCT session_id), 0), 2) as revenue_per_session
FROM `project.dataset.stg_adobe_events`
WHERE event_date = check_date
GROUP BY 1, 2
ORDER BY total_revenue DESC
LIMIT 25
