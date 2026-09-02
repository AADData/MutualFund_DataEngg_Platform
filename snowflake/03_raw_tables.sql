-- 03_raw_tables.sql
-- Raw tables mirror the source CSV and Azure SQL OLTP structure.

USE ROLE AADDATA_PLATFORM_ADMIN;
USE WAREHOUSE WH_AADDATA_DEV;
USE DATABASE MF_TRANS_DEV;
USE SCHEMA RAW;

CREATE OR REPLACE TABLE AGENT (
  agent_id NUMBER(38,0),
  agent_code VARCHAR(30),
  agent_name VARCHAR(200),
  channel VARCHAR(50),
  country_code CHAR(2),
  active_flag BOOLEAN,
  created_at TIMESTAMP_NTZ,
  updated_at TIMESTAMP_NTZ,
  load_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  source_file VARCHAR
);

CREATE OR REPLACE TABLE INVESTOR (
  investor_id NUMBER(38,0),
  agent_id NUMBER(38,0),
  investor_type VARCHAR(30),
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  country_code CHAR(2),
  kyc_status VARCHAR(30),
  risk_rating VARCHAR(30),
  created_at TIMESTAMP_NTZ,
  updated_at TIMESTAMP_NTZ,
  load_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  source_file VARCHAR
);

CREATE OR REPLACE TABLE FUND (
  fund_id NUMBER(38,0),
  fund_code VARCHAR(30),
  fund_name VARCHAR(200),
  asset_class VARCHAR(50),
  currency_code CHAR(3),
  fund_status VARCHAR(30),
  launch_date DATE,
  created_at TIMESTAMP_NTZ,
  updated_at TIMESTAMP_NTZ,
  load_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  source_file VARCHAR
);

CREATE OR REPLACE TABLE PRICE (
  price_id NUMBER(38,0),
  fund_id NUMBER(38,0),
  valuation_date DATE,
  nav_price NUMBER(19,6),
  currency_code CHAR(3),
  price_source VARCHAR(50),
  created_at TIMESTAMP_NTZ,
  load_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  source_file VARCHAR
);

CREATE OR REPLACE TABLE TRANSACTION (
  transaction_id NUMBER(38,0),
  investor_id NUMBER(38,0),
  agent_id NUMBER(38,0),
  fund_id NUMBER(38,0),
  transaction_type VARCHAR(30),
  transaction_status VARCHAR(30),
  trade_date DATE,
  settlement_date DATE,
  units NUMBER(28,8),
  price NUMBER(19,6),
  gross_amount NUMBER(19,4),
  fee_amount NUMBER(19,4),
  net_amount NUMBER(19,4),
  currency_code CHAR(3),
  created_at TIMESTAMP_NTZ,
  updated_at TIMESTAMP_NTZ,
  load_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  source_file VARCHAR
);

CREATE OR REPLACE TABLE HOLDING (
  holding_id NUMBER(38,0),
  investor_id NUMBER(38,0),
  fund_id NUMBER(38,0),
  valuation_date DATE,
  units NUMBER(28,8),
  nav_price NUMBER(19,6),
  market_value NUMBER(19,4),
  currency_code CHAR(3),
  created_at TIMESTAMP_NTZ,
  load_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  source_file VARCHAR
);

CREATE OR REPLACE TABLE COMMISSION (
  commission_id NUMBER(38,0),
  transaction_id NUMBER(38,0),
  agent_id NUMBER(38,0),
  fund_id NUMBER(38,0),
  commission_date DATE,
  commission_type VARCHAR(30),
  commission_rate NUMBER(9,6),
  commission_amount NUMBER(19,4),
  currency_code CHAR(3),
  created_at TIMESTAMP_NTZ,
  load_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  source_file VARCHAR
);

CREATE OR REPLACE TABLE ASSET (
  asset_id NUMBER(38,0),
  fund_id NUMBER(38,0),
  asset_code VARCHAR(50),
  asset_name VARCHAR(200),
  asset_type VARCHAR(50),
  sector VARCHAR(100),
  country_code CHAR(2),
  market_value NUMBER(19,4),
  valuation_date DATE,
  load_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  source_file VARCHAR
);

CREATE OR REPLACE TABLE LOAD_AUDIT (
  table_name VARCHAR,
  file_name VARCHAR,
  rows_loaded NUMBER,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

