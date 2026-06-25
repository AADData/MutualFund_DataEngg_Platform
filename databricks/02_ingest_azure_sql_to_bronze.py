# Databricks notebook source
# MAGIC %md
# MAGIC # 02 - Ingest Azure SQL To Bronze Delta
# MAGIC
# MAGIC This notebook reads operational source tables from Azure SQL and stores raw copies in Bronze Delta.

# COMMAND ----------

# MAGIC %run ./00_config

# COMMAND ----------

from datetime import datetime, timezone
from uuid import uuid4

from pyspark.sql import functions as F


batch_id = str(uuid4())
ingested_at = datetime.now(timezone.utc).isoformat()


def read_sql_table(source_table: str):
    return spark.read.jdbc(url=JDBC_URL, table=source_table, properties=JDBC_PROPS)


def add_ingestion_metadata(df, source_table: str):
    business_columns = df.columns
    record_hash = F.sha2(F.concat_ws("||", *[F.coalesce(F.col(c).cast("string"), F.lit("")) for c in business_columns]), 256)
    return (
        df.withColumn("_ingested_at", F.lit(ingested_at).cast("timestamp"))
        .withColumn("_source_system", F.lit(SOURCE_SYSTEM))
        .withColumn("_source_table", F.lit(source_table))
        .withColumn("_batch_id", F.lit(batch_id))
        .withColumn("_record_hash", record_hash)
        .withColumn("_is_deleted", F.lit(False))
    )


for table in SOURCE_TABLES:
    source_table = table["source_table"]
    target = f"{CATALOG}.{BRONZE_SCHEMA}.{table['target_table']}"
    raw_df = read_sql_table(source_table)
    bronze_df = add_ingestion_metadata(raw_df, source_table)
    (
        bronze_df.write.format("delta")
        .mode("append")
        .option("mergeSchema", "true")
        .saveAsTable(target)
    )
    print(f"Loaded {bronze_df.count()} rows into {target}")

