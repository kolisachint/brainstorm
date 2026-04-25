DECLARE check_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);

SELECT
  geo_country as country,
  geo_region as region,
  COUNT(DISTINCT visitor_id) as unique_visitors,
  COUNT(*) as total_events,
  COUNT(DISTINCT session_id) as sessions,
  SUM(revenue) as total_revenue,
  ROUND(SUM(revenue) / COUNT(DISTINCT visitor_id), 2) as revenue_per_visitor
FROM `project.dataset.stg_adobe_events`
WHERE event_date = check_date
  AND geo_country IS NOT NULL
GROUP BY 1, 2
HAVING COUNT(*) > 100
ORDER BY unique_visitors DESC
LIMIT 50
