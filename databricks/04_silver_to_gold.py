# Databricks notebook source
# MAGIC %md
# MAGIC # 04 - Silver To Gold
# MAGIC
# MAGIC This notebook creates business-ready Gold Delta tables. DBT can then build final data warehouse facts and dimensions from these tables.

# COMMAND ----------

# MAGIC %run ./00_config

# COMMAND ----------

spark.sql(f"""
CREATE OR REPLACE TABLE {CATALOG}.{GOLD_SCHEMA}.agent_commission_daily
USING DELTA
AS
SELECT
    commission_date,
    agent_id,
    fund_id,
    commission_type,
    currency_code,
    COUNT(*) AS commission_count,
    SUM(commission_amount) AS commission_amount
FROM {CATALOG}.{SILVER_SCHEMA}.commission
GROUP BY commission_date, agent_id, fund_id, commission_type, currency_code
""")

spark.sql(f"""
CREATE OR REPLACE TABLE {CATALOG}.{GOLD_SCHEMA}.agent_commission_monthly
USING DELTA
AS
SELECT
    date_trunc('MONTH', commission_date) AS commission_month,
    agent_id,
    fund_id,
    commission_type,
    currency_code,
    SUM(commission_count) AS commission_count,
    SUM(commission_amount) AS commission_amount
FROM {CATALOG}.{GOLD_SCHEMA}.agent_commission_daily
GROUP BY date_trunc('MONTH', commission_date), agent_id, fund_id, commission_type, currency_code
""")

spark.sql(f"""
CREATE OR REPLACE TABLE {CATALOG}.{GOLD_SCHEMA}.investor_holding_daily
USING DELTA
AS
SELECT
    valuation_date,
    investor_id,
    fund_id,
    currency_code,
    SUM(units) AS holding_units,
    MAX(nav_price) AS nav_price,
    SUM(market_value) AS market_value
FROM {CATALOG}.{SILVER_SCHEMA}.holding
GROUP BY valuation_date, investor_id, fund_id, currency_code
""")

spark.sql(f"""
CREATE OR REPLACE TABLE {CATALOG}.{GOLD_SCHEMA}.fund_flow_daily
USING DELTA
AS
SELECT
    trade_date,
    fund_id,
    transaction_type,
    currency_code,
    COUNT(*) AS transaction_count,
    SUM(units) AS units,
    SUM(gross_amount) AS gross_amount,
    SUM(net_amount) AS net_amount
FROM {CATALOG}.{SILVER_SCHEMA}.transaction
WHERE transaction_status = 'SETTLED'
GROUP BY trade_date, fund_id, transaction_type, currency_code
""")

spark.sql(f"""
CREATE OR REPLACE TABLE {CATALOG}.{GOLD_SCHEMA}.fund_flow_monthly
USING DELTA
AS
SELECT
    date_trunc('MONTH', trade_date) AS trade_month,
    fund_id,
    transaction_type,
    currency_code,
    SUM(transaction_count) AS transaction_count,
    SUM(units) AS units,
    SUM(gross_amount) AS gross_amount,
    SUM(net_amount) AS net_amount
FROM {CATALOG}.{GOLD_SCHEMA}.fund_flow_daily
GROUP BY date_trunc('MONTH', trade_date), fund_id, transaction_type, currency_code
""")

spark.sql(f"""
CREATE OR REPLACE TABLE {CATALOG}.{GOLD_SCHEMA}.fund_aum_daily
USING DELTA
AS
SELECT
    valuation_date,
    fund_id,
    currency_code,
    SUM(market_value) AS aum_amount
FROM {CATALOG}.{GOLD_SCHEMA}.investor_holding_daily
GROUP BY valuation_date, fund_id, currency_code
""")

