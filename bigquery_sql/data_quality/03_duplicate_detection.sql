-- Data Quality Check: Duplicate Detection
-- Purpose: Find duplicate events that may indicate ingestion issues

DECLARE check_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);

WITH duplicates AS (
  SELECT
    hit_id,
    COUNT(*) as occurrence_count,
    ARRAY_AGG(STRUCT(event_timestamp, _loaded_at) ORDER BY _loaded_at DESC) as occurrences
  FROM `project.dataset.stg_adobe_events`
  WHERE event_date = check_date
  GROUP BY 1
  HAVING COUNT(*) > 1
)

SELECT
  check_date as event_date,
  COUNT(*) as duplicate_hit_count,
  SUM(occurrence_count - 1) as excess_rows,
  AVG(occurrence_count) as avg_duplicates_per_hit,
  MAX(occurrence_count) as max_duplicates
FROM duplicates
