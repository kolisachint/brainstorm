DECLARE check_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);

SELECT
  browser_name,
  operating_system,
  COUNT(DISTINCT visitor_id) as unique_visitors,
  COUNT(*) as total_events,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pct_of_total
FROM `project.dataset.stg_adobe_events`
WHERE event_date = check_date
GROUP BY 1, 2
ORDER BY unique_visitors DESC
LIMIT 20
