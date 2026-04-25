SELECT
  job_id,
  creation_time,
  query,
  user_email,
  total_bytes_processed / POWER(1024, 3) as gb_processed,
  total_bytes_billed / POWER(1024, 3) as gb_billed,
  (total_slot_ms / 1000) / 60 as slot_minutes,
  query_priority,
  state
FROM `region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
  AND job_type = 'QUERY'
  AND query LIKE '%stg_adobe_events%'
ORDER BY total_bytes_billed DESC
LIMIT 20
