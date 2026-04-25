# Dimension Models

## OVERVIEW
Dimension models for Adobe Analytics pages, devices, channels, geos, campaigns, and visitor profiles with surrogate key lookups and type classifications.

## WHERE TO LOOK
| Model | Purpose |
|-------|---------|
| `dim_pages.sql` | Page dimension with path parsing and type classification (home, search, product, cart, checkout, account) |
| `dim_devices.sql` | Device and browser dimension |
| `dim_channels.sql` | Marketing channel dimension |
| `dim_geos.sql` | Geography dimension |
| `dim_campaigns.sql` | Campaign dimension |
| `dim_visitor_profiles.sql` | SCD Type 2 visitor profiles with lifetime metrics and change tracking |

## CONVENTIONS
- **Materialization**: Incremental with `merge` strategy and `unique_key` on surrogate key
- **Surrogate keys**: Join via pre-computed SKs from staging (page_sk, device_sk, geo_sk, channel_sk, campaign_sk) - do not regenerate in dimensions
- **Late-arrival handling**: 7-day lookback window in most dimensions; 14-day in dim_visitor_profiles
- **Deduplication**: QUALIFY `row_number() over (partition by sk order by event_timestamp desc) = 1` pattern
- **SCD Type 2** (dim_visitor_profiles only): Uses `valid_from`, `valid_to`, `is_current` columns; partitioned on `valid_from`
- **Type classifications**: Computed in dimension models (e.g., page_type in dim_pages) using case statements

## ANTI-PATTERNS
- Do not regenerate surrogate keys in dimension models - use the SKs pre-computed in stg_adobe_events
- Do not change the SCD Type 2 structure in dim_visitor_profiles (valid_from/valid_to/is_current columns are required)
- Do not remove the QUALIFY deduplication pattern - it ensures one row per surrogate key
- Do not increase lookback windows without updating partition config
