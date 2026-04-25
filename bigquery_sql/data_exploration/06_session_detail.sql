DECLARE session_id_to_check STRING DEFAULT 'SESSION_ID_HERE';

SELECT
  event_timestamp,
  page_sequence_in_session,
  event_type,
  page_name,
  page_url,
  traffic_source,
  campaign_id,
  revenue
FROM `project.dataset.stg_adobe_events`
WHERE session_id = session_id_to_check
ORDER BY event_timestamp
