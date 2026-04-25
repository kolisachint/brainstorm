DECLARE check_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);

SELECT
  'fct_events' as table_name,
  COUNT(*) as row_count,
  COUNT(DISTINCT event_id) as unique_ids,
  COUNT(*) - COUNT(DISTINCT event_id) as duplicate_count
FROM `project.dataset.fct_events`
WHERE event_date = check_date

UNION ALL

SELECT
  'fct_sessions' as table_name,
  COUNT(*) as row_count,
  COUNT(DISTINCT session_id) as unique_ids,
  COUNT(*) - COUNT(DISTINCT session_id) as duplicate_count
FROM `project.dataset.fct_sessions`
WHERE session_date = check_date

UNION ALL

SELECT
  'dim_visitor_profiles' as table_name,
  COUNT(*) as row_count,
  COUNT(DISTINCT visitor_sk) as unique_ids,
  COUNT(*) - COUNT(DISTINCT visitor_sk) as duplicate_count
FROM `project.dataset.dim_visitor_profiles`
WHERE DATE(valid_from) = check_date
