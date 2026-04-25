DECLARE table_name STRING DEFAULT 'stg_adobe_events';

SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  ROUND(100.0 * null_count / total_rows, 2) as pct_null
FROM `project.dataset.INFORMATION_SCHEMA.COLUMNS` c
JOIN (
  SELECT COUNT(*) as total_rows FROM `project.dataset.stg_adobe_events` WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
) t ON TRUE
LEFT JOIN (
  SELECT 
    'visitor_id' as col, COUNTIF(visitor_id IS NULL) as null_count FROM `project.dataset.stg_adobe_events` WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  UNION ALL
  SELECT 'session_id', COUNTIF(session_id IS NULL) FROM `project.dataset.stg_adobe_events` WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
) n ON c.column_name = n.col
WHERE table_name = 'stg_adobe_events'
ORDER BY column_name
