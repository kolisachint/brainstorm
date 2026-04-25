-- Data Quality Check: Null Rate Monitoring
-- Purpose: Track null rates for critical fields over time
-- High null rates may indicate data collection issues

DECLARE lookback_days INT64 DEFAULT 7;

SELECT
  event_date,
  COUNT(*) as total_events,
  
  -- Identity fields
  ROUND(100.0 * COUNTIF(visitor_id IS NULL) / COUNT(*), 2) as pct_null_visitor_id,
  ROUND(100.0 * COUNTIF(session_id IS NULL) / COUNT(*), 2) as pct_null_session_id,
  
  -- Page fields
  ROUND(100.0 * COUNTIF(page_name IS NULL) / COUNT(*), 2) as pct_null_page_name,
  ROUND(100.0 * COUNTIF(page_url IS NULL) / COUNT(*), 2) as pct_null_page_url,
  
  -- Geo fields
  ROUND(100.0 * COUNTIF(geo_country IS NULL) / COUNT(*), 2) as pct_null_country,
  ROUND(100.0 * COUNTIF(geo_city IS NULL) / COUNT(*), 2) as pct_null_city,
  
  -- Device fields
  ROUND(100.0 * COUNTIF(browser_name IS NULL) / COUNT(*), 2) as pct_null_browser,
  ROUND(100.0 * COUNTIF(operating_system IS NULL) / COUNT(*), 2) as pct_null_os,
  
  -- Revenue
  ROUND(100.0 * COUNTIF(revenue IS NULL) / COUNT(*), 2) as pct_null_revenue,
  COUNTIF(revenue > 0) as revenue_events

FROM `project.dataset.stg_adobe_events`
WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL lookback_days DAY)
GROUP BY 1
ORDER BY 1 DESC
