# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-26
**Commit:** 060628a
**Branch:** (git available)

## OVERVIEW
Adobe Analytics BigQuery data product using dbt. Transforms raw Adobe data into curated staging + mart layers with identity stitching and session resolution.

## STRUCTURE
```
./models/
├── staging/           # Single staging model (stg_adobe_events)
├── marts/
│   ├── dimensions/    # dim_pages, dim_devices, dim_channels, dim_geos, dim_campaigns, dim_visitor_profiles, dim_party_profiles
│   ├── facts/         # fct_events, fct_sessions, fct_identity_graph
│   └── bridge/        # party_visitor_mapping
├── intermediate/
macros/                 # generate_surrogate_key, calculate_revenue_from_products, parse macros
bigquery_sql/           # Ad-hoc queries (data_exploration, data_quality, maintenance, performance, validation)
seeds/                  # Reference data
```

## WHERE TO LOOK
| Task | Location |
|------|----------|
| Identity/stitching logic | `models/staging/stg_adobe_events.sql` (lines 18-21) |
| Surrogate key generation | `macros/generate_surrogate_key.sql` |
| Revenue calculation | `macros/calculate_revenue_from_products.sql` |
| Dimension models | `models/marts/dimensions/` |
| Fact models | `models/marts/facts/` |

## CODE MAP (Key Models)

| Model | Type | Purpose |
|-------|------|---------|
| `stg_adobe_events` | staging | Raw ingestion, deduplication, identity stitching, session stitching |
| `fct_events` | fact | Atomic event facts |
| `fct_sessions` | fact | Session aggregations |
| `fct_identity_graph` | fact | Cross-device identity resolution |
| `party_visitor_mapping` | bridge | Maps party IDs to visitor IDs with confidence levels |
| `dim_visitor_profiles` | dimension | SCD Type 2 visitor history |
| `dim_party_profiles` | dimension | SCD Type 2 party history |

## CONVENTIONS
- **Naming**: `stg_` prefix for staging, `dim_` for dimensions, `fct_` for facts, `party_` for party resolution
- **Materialization**: Incremental with `insert_overwrite` strategy
- **Partitioning**: By `event_date` (day granularity); party models partition on `valid_from`
- **Clustering**: By `visitor_id, session_id` in staging
- **Surrogate keys**: Pre-computed SKs in staging (page_sk, device_sk, geo_sk, channel_sk, campaign_sk)
- **Party ID priority**: crm > loyalty > login > mcid (when resolving primary visitor)

## ANTI-PATTERNS (THIS PROJECT)
- Don't modify `hit_id` - it's the deduplication key
- Don't change materialization without updating partition config
- Don't add late-arrival logic outside 14-day lookback window
- **dim_campaigns**: where clause must be inside conditional block (not after endif)

## COMMANDS
```bash
dbt deps              # Install dependencies
dbt seed              # Load reference data
dbt run               # Run all models
dbt test              # Run tests
dbt docs generate     # Generate docs
```

## NOTES
- Visitor ID priority: Marketing Cloud ID (mcid) > Legacy Visitor ID
- Session ID = stitched_visitor_id + visit_num
- 30-minute session timeout (Adobe default)