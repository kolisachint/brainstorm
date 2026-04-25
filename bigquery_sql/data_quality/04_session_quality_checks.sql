-- Data Quality Check: Session Quality
-- Purpose: Identify suspicious sessions (too long, too many hits, etc.)

DECLARE check_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);

SELECT
  session_id,
  visitor_id,
  session_start_timestamp,
  session_end_timestamp,
  duration_sec,
  pageviews,
  session_revenue,
  bounce_flag,
  
  CASE
    WHEN duration_sec > 14400 THEN 'SUSPICIOUS: Session > 4 hours'
    WHEN pageviews > 500 THEN 'SUSPICIOUS: > 500 hits'
    WHEN session_revenue > 100000 THEN 'SUSPICIOUS: Revenue > $100K'
    WHEN duration_sec = 0 AND pageviews > 1 THEN 'WARNING: Zero duration with multiple hits'
    ELSE 'OK'
  END as session_quality_flag

FROM `project.dataset.fct_sessions`
WHERE session_date = check_date
  AND (
    duration_sec > 14400
    OR pageviews > 500
    OR session_revenue > 100000
    OR (duration_sec = 0 AND pageviews > 1)
  )
ORDER BY pageviews DESC, session_revenue DESC
LIMIT 100
