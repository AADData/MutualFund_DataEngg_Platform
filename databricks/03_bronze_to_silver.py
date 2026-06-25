# Databricks notebook source
# MAGIC %md
# MAGIC # 03 - Bronze To Silver
# MAGIC
# MAGIC This notebook builds conformed Silver Delta tables using Delta merge.

# COMMAND ----------

# MAGIC %run ./00_config

# COMMAND ----------

from delta.tables import DeltaTable
from pyspark.sql import Window
from pyspark.sql import functions as F


def latest_from_bronze(table_name: str, primary_key: str):
    bronze_table = f"{CATALOG}.{BRONZE_SCHEMA}.{table_name}"
    df = spark.table(bronze_table)
    w = Window.partitionBy(primary_key).orderBy(F.col("_ingested_at").desc())
    return df.withColumn("_rn", F.row_number().over(w)).filter(F.col("_rn") == 1).drop("_rn")


def merge_to_silver(table_name: str, primary_key: str):
    target_table = f"{CATALOG}.{SILVER_SCHEMA}.{table_name}"
    source_df = latest_from_bronze(table_name, primary_key)

    if not spark.catalog.tableExists(target_table):
        (
            source_df.write.format("delta")
            .mode("overwrite")
            .option("overwriteSchema", "true")
            .saveAsTable(target_table)
        )
    else:
        target = DeltaTable.forName(spark, target_table)
        condition = f"target.{primary_key} = source.{primary_key}"
        (
            target.alias("target")
            .merge(source_df.alias("source"), condition)
            .whenMatchedUpdateAll()
            .whenNotMatchedInsertAll()
            .execute()
        )

    spark.sql(f"ALTER TABLE {target_table} SET TBLPROPERTIES (delta.enableChangeDataFeed = true)")
    print(f"Merged Silver table {target_table}")


for table in SOURCE_TABLES:
    merge_to_silver(table["target_table"], table["primary_key"])

# COMMAND ----------

constraints = [
    (f"{CATALOG}.{SILVER_SCHEMA}.price", "valid_nav_price", "nav_price > 0"),
    (f"{CATALOG}.{SILVER_SCHEMA}.holding", "valid_holding_units", "units >= 0"),
    (f"{CATALOG}.{SILVER_SCHEMA}.commission", "valid_commission_rate", "commission_rate >= 0 AND commission_rate <= 1"),
]

for table_name, constraint_name, expression in constraints:
    try:
        spark.sql(f"ALTER TABLE {table_name} ADD CONSTRAINT {constraint_name} CHECK ({expression})")
    except Exception as exc:
        print(f"Constraint {constraint_name} was not added, possibly because it already exists: {exc}")
