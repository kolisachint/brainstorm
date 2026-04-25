# Adobe Analytics Data Product - ERD

## Star Schema Overview

```
                    ┌─────────────────────┐
                    │   dim_campaign      │
                    │  (campaign_sk, PK)  │
                    └──────────┬──────────┘
                               │
                    ┌──────────┴──────────┐
                    │   dim_channel       │
                    │  (channel_sk, PK)   │
                    └──────────┬──────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│   dim_page   │────▶│    event_fact    │◀────│  dim_device  │
│ (page_sk, PK)│     │  (event_id, PK)  │     │(device_sk,PK)│
└──────────────┘     └────────┬─────────┘     └──────────────┘
                              │
                              │ visitor_sk (FK)
                              ▼
                    ┌──────────────────┐
                    │  visitor_profile │
                    │(visitor_sk, PK)  │
                    │  SCD Type 2      │
                    └────────┬─────────┘
                             │
                             │ visitor_sk (FK)
                             ▼
                    ┌──────────────────┐
                    │   session_fact   │
                    │ (session_id, PK) │
                    └────────┬─────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   dim_geo    │    │   dim_page   │    │  dim_channel │
│  (geo_sk,PK) │    │(entry_page)  │    │(landing_ch)  │
└──────────────┘    └──────────────┘    └──────────────┘
```

## Table Relationships

### event_fact (Atomic Events)
| Column | Type | Reference |
|--------|------|-----------|
| event_id | STRING (PK) | |
| visitor_id | STRING | visitor_profile.visitor_id |
| session_id | STRING | session_fact.session_id |
| page_sk | INT64 | dim_page.page_sk |
| device_sk | INT64 | dim_device.device_sk |
| channel_sk | INT64 | dim_channel.channel_sk |
| geo_sk | INT64 | dim_geo.geo_sk |
| campaign_sk | INT64 | dim_campaign.campaign_sk |

### session_fact (Session Aggregations)
| Column | Type | Reference |
|--------|------|-----------|
| session_id | STRING (PK) | |
| visitor_id | STRING | visitor_profile.visitor_id |
| landing_page_sk | INT64 | dim_page.page_sk |
| exit_page_sk | INT64 | dim_page.page_sk |
| device_sk | INT64 | dim_device.device_sk |
| channel_sk | INT64 | dim_channel.channel_sk |
| geo_sk | INT64 | dim_geo.geo_sk |
| campaign_sk | INT64 | dim_campaign.campaign_sk |

### visitor_profile (SCD Type 2)
| Column | Type | Description |
|--------|------|-------------|
| visitor_sk | INT64 (PK) | Surrogate key |
| visitor_id | STRING | Natural key |
| valid_from | TIMESTAMP | SCD start |
| valid_to | TIMESTAMP | SCD end |
| is_current | BOOL | Current flag |

## Partitioning Strategy

| Table | Partition Column | Clustering |
|-------|-----------------|------------|
| bronze_adobe_hit_data | dt (DATE) | visitor_id |
| silver_adobe_events | event_date (DATE) | visitor_id, session_id |
| gold_event_fact | event_date (DATE) | visitor_id, session_id |
| gold_session_fact | session_date (DATE) | visitor_id, channel_sk |
| gold_visitor_profile | DATE(valid_from) | visitor_id, is_current |

## Grain Definitions

- **event_fact**: One row per Adobe Analytics hit
- **session_fact**: One row per visit (visit_num per visitor)
- **visitor_profile**: One row per SCD version of visitor
- **Dimension tables**: One row per unique dimension value
