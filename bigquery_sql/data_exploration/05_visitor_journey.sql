DECLARE visitor_id_to_check STRING DEFAULT 'VISITOR_ID_HERE';
DECLARE lookback_days INT64 DEFAULT 30;

SELECT
  event_timestamp,
  session_id,
  event_type,
  page_name,
  page_url,
  traffic_source,
  campaign_id,
  revenue,
  geo_country,
  browser_name
FROM `project.dataset.stg_adobe_events`
WHERE visitor_id = visitor_id_to_check
  AND event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL lookback_days DAY)
ORDER BY event_timestamp
