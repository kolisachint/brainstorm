-- Data Quality Check: Revenue Anomalies
-- Purpose: Detect unusual revenue patterns

DECLARE check_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);

WITH revenue_stats AS (
  SELECT
    event_date,
    COUNTIF(revenue > 0) as revenue_events,
    COUNT(*) as total_events,
    SUM(revenue) as total_revenue,
    AVG(revenue) as avg_revenue_per_event,
    APPROX_QUANTILES(revenue, 100)[OFFSET(99)] as p99_revenue,
    MAX(revenue) as max_revenue
  FROM `project.dataset.stg_adobe_events`
  WHERE event_date >= check_date
  GROUP BY 1
)

SELECT
  event_date,
  revenue_events,
  total_events,
  ROUND(100.0 * revenue_events / total_events, 2) as pct_revenue_events,
  total_revenue,
  ROUND(avg_revenue_per_event, 2) as avg_revenue,
  ROUND(p99_revenue, 2) as p99_revenue,
  max_revenue,
  CASE
    WHEN max_revenue > 10 * p99_revenue THEN 'ALERT: Extreme outlier'
    WHEN total_revenue = 0 AND revenue_events > 0 THEN 'ALERT: Revenue events but zero total'
    ELSE 'OK'
  END as status
FROM revenue_stats
ORDER BY event_date DESC
