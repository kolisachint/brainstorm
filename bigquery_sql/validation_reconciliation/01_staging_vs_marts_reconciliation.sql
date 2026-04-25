DECLARE check_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);

WITH staging_counts AS (
  SELECT
    COUNT(*) as stg_total_events,
    COUNT(DISTINCT session_id) as stg_unique_sessions,
    SUM(revenue) as stg_total_revenue
  FROM `project.dataset.stg_adobe_events`
  WHERE event_date = check_date
),

fact_counts AS (
  SELECT
    COUNT(*) as fct_total_events
  FROM `project.dataset.fct_events`
  WHERE event_date = check_date
),

session_fact_counts AS (
  SELECT
    COUNT(*) as fct_total_sessions,
    SUM(session_revenue) as fct_total_revenue
  FROM `project.dataset.fct_sessions`
  WHERE session_date = check_date
)

SELECT
  check_date as event_date,
  s.stg_total_events,
  f.fct_total_events,
  s.stg_total_events - f.fct_total_events as event_diff,
  ROUND(100.0 * (s.stg_total_events - f.fct_total_events) / NULLIF(s.stg_total_events, 0), 2) as event_diff_pct,
  s.stg_unique_sessions,
  sf.fct_total_sessions,
  s.stg_unique_sessions - sf.fct_total_sessions as session_diff,
  ROUND(s.stg_total_revenue, 2) as stg_revenue,
  ROUND(sf.fct_total_revenue, 2) as fct_revenue,
  ROUND(s.stg_total_revenue - sf.fct_total_revenue, 2) as revenue_diff
FROM staging_counts s
CROSS JOIN fact_counts f
CROSS JOIN session_fact_counts sf
