# Cross-Device Identity Resolution

This document describes the cross-device identity resolution system built on top of Adobe Analytics data.

## Overview

The identity resolution system maps multiple visitor IDs (devices/cookies) to a single Party ID (customer), enabling cross-device journey analysis and unified customer metrics.

## Identity Hierarchy

Party ID is resolved using the following priority:

1. **CRM Customer ID** (post_evar1) - Highest trust
2. **Loyalty Program ID** (post_evar20) - Medium trust
3. **Login/User ID** (post_evar5) - Medium trust
4. **Adobe MCID** (marketing_cloud_visitor_id) - Device-level
5. **Legacy Visitor ID** - Fallback

## Models

### Staging Layer

**stg_adobe_events** - Updated to extract Party ID
- `party_id`: Resolved identifier using hierarchy above
- `party_id_source`: Source of the party identifier (crm, loyalty, login, mcid, legacy_visitor)

### Marts Layer

#### dim_party_profiles
SCD Type 2 dimension tracking party-level metrics across all devices.

| Column | Description |
|--------|-------------|
| `party_sk` | Surrogate key |
| `party_id` | Natural key (resolved party identifier) |
| `cross_device_visitors` | Number of unique visitor IDs associated with this party |
| `lifetime_sessions` | Total sessions across all devices |
| `lifetime_events` | Total events across all devices |
| `lifetime_revenue` | Total revenue across all devices |
| `primary_id_source` | Highest-confidence identity source for this party |

#### fct_identity_graph
Fact table mapping relationships between Party ID and individual Visitor IDs.

| Column | Description |
|--------|-------------|
| `party_id` | Resolved party identifier |
| `visitor_id` | Adobe visitor ID (device/cookie) |
| `identity_source` | Source that linked this visitor to the party |
| `first_seen_ts` | First time this visitor was seen for this party |
| `last_seen_ts` | Most recent activity |
| `visitor_relationship_type` | single_session, single_day_multi_session, or multi_day_returning |

#### party_visitor_mapping
Bridge table enabling many-to-many relationships between parties and visitors.

| Column | Description |
|--------|-------------|
| `party_sk` | Party surrogate key |
| `visitor_sk` | Visitor surrogate key |
| `identity_confidence_level` | crm_enriched, loyalty_enriched, login_enriched, or anonymous |
| `total_visitors_for_party` | Total visitors associated with this party |

#### fct_events (Updated)
Now includes `party_id` and `party_id_source` for event-level party attribution.

#### fct_sessions (Updated)
Now includes `party_id` and `party_id_source` for session-level party attribution.

## Usage Examples

### Cross-Device Journey Analysis

```sql
-- Analyze a customer's journey across devices
select * from {{ ref('cross_device_journey') }}
-- Set var party_id = 'your-party-id-here'
```

### Identity Confidence Summary

```sql
-- Summary of identity resolution confidence levels
select * from {{ ref('identity_confidence_summary') }}
```

### Party-Level Metrics vs Visitor-Level

```sql
-- Compare party-level to visitor-level metrics
select
    p.party_id,
    p.cross_device_visitors,
    p.lifetime_revenue as party_revenue,
    sum(v.lifetime_revenue) as sum_visitor_revenue
from {{ ref('dim_party_profiles') }} p
join {{ ref('party_visitor_mapping') }} m on p.party_sk = m.party_sk
join {{ ref('dim_visitor_profiles') }} v on m.visitor_sk = v.visitor_sk
where p.is_current = true and v.is_current = true
group by 1, 2, 3
```

## Implementation Notes

### eVar Configuration

Ensure these eVars are populated in Adobe Analytics:
- **eVar1**: CRM Customer ID (set on authenticated interactions)
- **eVar5**: User ID / Login ID (set on login)
- **eVar20**: Loyalty Program ID (if applicable)

### Data Quality Considerations

1. **Anonymous Users**: Users without CRM/Login IDs will have party_id = visitor_id
2. **Shared Devices**: Multiple parties on same device require login identification
3. **Identity Gaps**: Users not logging in across devices won't be stitched
4. **Late Arrivals**: Identity resolution uses 30-day lookback window

### Privacy & GDPR

To delete a party and all associated data:

```sql
-- Get all visitor IDs for a party
select visitor_id from {{ ref('fct_identity_graph') }} where party_id = 'party-to-delete';

-- Delete from all tables (cascade by visitor_id)
```

## Performance

- All identity tables are partitioned by `first_seen_date` or `valid_from`
- Clustered by `party_id` and `visitor_id` for efficient lookups
- Incremental processing with 30-day lookback for late-arriving data
