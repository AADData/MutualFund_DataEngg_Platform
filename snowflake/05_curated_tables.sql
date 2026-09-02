-- 05_curated_tables.sql
-- Builds curated and reporting tables from RAW data.

USE ROLE AADDATA_PLATFORM_ADMIN;
USE WAREHOUSE WH_AADDATA_DEV;
USE DATABASE MF_TRANS_DEV;

CREATE OR REPLACE TABLE CURATED.AGENT AS
SELECT *
FROM RAW.AGENT
QUALIFY ROW_NUMBER() OVER (PARTITION BY agent_id ORDER BY load_ts DESC) = 1;

CREATE OR REPLACE TABLE CURATED.INVESTOR AS
SELECT *
FROM RAW.INVESTOR
QUALIFY ROW_NUMBER() OVER (PARTITION BY investor_id ORDER BY load_ts DESC) = 1;

CREATE OR REPLACE TABLE CURATED.FUND AS
SELECT *
FROM RAW.FUND
QUALIFY ROW_NUMBER() OVER (PARTITION BY fund_id ORDER BY load_ts DESC) = 1;

CREATE OR REPLACE TABLE CURATED.PRICE AS
SELECT *
FROM RAW.PRICE
QUALIFY ROW_NUMBER() OVER (PARTITION BY price_id ORDER BY load_ts DESC) = 1;

CREATE OR REPLACE TABLE CURATED.TRANSACTION AS
SELECT *
FROM RAW.TRANSACTION
QUALIFY ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY load_ts DESC) = 1;

CREATE OR REPLACE TABLE CURATED.HOLDING AS
SELECT *
FROM RAW.HOLDING
QUALIFY ROW_NUMBER() OVER (PARTITION BY holding_id ORDER BY load_ts DESC) = 1;

CREATE OR REPLACE TABLE CURATED.COMMISSION AS
SELECT *
FROM RAW.COMMISSION
QUALIFY ROW_NUMBER() OVER (PARTITION BY commission_id ORDER BY load_ts DESC) = 1;

CREATE OR REPLACE TABLE CURATED.ASSET AS
SELECT *
FROM RAW.ASSET
QUALIFY ROW_NUMBER() OVER (PARTITION BY asset_id ORDER BY load_ts DESC) = 1;

CREATE OR REPLACE TABLE MART.DIM_AGENT AS
SELECT
  agent_id AS agent_key,
  agent_id,
  agent_code,
  agent_name,
  channel,
  country_code,
  active_flag
FROM CURATED.AGENT;

CREATE OR REPLACE TABLE MART.DIM_INVESTOR AS
SELECT
  investor_id AS investor_key,
  investor_id,
  agent_id,
  investor_type,
  first_name,
  last_name,
  country_code,
  kyc_status,
  risk_rating
FROM CURATED.INVESTOR;

CREATE OR REPLACE TABLE MART.DIM_FUND AS
SELECT
  fund_id AS fund_key,
  fund_id,
  fund_code,
  fund_name,
  asset_class,
  currency_code,
  fund_status,
  launch_date
FROM CURATED.FUND;

CREATE OR REPLACE TABLE MART.FACT_TRANSACTION AS
SELECT
  transaction_id,
  trade_date,
  settlement_date,
  investor_id,
  agent_id,
  fund_id,
  transaction_type,
  transaction_status,
  units,
  price AS transaction_price,
  gross_amount,
  fee_amount,
  net_amount,
  currency_code
FROM CURATED.TRANSACTION;

CREATE OR REPLACE TABLE MART.FACT_AGENT_COMMISSION_DAILY AS
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

CREATE OR REPLACE TABLE MART.FACT_INVESTOR_HOLDING_DAILY AS
SELECT
  valuation_date,
  investor_id,
  fund_id,
  SUM(units) AS holding_units,
  AVG(nav_price) AS nav_price,
  SUM(market_value) AS market_value,
  currency_code
FROM CURATED.HOLDING
GROUP BY valuation_date, investor_id, fund_id, currency_code;

CREATE OR REPLACE TABLE MART.FACT_FUND_FLOW_DAILY AS
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

CREATE OR REPLACE TABLE MART.FACT_FUND_AUM_DAILY AS
SELECT
  valuation_date,
  fund_id,
  currency_code,
  SUM(market_value) AS aum_amount
FROM CURATED.HOLDING
GROUP BY valuation_date, fund_id, currency_code;

