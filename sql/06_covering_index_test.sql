-- ============================================================================
-- 06_covering_index_test.sql
-- Follow-up to 05_index_benchmark.sql for Query A (monthly top cost resources).
--
-- In 05, Query A used idx_bench_timestamp but barely sped up. The range scan
-- found 82,080 matching index entries, and each one needed a separate lookup
-- into the table to read Calculated_Cost.
--
-- A covering index stores every column the query needs inside the index
-- itself: Event_Timestamp to filter, FK_Resource_ID to join, and
-- Calculated_Cost to sum. MySQL can then answer the query from the index alone
-- and skip the table lookups. The plan should show "Covering index range scan".
--
-- Run after 05_index_benchmark.sql, while usage_event_bench still exists.
-- ============================================================================

USE cloud_resource_management;
SET time_zone = '+00:00';

-- Confirm the benchmark table is still loaded (expect 2,000,000)
SELECT COUNT(*) AS Bench_Rows FROM usage_event_bench;

-- ----------------------------------------------------------------------------
-- 1. Add the covering index
-- ----------------------------------------------------------------------------
ALTER TABLE usage_event_bench
    ADD INDEX idx_bench_covering (Event_Timestamp, FK_Resource_ID, Calculated_Cost);

ANALYZE TABLE usage_event_bench;

-- ----------------------------------------------------------------------------
-- 2. Rerun Query A, unchanged from 05. Run it twice and keep the second
--    result so both runs read from a warm buffer pool.
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

-- ----------------------------------------------------------------------------
-- 3. Check that Query B still picks the composite index
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT
    COUNT(*) AS Events,
    SUM(bench.Calculated_Cost) AS Month_Cost
FROM usage_event_bench bench
WHERE bench.FK_Resource_ID = 4
  AND bench.Event_Timestamp >= '2024-11-01'
  AND bench.Event_Timestamp <  '2024-12-01';

-- ----------------------------------------------------------------------------
-- 4. The trade-off: disk space used by each index
--    Every extra index also adds work to each INSERT into the table.
-- ----------------------------------------------------------------------------
SELECT
    index_name AS Index_Name,
    ROUND(stat_value * @@innodb_page_size / 1024 / 1024, 1) AS Size_MB
FROM mysql.innodb_index_stats
WHERE database_name = 'cloud_resource_management'
  AND table_name = 'usage_event_bench'
  AND stat_name = 'size'
ORDER BY stat_value DESC;

-- ----------------------------------------------------------------------------
-- 5. Clean up (uncomment to remove the benchmark tables)
-- ----------------------------------------------------------------------------
-- DROP TABLE usage_event_bench;
-- DROP TABLE bench_digits;
