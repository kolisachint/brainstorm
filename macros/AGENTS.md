# Macros

Reusable SQL macros for Adobe Analytics BigQuery dbt project.

## Macro Reference

| Macro | Signature | Purpose |
|-------|-----------|---------|
| `generate_surrogate_key` | `generate_surrogate_key(fields)` | Creates deterministic 64-bit fingerprint keys from input fields for dimension joins. Uses `farm_fingerprint(concat(...))` with `coalesce` null handling. |
| `calculate_revenue_from_products` | `calculate_revenue_from_products(product_column)` | Extracts and sums revenue from Adobe product strings (format: `category;product;qty;price`). BigQuery only. |
| `parse_adobe_product_string` | `parse_adobe_product_string(product_column)` | Parses comma-separated Adobe product strings into array of structs with `category`, `product_name`, `quantity`, `price` fields. BigQuery only. |
| `parse_url_path` | `parse_url_path(url_column)` | Extracts path component from URL. Uses `net.path()` for BigQuery, `parse_url()` for other databases. |
| `parse_url_host` | `parse_url_host(url_column)` | Extracts hostname component from URL. Uses `net.host()` for BigQuery, `parse_url()` for other databases. |

## Usage Patterns

```sql
-- Surrogate key generation (pre-computed in staging)
{{ generate_surrogate_key(['page_url', 'page_name']) }} as page_sk

-- Revenue calculation from product strings
{{ calculate_revenue_from_products('product_string') }} as total_revenue

-- Product string parsing (for array operations)
products = {{ parse_adobe_product_string('product_string') }}

-- URL parsing
url_path = {{ parse_url_path('page_url') }}
url_host = {{ parse_url_host('page_url') }}
```

All macros include BigQuery-specific implementations with fallback to `null` or `0` for other database targets.