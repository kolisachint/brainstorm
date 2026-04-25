DECLARE table_name STRING DEFAULT 'project.dataset.stg_adobe_events';

SELECT
  table_name,
  partition_id,
  total_rows,
  total_logical_bytes,
  total_logical_bytes / POWER(1024, 3) as size_gb,
  last_modified_time,
  storage_tier
FROM `project.dataset.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'stg_adobe_events'
ORDER BY partition_id DESC
LIMIT 30
