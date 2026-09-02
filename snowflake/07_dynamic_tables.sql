-- 07_dynamic_tables.sql
-- Dynamic table examples for managed transformation refresh.

USE ROLE AADDATA_PLATFORM_ADMIN;
USE WAREHOUSE WH_AADDATA_DEV;
USE DATABASE MF_TRANS_DEV;

CREATE OR REPLACE DYNAMIC TABLE MART.DT_AGENT_COMMISSION_DAILY
  TARGET_LAG = '1 hour'
  WAREHOUSE = WH_AADDATA_DEV
AS
SELECT
  commission_date,
  agent_id,
  fund_id,
  commission_type,
  COUNT(*) AS commission_count,
  SUM(commission_amount) AS commission_amount,
  currency_code
FROM CURATED.COMMISSION
GROUP BY commission_date, agent_id, fund_id, commission_type, currency_code;

CREATE OR REPLACE DYNAMIC TABLE MART.DT_FUND_FLOW_DAILY
  TARGET_LAG = '1 hour'
  WAREHOUSE = WH_AADDATA_DEV
AS
SELECT
  trade_date,
  fund_id,
  currency_code,
  SUM(CASE WHEN transaction_type IN ('SUBSCRIPTION', 'SWITCH_IN') THEN net_amount ELSE 0 END) AS subscription_amount,
  SUM(CASE WHEN transaction_type IN ('REDEMPTION', 'SWITCH_OUT') THEN net_amount ELSE 0 END) AS redemption_amount,
  SUM(CASE
        WHEN transaction_type IN ('SUBSCRIPTION', 'SWITCH_IN') THEN net_amount
        WHEN transaction_type IN ('REDEMPTION', 'SWITCH_OUT') THEN -net_amount
        ELSE 0
      END) AS net_flow_amount
FROM CURATED.TRANSACTION
WHERE transaction_status = 'SETTLED'
GROUP BY trade_date, fund_id, currency_code;

SHOW DYNAMIC TABLES IN SCHEMA MART;

-- SnowPro notes:
-- Dynamic tables are managed transformation objects.
-- They are different from streams/tasks and different from materialized views.
-- TARGET_LAG controls freshness target.

