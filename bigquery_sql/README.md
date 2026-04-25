-- List all BigQuery SQL utility queries
-- Organized by category for easy navigation

## Data Quality (data_quality/)
1. event_volume_trends.sql - Detect volume anomalies
2. null_rate_monitoring.sql - Track null rates
3. duplicate_detection.sql - Find duplicate events
4. session_quality_checks.sql - Identify suspicious sessions
5. revenue_anomalies.sql - Detect revenue outliers

## Data Exploration (data_exploration/)
1. hourly_traffic_pattern.sql - Hourly breakdown
2. geographic_distribution.sql - Geo analysis
3. browser_os_breakdown.sql - Device breakdown
4. traffic_source_analysis.sql - Channel performance
5. visitor_journey.sql - Individual visitor timeline
6. session_detail.sql - Session-level detail

## Validation & Reconciliation (validation_reconciliation/)
1. staging_vs_marts_reconciliation.sql - Row count validation
2. uniqueness_checks.sql - Duplicate detection
3. referential_integrity.sql - FK validation

## Performance Monitoring (performance_monitoring/)
1. partition_sizes.sql - Storage analysis
2. query_cost_analysis.sql - Cost monitoring
3. column_statistics.sql - Column-level stats

## Maintenance (maintenance/)
1. identify_old_partitions.sql - Find expired data
2. gdpr_delete_visitor.sql - Delete visitor data

## Usage Instructions
1. Replace `project.dataset` with your actual project and dataset names
2. Set DECLARE variables at the top of each query
3. Run in BigQuery Console or Cloud Shell
