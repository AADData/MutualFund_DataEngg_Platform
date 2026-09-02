-- 10_exam_revision_queries.sql
-- Practical SnowPro Core revision queries mapped to this project.

USE ROLE AADDATA_PLATFORM_ADMIN;
USE WAREHOUSE WH_AADDATA_DEV;
USE DATABASE MF_TRANS_DEV;

-- Warehouses and cost.
SHOW WAREHOUSES LIKE 'WH_AADDATA_DEV';

SELECT *
FROM TABLE(INFORMATION_SCHEMA.WAREHOUSE_LOAD_HISTORY(
  DATE_RANGE_START => DATEADD('day', -7, CURRENT_DATE()),
  WAREHOUSE_NAME => 'WH_AADDATA_DEV'
));

-- Tables, schemas, and storage.
SHOW DATABASES LIKE 'MF_TRANS_DEV';
SHOW SCHEMAS IN DATABASE MF_TRANS_DEV;
SHOW TABLES IN SCHEMA RAW;
SHOW TABLES IN SCHEMA CURATED;
SHOW TABLES IN SCHEMA MART;

-- Stages and file formats.
SHOW STAGES IN SCHEMA RAW;
SHOW FILE FORMATS IN SCHEMA RAW;
LIST @RAW.AZURE_SOURCE_LANDING_STAGE;

-- COPY INTO history.
SELECT *
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'RAW.TRANSACTION',
  START_TIME => DATEADD('day', -7, CURRENT_TIMESTAMP())
));

-- Query profile candidates.
SELECT
  f.fund_name,
  t.trade_date,
  SUM(t.net_amount) AS net_amount
FROM MART.FACT_TRANSACTION t
JOIN MART.DIM_FUND f
  ON t.fund_id = f.fund_id
GROUP BY f.fund_name, t.trade_date
ORDER BY t.trade_date, f.fund_name;

-- Result cache practice: run the same query twice and compare query history.
SELECT COUNT(*) FROM MART.FACT_TRANSACTION;
SELECT COUNT(*) FROM MART.FACT_TRANSACTION;

-- Streams and tasks.
SHOW STREAMS IN SCHEMA RAW;
SHOW TASKS IN SCHEMA CONTROL;

-- Dynamic tables.
SHOW DYNAMIC TABLES IN SCHEMA MART;

-- RBAC.
SHOW GRANTS TO ROLE AADDATA_DATA_ENGINEER;
SHOW GRANTS TO ROLE AADDATA_ANALYST;

-- Time Travel and clone.
SELECT COUNT(*)
FROM MART.FACT_TRANSACTION
AT (OFFSET => -60);

-- Data quality checks.
SELECT 'negative_holding_units' AS check_name, COUNT(*) AS break_count
FROM CURATED.HOLDING
WHERE units < 0
UNION ALL
SELECT 'invalid_nav_price', COUNT(*)
FROM CURATED.PRICE
WHERE nav_price <= 0
UNION ALL
SELECT 'invalid_commission_rate', COUNT(*)
FROM CURATED.COMMISSION
WHERE commission_rate < 0 OR commission_rate > 1;

