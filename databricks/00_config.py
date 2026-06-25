# Databricks notebook source
# MAGIC %md
# MAGIC # 00 - Configuration
# MAGIC
# MAGIC Run this notebook first in the Databricks workspace. Update the values below for your Azure subscription.

# COMMAND ----------

CATALOG = "aaddata_mf"
BRONZE_SCHEMA = "bronze"
SILVER_SCHEMA = "silver"
GOLD_SCHEMA = "gold"

# Use an external ADLS Gen2 location for a realistic portfolio build.
# Example: abfss://lakehouse@<storage-account>.dfs.core.windows.net/mutual-fund-platform
LAKEHOUSE_BASE_PATH = "abfss://lakehouse@<storage-account>.dfs.core.windows.net/mutual-fund-platform"

SOURCE_SYSTEM = "azure_sql_mutual_fund"

# Create a Databricks secret scope named "aad-mf".
# Recommended secret keys:
# - sql-server-host
# - sql-database
# - sql-user
# - sql-password
SECRET_SCOPE = "aad-mf"

SQL_SERVER_HOST = dbutils.secrets.get(SECRET_SCOPE, "sql-server-host")
SQL_DATABASE = dbutils.secrets.get(SECRET_SCOPE, "sql-database")
SQL_USER = dbutils.secrets.get(SECRET_SCOPE, "sql-user")
SQL_PASSWORD = dbutils.secrets.get(SECRET_SCOPE, "sql-password")

JDBC_URL = (
    f"jdbc:sqlserver://{SQL_SERVER_HOST}:1433;"
    f"database={SQL_DATABASE};"
    "encrypt=true;"
    "trustServerCertificate=false;"
    "hostNameInCertificate=*.database.windows.net;"
    "loginTimeout=30;"
)

JDBC_PROPS = {
    "user": SQL_USER,
    "password": SQL_PASSWORD,
    "driver": "com.microsoft.sqlserver.jdbc.SQLServerDriver",
}

SOURCE_TABLES = [
    {"source_table": "dbo.Agent", "target_table": "agent", "primary_key": "agent_id", "watermark": "updated_at"},
    {"source_table": "dbo.Investor", "target_table": "investor", "primary_key": "investor_id", "watermark": "updated_at"},
    {"source_table": "dbo.Fund", "target_table": "fund", "primary_key": "fund_id", "watermark": "updated_at"},
    {"source_table": "dbo.[Transaction]", "target_table": "transaction", "primary_key": "transaction_id", "watermark": "updated_at"},
    {"source_table": "dbo.Price", "target_table": "price", "primary_key": "price_id", "watermark": "created_at"},
    {"source_table": "dbo.Holding", "target_table": "holding", "primary_key": "holding_id", "watermark": "created_at"},
    {"source_table": "dbo.Commission", "target_table": "commission", "primary_key": "commission_id", "watermark": "created_at"},
    {"source_table": "dbo.Asset", "target_table": "asset", "primary_key": "asset_id", "watermark": "valuation_date"},
]

