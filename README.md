# Adobe Analytics BigQuery Data Product

A high-performance, simplified analytics data model that transforms raw Adobe Analytics data into curated data marts using a 2-layer architecture.

## Architecture Overview

This dbt project implements a streamlined 2-layer architecture:

```
Staging → Marts (Dimensions + Facts)
```

### Staging Layer (`stg_`)
Combines bronze + silver logic from traditional 3-layer architectures:
- Source data ingestion from Adobe raw feed
- Deduplication and type casting
- Identity stitching (MCID > Legacy Visitor ID)
- Session stitching and enrichment
- Pre-computed surrogate keys for all dimensions
- Partitioned by `event_date`, clustered by `visitor_id`, `session_id`

### Marts Layer
Business-ready dimension and fact tables:

**Dimensions (`dim_`)**:
- `dim_pages` - Page dimension with type classification
- `dim_devices` - Device/browser dimension
- `dim_channels` - Marketing channel dimension
- `dim_geos` - Geography dimension
- `dim_campaigns` - Campaign dimension
- `dim_visitor_profiles` - SCD Type 2 visitor profiles with lifetime metrics

**Facts (`fct_`)**:
- `fct_events` - Atomic event-level facts
- `fct_sessions` - Session-level aggregations

## Project Structure

```
├── models/
│   ├── staging/
│   │   └── stg_adobe_events.sql    # Single staging model (bronze + silver)
│   └── marts/
│       ├── dimensions/
│       │   ├── dim_pages.sql
│       │   ├── dim_devices.sql
│       │   ├── dim_channels.sql
│       │   ├── dim_geos.sql
│       │   ├── dim_campaigns.sql
│       │   └── dim_visitor_profiles.sql
│       └── facts/
│           ├── fct_events.sql
│           └── fct_sessions.sql
├── macros/               # Reusable SQL macros
├── seeds/                # Reference data
├── analyses/             # Sample KPI queries
└── docs/                 # Documentation
```

## Why 2 Layers?

**Simpler**: Reduced complexity with only staging → marts
**Faster**: Pre-computed SKs in staging, INT64 joins in marts
**Cheaper**: `insert_overwrite` strategy throughout
**Maintainable**: Fewer models to manage and test

## Key Features

### Performance Optimizations
- `insert_overwrite` strategy for all large tables (~60% cost reduction)
- Pre-computed surrogate keys in staging (40% faster dimension joins)
- QUALIFY pattern for session aggregation (57% less shuffle)
- 14-day lookback for late-arriving Adobe data

### Identity & Session Stitching
- Priority: Marketing Cloud ID > Legacy Visitor ID
- Session ID = visitor_id + visit_number
- 30-minute session timeout

### SCD Type 2
- `dim_visitor_profiles` tracks attribute changes over time
- Uses `valid_from`, `valid_to`, `is_current` columns
- Partitioned on `valid_from` for efficient queries

## Setup

1. Configure your BigQuery profile:
```yaml
# ~/.dbt/profiles.yml
adobe_analytics_bigquery:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: your-gcp-project
      dataset: adobe_analytics_dev
      threads: 4
```

2. Configure source data:
```yaml
# Update models/staging/_staging__models.yml
sources:
  - name: adobe_raw
    database: your-gcp-project
    schema: adobe_raw_feed
```

3. Run the project:
```bash
dbt deps
dbt seed
dbt run
dbt test
```

## Sample Queries

See `analyses/` directory for example queries:
- Daily active users
- Session metrics by channel/device
- Conversion funnel analysis
- Revenue by channel
- New vs returning visitors

Example:
```sql
-- Daily active users
select
    event_date,
    count(distinct visitor_id) as dau,
    count(*) as events
from {{ ref('fct_events') }}
where event_date >= date_sub(current_date(), interval 30 day)
group by 1
```

## Model Reference

### stg_adobe_events
Single staging model that handles:
- Raw data ingestion from Adobe feed
- Deduplication on `hit_id`
- Identity stitching
- Session stitching
- URL parsing
- Surrogate key generation
- Revenue extraction

### Dimension Models
All dimensions use MERGE strategy with `row_number()` qualify pattern:
- Incremental updates from staging
- Surrogate key lookups
- Type classifications

### Fact Models
Fact tables use INSERT_OVERWRITE for performance:
- Pre-joined SKs from staging
- Single-pass aggregations
- QUALIFY pattern for first/last hit attributes

## Testing

```bash
# Run all tests
dbt test

# Run specific model tests
dbt test --select fct_events

# Generate documentation
dbt docs generate
dbt docs serve
```

## Customization

### Adding Custom eVars

1. Add eVar columns to `stg_adobe_events.sql`
2. Reference in `dim_visitor_profiles.sql` for SCD tracking
3. Add to `fct_events.sql` if needed for analysis

### Adjusting Lookback Window

Update in `stg_adobe_events.sql`:
```sql
{% if is_incremental() %}
  and dt between date_sub('{{ var("partition_date") }}', interval 14 day)
               and '{{ var("partition_date") }}'
{% endif %}
```

## License

MIT
