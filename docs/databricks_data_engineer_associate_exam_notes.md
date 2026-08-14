# Databricks Data Engineer Associate Exam Notes

These notes map Databricks exam concepts to the mutual fund lakehouse project code. Use the file and line references for quick revision.

## 1. Workspace, Notebooks, And `%run`

Concept:
- Databricks notebooks can call shared setup notebooks using `%run`.
- This is useful for shared configuration, paths, credentials, and constants.

Project reference:
- `databricks/01_setup_catalog_schemas.py:2` runs `00_config`.
- `databricks/02_ingest_azure_sql_to_bronze.py:9` runs `00_config`.
- `databricks/03_bronze_to_silver.py:9` runs `00_config`.
- `databricks/04_silver_to_gold.py:9` runs `00_config`.
- `databricks/05_delta_maintenance_and_quality.py:7` runs `00_config`.

Exam reminder:
- A notebook task can depend on shared config notebooks.
- `%run` brings variables/functions from another notebook into the current notebook context.

## 2. Unity Catalog: Catalogs And Schemas

Concept:
- Unity Catalog uses a three-level namespace: `catalog.schema.table`.
- Catalogs organize data assets at a high level.
- Schemas organize tables inside a catalog.

Project reference:
- `databricks/00_config.py:9` sets catalog `aaddata_mf`.
- `databricks/00_config.py:10` sets Bronze schema.
- `databricks/00_config.py:11` sets Silver schema.
- `databricks/00_config.py:12` sets Gold schema.
- `databricks/01_setup_catalog_schemas.py:6` creates the catalog.
- `databricks/01_setup_catalog_schemas.py:7-9` creates Bronze, Silver, and Gold schemas.
- `databricks/01_setup_catalog_schemas.py:13-14` switches catalog and displays schemas.

Exam reminder:
- `CREATE CATALOG` and `CREATE SCHEMA` are Unity Catalog operations.
- Fully qualified table names reduce ambiguity.

## 3. ADLS Gen2 Paths And External Storage

Concept:
- ADLS Gen2 paths use `abfss://container@storageaccount.dfs.core.windows.net/path`.
- This is the cloud storage foundation for a lakehouse.

Project reference:
- `databricks/00_config.py:14-16` documents and sets the ADLS Gen2 lakehouse path.

Exam reminder:
- `abfss` is the secure Azure Blob File System protocol.
- Managed tables hide physical storage details; external locations make storage placement explicit.

## 4. Secret Scope And Secure Credentials

Concept:
- Secrets avoid hardcoding passwords in notebooks.
- `dbutils.secrets.get(scope, key)` retrieves a secret by scope and key name.

Project reference:
- `databricks/00_config.py:20-26` documents the secret scope and required keys.
- `databricks/00_config.py:28-31` reads SQL server, database, user, and password from secrets.

Exam reminder:
- The second argument to `dbutils.secrets.get` is the secret key name, not the secret value.
- Do not print passwords in notebook output.

## 5. JDBC Source Ingestion

Concept:
- Spark can read relational databases using JDBC.
- This project reads Azure SQL OLTP tables into Databricks.

Project reference:
- `databricks/00_config.py:33-40` builds the JDBC URL.
- `databricks/00_config.py:42-46` sets JDBC properties and SQL Server driver.
- `databricks/00_config.py:48-57` lists Azure SQL source tables and target Bronze table names.
- `databricks/02_ingest_azure_sql_to_bronze.py:23-24` reads a SQL table using `spark.read.jdbc`.

Exam reminder:
- JDBC ingestion is batch ingestion.
- Source database firewall/networking must allow Databricks access.
- Credentials should come from secrets.

## 6. Medallion Architecture

Concept:
- Bronze stores raw ingested data.
- Silver stores cleaned, deduplicated, conformed data.
- Gold stores business-ready aggregates and reporting outputs.

Project reference:
- `databricks/02_ingest_azure_sql_to_bronze.py:40-51` loads source tables into Bronze.
- `databricks/03_bronze_to_silver.py:18-52` converts Bronze tables into Silver tables.
- `databricks/04_silver_to_gold.py:13-107` creates Gold aggregates.

Exam reminder:
- Bronze is usually close to source.
- Silver applies quality, deduplication, and conformance.
- Gold supports analytics, dashboards, and downstream marts.

## 7. Bronze Ingestion Metadata

Concept:
- Bronze should support auditability and lineage.
- Ingestion metadata helps identify load time, batch, source system, and row fingerprint.

Project reference:
- `databricks/02_ingest_azure_sql_to_bronze.py:19-20` creates batch ID and ingestion timestamp.
- `databricks/02_ingest_azure_sql_to_bronze.py:27-37` adds `_ingested_at`, `_source_system`, `_source_table`, `_batch_id`, `_record_hash`, and `_is_deleted`.
- `sql/Bronze_Data_Validation.sql:108-121` validates Bronze ingestion metadata columns.

Exam reminder:
- Metadata columns support troubleshooting and lineage.
- Hash columns can help detect changed records.

## 8. Writing Delta Tables

Concept:
- Delta Lake provides ACID transactions, schema enforcement/evolution, and table history.
- `saveAsTable` creates or writes to a table in the metastore/catalog.

Project reference:
- `databricks/02_ingest_azure_sql_to_bronze.py:45-50` writes Bronze data using Delta format, append mode, and schema merge.
- `databricks/03_bronze_to_silver.py:30-35` writes initial Silver tables using Delta overwrite.
- `databricks/04_silver_to_gold.py:14-15`, `30-31`, `46-47`, `62-63`, `80-81`, and `97-98` create Gold Delta tables.

Exam reminder:
- `append` adds rows.
- `overwrite` replaces table data.
- `mergeSchema` allows schema evolution where supported.

## 9. Deduplication With Window Functions

Concept:
- Window functions can identify the latest version of a record by primary key.
- This is common before Silver upsert/merge.

Project reference:
- `databricks/03_bronze_to_silver.py:18-22` partitions by primary key and keeps latest `_ingested_at`.

Exam reminder:
- `row_number()` with `partitionBy` and `orderBy` is a common deduplication pattern.

## 10. Delta MERGE / Upsert

Concept:
- `MERGE` performs insert/update logic into a Delta target.
- It is used for upsert pipelines.

Project reference:
- `databricks/03_bronze_to_silver.py:37-45` performs Delta merge with matched update and not-matched insert.
- `databricks/03_bronze_to_silver.py:51-52` applies this merge to all source tables.

Exam reminder:
- Use `MERGE INTO` for upsert.
- Initial table creation can use overwrite; recurring loads usually use merge.

## 11. Change Data Feed

Concept:
- Change Data Feed records row-level changes to a Delta table.
- Useful for downstream incremental processing.

Project reference:
- `databricks/03_bronze_to_silver.py:47` enables `delta.enableChangeDataFeed`.
- `sql/Silver_Data_Validation.sql:175-176` validates table properties.

Exam reminder:
- CDF must be enabled before changes you want to capture.
- CDF is useful for incremental downstream loads.

## 12. Delta Constraints And Data Quality Rules

Concept:
- Delta constraints enforce data quality rules at table level.
- Quality checks also produce operational evidence.

Project reference:
- `databricks/03_bronze_to_silver.py:56-60` defines constraints for NAV price, holding units, and commission rate.
- `databricks/03_bronze_to_silver.py:62-66` applies constraints.
- `sql/Silver_Data_Validation.sql:90-109` validates data quality breaks in Silver.
- `databricks/05_delta_maintenance_and_quality.py:13-34` defines quality checks.
- `databricks/05_delta_maintenance_and_quality.py:36-38` turns check results into PASS/FAIL status.

Exam reminder:
- Constraints prevent bad data from being written.
- Query-based quality checks are useful for monitoring and reporting.

## 13. Gold Aggregations

Concept:
- Gold tables are business-ready metrics.
- They are normally grouped, filtered, and aggregated from Silver.

Project reference:
- `databricks/04_silver_to_gold.py:13-27` creates daily agent commission.
- `databricks/04_silver_to_gold.py:29-43` creates monthly agent commission.
- `databricks/04_silver_to_gold.py:45-59` creates investor holdings daily.
- `databricks/04_silver_to_gold.py:61-77` creates fund flow daily from settled transactions.
- `databricks/04_silver_to_gold.py:79-94` creates fund flow monthly.
- `databricks/04_silver_to_gold.py:96-107` creates fund AUM daily.
- `sql/Gold_Data_Validation.sql:17-45` reconciles Gold metrics back to Silver.

Exam reminder:
- Gold tables are optimized for consumption.
- Gold may be rebuilt with `CREATE OR REPLACE TABLE` for small/simple pipelines.

## 14. Data Quality Summary Table

Concept:
- Quality checks should write results into a durable table for audit and monitoring.

Project reference:
- `databricks/05_delta_maintenance_and_quality.py:40-41` creates a DataFrame and temp view for quality checks.
- `databricks/05_delta_maintenance_and_quality.py:43-53` writes `data_quality_run_summary`.
- `databricks/05_delta_maintenance_and_quality.py:55` displays the quality summary.
- `sql/Maintenance_Quality.sql:5-21` validates quality summary and failed checks.

Exam reminder:
- Temp views are session-scoped.
- Persisted Delta quality tables are reusable for monitoring and reporting.

## 15. OPTIMIZE And Delta Maintenance

Concept:
- `OPTIMIZE` compacts small files to improve query performance.
- It is a Delta maintenance command.

Project reference:
- `databricks/05_delta_maintenance_and_quality.py:59-67` runs `OPTIMIZE` on Gold reporting tables.
- `sql/Maintenance_Quality.sql:33-40` validates Delta history for optimized tables.
- `sql/Maintenance_Quality.sql:42-43` uses `DESCRIBE DETAIL` for table metadata.

Exam reminder:
- `OPTIMIZE` is useful for read-heavy Delta tables.
- `VACUUM` removes old files and must be used carefully because it affects time travel retention.

## 16. Delta History And Detail

Concept:
- Delta table history provides operation-level auditability.
- `DESCRIBE DETAIL` provides table metadata.

Project reference:
- `sql/Bronze_Data_Validation.sql:123-124` checks Bronze Delta history.
- `sql/Silver_Data_Validation.sql:178-179` checks Silver Delta history.
- `sql/Gold_Data_Validation.sql:145-146` checks Gold Delta history.
- `sql/Maintenance_Quality.sql:33-43` checks optimization history and detail metadata.

Exam reminder:
- `DESCRIBE HISTORY` is central to Delta auditability and time travel understanding.

## 17. SQL Warehouses And Validation Queries

Concept:
- SQL warehouses run Databricks SQL queries for validation, dashboards, and BI use cases.
- They are different from notebook compute/all-purpose clusters.

Project reference:
- `sql/Bronze_Data_Validation.sql:5-17` validates Bronze table existence and counts.
- `sql/Silver_Data_Validation.sql:5-17` validates Silver table existence and counts.
- `sql/Gold_Data_Validation.sql:5-15` validates Gold table existence and counts.
- `sql/Maintenance_Quality.sql:23-31` validates Gold table counts after maintenance.

Exam reminder:
- SQL Warehouse: SQL Editor, dashboards, BI.
- All-purpose compute: interactive notebooks.
- Job compute: scheduled production job runs.
- Serverless compute: Databricks-managed compute with less infrastructure management.

## 18. Workflow / Job Orchestration

Concept:
- Databricks Workflows orchestrate notebooks and tasks using dependencies.
- Similar conceptually to Control-M, SQL Server Agent, or Windows Task Scheduler.

Project reference:
- `databricks/databricks_job.json:2-8` defines job name, concurrency, and tags.
- `databricks/databricks_job.json:9-60` defines the multi-task workflow.
- `databricks/databricks_job.json:17-25` defines Azure SQL to Bronze task.
- `databricks/databricks_job.json:28-36` defines Bronze to Silver task and dependency.
- `databricks/databricks_job.json:39-47` defines Silver to Gold task and dependency.
- `databricks/databricks_job.json:50-58` defines quality and maintenance task and dependency.

Exam reminder:
- Jobs can run tasks in dependency order.
- Production jobs should add retries, alerts, timeouts, schedules, and parameters.

## 19. Validation And Reconciliation

Concept:
- Reconciliation proves source-to-target completeness.
- Validation scripts are evidence for production support and audit.

Project reference:
- `sql/Bronze_Data_Validation.sql:8-17` checks Bronze row counts.
- `sql/Silver_Data_Validation.sql:19-46` reconciles Bronze to Silver.
- `sql/Gold_Data_Validation.sql:17-45` reconciles Gold aggregates to Silver.
- `sql/Silver_Data_Validation.sql:48-88` checks duplicate primary keys.
- `sql/Silver_Data_Validation.sql:111-146` validates relationship integrity.

Exam reminder:
- Row count reconciliation is simple but important.
- Aggregated reconciliations validate business metrics, not just records.

## 20. Interview Sound Bite

Use this summary:

> I built a Databricks medallion lakehouse pipeline for mutual fund transaction data. Azure SQL acts as the operational source, Databricks ingests it by JDBC into Bronze Delta tables with audit metadata, Silver applies deduplication, merge/upsert, Change Data Feed, and constraints, and Gold creates business-ready aggregates for commissions, fund flows, holdings, and AUM. I validated each layer with SQL reconciliation scripts and added a maintenance notebook for quality checks and Delta OPTIMIZE. The workflow is orchestrated as a multi-task Databricks job.

