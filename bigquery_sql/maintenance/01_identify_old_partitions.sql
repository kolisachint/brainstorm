DECLARE days_to_keep INT64 DEFAULT 365;
DECLARE partition_date DATE;

SET partition_date = DATE_SUB(CURRENT_DATE(), INTERVAL days_to_keep DAY);

SELECT
  'Partition older than ' || CAST(days_to_keep AS STRING) || ' days will be deleted: ' || CAST(partition_date AS STRING) as message,
  partition_id,
  total_rows,
  total_logical_bytes / POWER(1024, 3) as size_gb
FROM `project.dataset.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'stg_adobe_events'
  AND PARSE_DATE('%Y%m%d', partition_id) < partition_date
ORDER BY partition_id
