DECLARE check_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);

WITH orphan_events AS (
  SELECT 'fct_events' as fact_table, COUNT(*) as orphan_count
  FROM `project.dataset.fct_events` e
  LEFT JOIN `project.dataset.dim_pages` p ON e.page_sk = p.page_sk
  WHERE e.event_date = check_date AND p.page_sk IS NULL
),

orphan_sessions AS (
  SELECT 'fct_sessions' as fact_table, COUNT(*) as orphan_count
  FROM `project.dataset.fct_sessions` s
  LEFT JOIN `project.dataset.dim_devices` d ON s.device_sk = d.device_sk
  WHERE s.session_date = check_date AND d.device_sk IS NULL
)

SELECT * FROM orphan_events
UNION ALL
SELECT * FROM orphan_sessions
