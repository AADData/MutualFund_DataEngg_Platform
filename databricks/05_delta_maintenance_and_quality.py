# Databricks notebook source
# MAGIC %md
# MAGIC # 05 - Delta Maintenance And Quality Checks

# COMMAND ----------

# MAGIC %run ./00_config

# COMMAND ----------

quality_checks = []

checks = {
    "missing_fund_prices": f"""
        SELECT COUNT(*) AS break_count
        FROM {CATALOG}.{SILVER_SCHEMA}.price
        WHERE nav_price IS NULL OR nav_price <= 0
    """,
    "negative_holdings": f"""
        SELECT COUNT(*) AS break_count
        FROM {CATALOG}.{SILVER_SCHEMA}.holding
        WHERE units < 0
    """,
    "invalid_commission_rate": f"""
        SELECT COUNT(*) AS break_count
        FROM {CATALOG}.{SILVER_SCHEMA}.commission
        WHERE commission_rate < 0 OR commission_rate > 1
    """,
    "holding_value_mismatch": f"""
        SELECT COUNT(*) AS break_count
        FROM {CATALOG}.{SILVER_SCHEMA}.holding
        WHERE ABS(market_value - (units * nav_price)) > 0.05
    """,
}

for check_name, sql_text in checks.items():
    break_count = spark.sql(sql_text).first()["break_count"]
    quality_checks.append((check_name, "PASS" if break_count == 0 else "FAIL", break_count))

quality_df = spark.createDataFrame(quality_checks, ["check_name", "status", "break_count"])
quality_df.createOrReplaceTempView("quality_run")

spark.sql(f"""
CREATE OR REPLACE TABLE {CATALOG}.{GOLD_SCHEMA}.data_quality_run_summary
USING DELTA
AS
SELECT
    current_timestamp() AS checked_at,
    check_name,
    status,
    break_count
FROM quality_run
""")

display(spark.table(f"{CATALOG}.{GOLD_SCHEMA}.data_quality_run_summary"))

# COMMAND ----------

for table_name in [
    "agent_commission_daily",
    "agent_commission_monthly",
    "investor_holding_daily",
    "fund_flow_daily",
    "fund_flow_monthly",
    "fund_aum_daily",
]:
    spark.sql(f"OPTIMIZE {CATALOG}.{GOLD_SCHEMA}.{table_name}")

