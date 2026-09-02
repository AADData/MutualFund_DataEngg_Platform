-- 04_copy_into_raw.sql
-- Loads source CSV files from Azure Blob/ADLS external stage into Snowflake RAW tables.

USE ROLE AADDATA_PLATFORM_ADMIN;
USE WAREHOUSE WH_AADDATA_DEV;
USE DATABASE MF_TRANS_DEV;
USE SCHEMA RAW;

-- Preview files before loading.
LIST @AZURE_SOURCE_LANDING_STAGE;

COPY INTO AGENT (
  agent_id, agent_code, agent_name, channel, country_code, active_flag, created_at, updated_at
)
FROM @AZURE_SOURCE_LANDING_STAGE/Agent.csv
FILE_FORMAT = (FORMAT_NAME = CSV_WITH_HEADER_FF)
ON_ERROR = ABORT_STATEMENT;

COPY INTO INVESTOR (
  investor_id, agent_id, investor_type, first_name, last_name, country_code, kyc_status, risk_rating, created_at, updated_at
)
FROM @AZURE_SOURCE_LANDING_STAGE/Investor.csv
FILE_FORMAT = (FORMAT_NAME = CSV_WITH_HEADER_FF)
ON_ERROR = ABORT_STATEMENT;

COPY INTO FUND (
  fund_id, fund_code, fund_name, asset_class, currency_code, fund_status, launch_date, created_at, updated_at
)
FROM @AZURE_SOURCE_LANDING_STAGE/Fund.csv
FILE_FORMAT = (FORMAT_NAME = CSV_WITH_HEADER_FF)
ON_ERROR = ABORT_STATEMENT;

COPY INTO PRICE (
  price_id, fund_id, valuation_date, nav_price, currency_code, price_source, created_at
)
FROM @AZURE_SOURCE_LANDING_STAGE/Price.csv
FILE_FORMAT = (FORMAT_NAME = CSV_WITH_HEADER_FF)
ON_ERROR = ABORT_STATEMENT;

COPY INTO TRANSACTION (
  transaction_id, investor_id, agent_id, fund_id, transaction_type, transaction_status,
  trade_date, settlement_date, units, price, gross_amount, fee_amount, net_amount,
  currency_code, created_at, updated_at
)
FROM @AZURE_SOURCE_LANDING_STAGE/Transaction.csv
FILE_FORMAT = (FORMAT_NAME = CSV_WITH_HEADER_FF)
ON_ERROR = ABORT_STATEMENT;

COPY INTO HOLDING (
  holding_id, investor_id, fund_id, valuation_date, units, nav_price, market_value, currency_code, created_at
)
FROM @AZURE_SOURCE_LANDING_STAGE/Holding.csv
FILE_FORMAT = (FORMAT_NAME = CSV_WITH_HEADER_FF)
ON_ERROR = ABORT_STATEMENT;

COPY INTO COMMISSION (
  commission_id, transaction_id, agent_id, fund_id, commission_date, commission_type,
  commission_rate, commission_amount, currency_code, created_at
)
FROM @AZURE_SOURCE_LANDING_STAGE/Commission.csv
FILE_FORMAT = (FORMAT_NAME = CSV_WITH_HEADER_FF)
ON_ERROR = ABORT_STATEMENT;

COPY INTO ASSET (
  asset_id, fund_id, asset_code, asset_name, asset_type, sector, country_code, market_value, valuation_date
)
FROM @AZURE_SOURCE_LANDING_STAGE/Asset.csv
FILE_FORMAT = (FORMAT_NAME = CSV_WITH_HEADER_FF)
ON_ERROR = ABORT_STATEMENT;

-- Validation after COPY INTO.
SELECT 'AGENT' AS table_name, COUNT(*) AS row_count FROM AGENT
UNION ALL SELECT 'INVESTOR', COUNT(*) FROM INVESTOR
UNION ALL SELECT 'FUND', COUNT(*) FROM FUND
UNION ALL SELECT 'PRICE', COUNT(*) FROM PRICE
UNION ALL SELECT 'TRANSACTION', COUNT(*) FROM TRANSACTION
UNION ALL SELECT 'HOLDING', COUNT(*) FROM HOLDING
UNION ALL SELECT 'COMMISSION', COUNT(*) FROM COMMISSION
UNION ALL SELECT 'ASSET', COUNT(*) FROM ASSET
ORDER BY table_name;

-- COPY history is important for SnowPro Core.
SELECT *
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'TRANSACTION',
  START_TIME => DATEADD('hour', -24, CURRENT_TIMESTAMP())
));

