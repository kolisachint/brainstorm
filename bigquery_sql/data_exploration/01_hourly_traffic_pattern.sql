DECLARE start_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);
DECLARE end_date DATE DEFAULT CURRENT_DATE();

SELECT
  event_date,
  event_hour,
  COUNT(*) as events,
  COUNT(DISTINCT visitor_id) as unique_visitors,
  COUNT(DISTINCT session_id) as unique_sessions,
  ROUND(100.0 * COUNT(DISTINCT session_id) / COUNT(DISTINCT visitor_id), 2) as sessions_per_visitor,
  SUM(revenue) as revenue
FROM `project.dataset.stg_adobe_events`
WHERE event_date BETWEEN start_date AND end_date
GROUP BY 1, 2
ORDER BY 1 DESC, 2
