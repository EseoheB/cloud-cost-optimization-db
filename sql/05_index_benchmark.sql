-- ============================================================================
-- 05_index_benchmark.sql
-- Measures how much the USAGE_EVENT indexes speed up cost queries at scale.
--
-- The sample data has only 21 usage events, which is too small to show any
-- index effect. This script builds a separate table with 2,000,000 synthetic
-- events spread across 24 months and the 22 seeded resources, times two
-- queries with no secondary indexes, adds the same two indexes defined on
-- USAGE_EVENT, and times them again.
--
-- The benchmark table has no foreign keys, so InnoDB creates no automatic
-- index on FK_Resource_ID. The "before" runs are a true no-index baseline.
--
-- Requires MySQL 8.0.18+ for EXPLAIN ANALYZE. The data load takes a minute or
-- two. EXPLAIN ANALYZE runs each query for real and prints the actual time.
-- Run each timed query twice and record the second result, so both runs read
-- from a warm buffer pool.
-- ============================================================================

USE cloud_resource_management;

-- Fixed time zone so generated timestamps never fall into a daylight saving gap
SET time_zone = '+00:00';

-- ----------------------------------------------------------------------------
-- 1. Build the benchmark table (no secondary indexes)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS usage_event_bench;
DROP TABLE IF EXISTS bench_digits;

CREATE TABLE bench_digits (d TINYINT PRIMARY KEY);
INSERT INTO bench_digits VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

CREATE TABLE usage_event_bench (
    Event_ID BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    FK_Resource_ID INT NOT NULL,
    FK_Pricing_Tier_ID INT NOT NULL,
    Event_Timestamp TIMESTAMP NOT NULL,
    Quantity_Consumed DECIMAL(15,6) NOT NULL,
    Calculated_Cost DECIMAL(12,4) NOT NULL,
    Event_Source VARCHAR(100)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 2. Generate 2,000,000 deterministic synthetic events
--    n runs from 0 to 1,999,999. Resource IDs cycle through 1-22, timestamps
--    spread evenly over the hours from Dec 2023 to Nov 2025, and costs range
--    from $0.50 to $10.49. The same rows are produced on every run.
-- ----------------------------------------------------------------------------
INSERT INTO usage_event_bench
    (FK_Resource_ID, FK_Pricing_Tier_ID, Event_Timestamp,
     Quantity_Consumed, Calculated_Cost, Event_Source)
SELECT
    1 + MOD(n * 7919, 22),
    1 + MOD(n, 16),
    TIMESTAMP('2023-12-01 00:00:00') + INTERVAL MOD(n * 37, 731 * 24) HOUR,
    24.000000,
    0.50 + MOD(n * 13, 1000) / 100,
    'synthetic_benchmark'
FROM (
    SELECT a.d + 10*b.d + 100*c.d + 1000*e.d + 10000*f.d
           + 100000*g.d + 1000000*h.d AS n
    FROM bench_digits a, bench_digits b, bench_digits c, bench_digits e,
         bench_digits f, bench_digits g, bench_digits h
    WHERE h.d < 2
) numbers;

SELECT COUNT(*) AS Bench_Rows,
       MIN(Event_Timestamp) AS First_Event,
       MAX(Event_Timestamp) AS Last_Event
FROM usage_event_bench;

ANALYZE TABLE usage_event_bench;

-- ----------------------------------------------------------------------------
-- 3. BEFORE: no secondary indexes
-- ----------------------------------------------------------------------------

-- Query A: top cost resources for one month (same logic as Analytics Query 3)
EXPLAIN ANALYZE
SELECT
    resource.Resource_Name,
    SUM(bench.Calculated_Cost) AS Month_Cost
FROM usage_event_bench bench
INNER JOIN RESOURCE resource
    ON bench.FK_Resource_ID = resource.Resource_ID
WHERE bench.Event_Timestamp >= '2024-11-01'
  AND bench.Event_Timestamp <  '2024-12-01'
GROUP BY resource.Resource_Name
ORDER BY Month_Cost DESC
LIMIT 20;

-- Query B: one resource's cost for one month (same pattern as Use Case Step 3)
EXPLAIN ANALYZE
SELECT
    COUNT(*) AS Events,
    SUM(bench.Calculated_Cost) AS Month_Cost
FROM usage_event_bench bench
WHERE bench.FK_Resource_ID = 4
  AND bench.Event_Timestamp >= '2024-11-01'
  AND bench.Event_Timestamp <  '2024-12-01';

-- ----------------------------------------------------------------------------
-- 4. Add the same indexes that USAGE_EVENT uses
-- ----------------------------------------------------------------------------
ALTER TABLE usage_event_bench
    ADD INDEX idx_bench_timestamp (Event_Timestamp),
    ADD INDEX idx_bench_resource (FK_Resource_ID, Event_Timestamp);

ANALYZE TABLE usage_event_bench;

-- ----------------------------------------------------------------------------
-- 5. AFTER: rerun both queries unchanged
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT
    resource.Resource_Name,
    SUM(bench.Calculated_Cost) AS Month_Cost
FROM usage_event_bench bench
INNER JOIN RESOURCE resource
    ON bench.FK_Resource_ID = resource.Resource_ID
WHERE bench.Event_Timestamp >= '2024-11-01'
  AND bench.Event_Timestamp <  '2024-12-01'
GROUP BY resource.Resource_Name
ORDER BY Month_Cost DESC
LIMIT 20;

EXPLAIN ANALYZE
SELECT
    COUNT(*) AS Events,
    SUM(bench.Calculated_Cost) AS Month_Cost
FROM usage_event_bench bench
WHERE bench.FK_Resource_ID = 4
  AND bench.Event_Timestamp >= '2024-11-01'
  AND bench.Event_Timestamp <  '2024-12-01';

-- ----------------------------------------------------------------------------
-- 6. Clean up (uncomment to remove the benchmark tables)
-- ----------------------------------------------------------------------------
-- DROP TABLE usage_event_bench;
-- DROP TABLE bench_digits;
