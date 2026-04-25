-- Data Quality Check: Event Volume Trends
-- Purpose: Detect sudden drops or spikes in event volume
-- Run this daily to catch ingestion issues

DECLARE lookback_days INT64 DEFAULT 30;

WITH daily_counts AS (
  SELECT
    event_date,
    COUNT(*) as total_events,
    COUNT(DISTINCT visitor_id) as unique_visitors,
    COUNT(DISTINCT session_id) as unique_sessions,
    SUM(revenue) as total_revenue
  FROM `project.dataset.stg_adobe_events`
  WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL lookback_days DAY)
  GROUP BY 1
),

with_stats AS (
  SELECT
    *,
    AVG(total_events) OVER (ORDER BY event_date ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING) as avg_events_7d,
    STDDEV(total_events) OVER (ORDER BY event_date ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING) as stddev_events_7d
  FROM daily_counts
)

SELECT
  event_date,
  total_events,
  unique_visitors,
  unique_sessions,
  total_revenue,
  ROUND((total_events - avg_events_7d) / NULLIF(stddev_events_7d, 0), 2) as z_score_events,
  CASE 
    WHEN ABS((total_events - avg_events_7d) / NULLIF(stddev_events_7d, 0)) > 3 THEN 'ALERT: Anomaly detected'
    WHEN ABS((total_events - avg_events_7d) / NULLIF(stddev_events_7d, 0)) > 2 THEN 'WARNING: Unusual volume'
    ELSE 'OK'
  END as status
FROM with_stats
WHERE avg_events_7d IS NOT NULL
ORDER BY event_date DESC
