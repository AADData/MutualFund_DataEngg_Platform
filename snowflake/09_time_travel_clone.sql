-- 09_time_travel_clone.sql
-- Time Travel and zero-copy clone practice.

USE ROLE AADDATA_PLATFORM_ADMIN;
USE WAREHOUSE WH_AADDATA_DEV;
USE DATABASE MF_TRANS_DEV;

-- Zero-copy clone for safe testing.
CREATE OR REPLACE DATABASE MF_TRANS_DEV_CLONE
  CLONE MF_TRANS_DEV
  COMMENT = 'Zero-copy clone for SnowPro Core practice';

-- Compare row counts between source and clone.
SELECT 'SOURCE' AS db_name, COUNT(*) AS row_count FROM MF_TRANS_DEV.MART.FACT_TRANSACTION
UNION ALL
SELECT 'CLONE', COUNT(*) FROM MF_TRANS_DEV_CLONE.MART.FACT_TRANSACTION;

-- Time Travel examples.
-- Query table as of an earlier timestamp.
SELECT COUNT(*) AS transaction_count_5_minutes_ago
FROM MF_TRANS_DEV.MART.FACT_TRANSACTION
AT (TIMESTAMP => DATEADD('minute', -5, CURRENT_TIMESTAMP()));

-- Undrop examples for exam concept only. Do not run unless you intentionally drop an object.
-- DROP TABLE MF_TRANS_DEV.MART.FACT_TRANSACTION;
-- UNDROP TABLE MF_TRANS_DEV.MART.FACT_TRANSACTION;

-- Clean-up command when finished with clone.
-- DROP DATABASE MF_TRANS_DEV_CLONE;

-- SnowPro notes:
-- Time Travel allows querying/restoring historical data within retention period.
-- Fail-safe is Snowflake-managed disaster recovery period after Time Travel.
-- Zero-copy clone is metadata-based and initially does not duplicate storage.

