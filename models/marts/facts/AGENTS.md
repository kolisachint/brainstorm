# Fact Models

## OVERVIEW
Event-level (fct_events) and session-level (fct_sessions) aggregations with pre-computed surrogate keys for dimension joins.

## WHERE TO LOOK
| Model | Purpose |
|-------|---------|
| `fct_events` | Atomic events with pre-joined SKs |
| `fct_sessions` | Session aggregations via QUALIFY pattern |

## CONVENTIONS
- **Materialization**: INSERT_OVERWRITE
- **Partitioning**: By `event_date` (day)
- **Clustering**: On `visitor_id, session_id`
- **SKs**: Pre-joined from staging (page_sk, device_sk, geo_sk, channel_sk, campaign_sk)
- **QUALIFY**: Used in fct_sessions for deduplication

## ANTI-PATTERNS
- Don't bypass pre-computed SKs and re-join to dimensions directly
- Don't use LEFT JOINs that introduce nulls in fact metrics without approval
- Don't modify hit_id (deduplication key)
- Don't change partition strategy without updating dependent models