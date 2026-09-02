# AADData Mutual Fund Platform: Interview Questions And Key Concepts

This guide is based on the implementation in this repository. It is designed for interview revision: explain the business reason first, then the technical design, and finally name the evidence in the code.

## 1. Two-Minute Project Summary

> I built a mutual fund data engineering platform to demonstrate modern Azure and Databricks delivery in a finance domain. Azure SQL Database is the normalized operational source for investors, agents, funds, transactions, prices, holdings, commissions, and underlying assets. Databricks ingests the source through JDBC into Bronze Delta tables with audit metadata. Silver keeps the latest record per business key, applies Delta `MERGE` upserts, enables Change Data Feed, and adds quality constraints. Gold creates business-ready daily and monthly marts for agent commission, investor holdings, fund flows, and AUM. A Databricks Workflow orchestrates the stages in dependency order and a maintenance notebook records quality outcomes and runs `OPTIMIZE` on Gold tables. In parallel, I created a dbt project that models conformed dimensions and facts from the Silver layer, with source definitions and model tests.

Useful architecture summary:

```text
Azure SQL OLTP -> JDBC -> Bronze Delta -> Silver Delta -> Gold Delta marts -> SQL/dashboard consumers
                                  |             |               |
                            audit metadata   MERGE/CDF       aggregates, quality,
                                                           maintenance and reporting
```

## 2. Project Status: Describe It Accurately

| Area | What is implemented in the project | Interview-safe wording |
| --- | --- | --- |
| Azure SQL OLTP | DDL and sample data for eight operational entities. | "I designed and created the relational source model in Azure SQL." |
| Databricks ingestion | JDBC read from Azure SQL into Bronze Delta tables, including audit columns. | "I implemented and ran batch JDBC ingestion into Bronze Delta." |
| Medallion pipeline | Bronze, Silver, Gold notebooks were run and validated. | "I built and validated the medallion flow end to end." |
| Databricks workflow | Multi-task job JSON defines the ordered orchestration. | "I created a production-style workflow definition with task dependencies." |
| Delta quality and maintenance | Constraints, quality summary, validation SQL, and `OPTIMIZE` are implemented. | "I included data-quality evidence and Delta maintenance." |
| dbt | Sources, staging views, mart models, and schema tests are present in the repo. | "I created a dbt project structure and models; the next implementation step is configuring the dbt Databricks profile and running `dbt run` and `dbt test`." |
| ADLS Gen2 storage | An ADLS base path is configured, but the current Unity Catalog tables were created as managed tables. | "The environment has ADLS configured; the current tables are Unity Catalog managed Delta tables. I would use an external location and explicit table paths when the storage placement must be governed in ADLS." |

Do not say that dbt has been executed until you have run `dbt debug`, `dbt run`, and `dbt test` successfully and retained the run artifacts.

## 3. OLTP And Relational Design

### Q1. Why did you use Azure SQL Database as the source system?

**Answer:** Mutual fund transfer-agency style operations are transactional: an investor places transactions, funds publish prices, holdings are valued daily, and commissions are calculated against transactions. Azure SQL provides relational integrity, transactions, constraints, indexes, and a familiar operational model. Databricks is then used for scalable analytical processing rather than being the system of record for operational updates.

**Project evidence:** `sql/azure_sql_schema.sql`.

### Q2. What is the difference between OLTP and OLAP in this project?

**Answer:** OLTP is normalized and supports frequent, small, controlled business updates. In this project, `Transaction`, `Holding`, `Price`, and `Commission` are operational tables. OLAP is optimised for reading and aggregation. The Gold Delta tables and dbt facts/dimensions support reporting such as daily commission, fund flow, holdings, and AUM.

### Q3. Why is the Azure SQL model normalized?

**Answer:** The model separates business entities to avoid duplication and preserve integrity. For example, the `Fund` master is stored once and is referenced by transactions, holdings, prices, commissions, and assets. This avoids repeating fund attributes on every transaction and provides one controlled source of truth.

### Q4. Explain the relationships between Investor, Agent, Fund, Transaction, and Commission.

**Answer:** An agent services investors; an investor places transactions in funds. A commission is generated from a transaction and is assigned to an agent and fund. Foreign keys make those relationships explicit, so a commission cannot exist for an unknown transaction, agent, or fund.

**Project evidence:** `sql/azure_sql_schema.sql`, foreign keys `fk_investor_agent`, `fk_transaction_*`, and `fk_commission_*`.

### Q5. What is the difference between a fund and an asset?

**Answer:** A fund is the investor-facing investment product, such as a managed equity fund. An asset is an underlying security or position held by that fund, such as a listed share, bond, or cash position. An investor transacts in units of a fund; the fund has exposure to many assets. That is why `Asset` references `Fund`, while transactions and holdings reference `Fund` directly.

### Q6. Why does the Price table have a unique key on fund and valuation date?

**Answer:** For a given fund and valuation date, there should be one official NAV in the source. The unique constraint prevents duplicate daily prices and supports reliable holding valuation and NAV reporting.

**Project evidence:** `sql/azure_sql_schema.sql`, `uq_price_fund_date`.

### Q7. What is gross amount, fee amount, and net amount?

**Answer:** `gross_amount` is the transaction value before fees, usually units multiplied by price. `fee_amount` is the charge applied to the transaction. `net_amount` is the final value after fees, commonly gross less fee for a subscription or according to the business sign convention. All three are stored because finance reporting needs both the original economic value and the fee impact.

### Q8. How is commission linked to a transaction?

**Answer:** `Commission.transaction_id` is a foreign key to `Transaction.transaction_id`. It records the commission event generated by that transaction, while `agent_id` and `fund_id` retain the reporting context. This supports transaction-level audit and agent/fund-level aggregation.

### Q9. What is trail commission?

**Answer:** Trail commission is an ongoing fee paid to an intermediary while a client remains invested, usually calculated periodically from assets under management rather than only at the original sale. In this model it is represented through `commission_type`; a production enhancement would enforce the allowed values through a check constraint or reference table.

### Q10. Why were indexes added to the operational tables?

**Answer:** They support likely access paths and extraction filters: transaction trade date/fund/agent, commission date/agent/fund, holding valuation date/fund/investor, and price valuation date/fund. Indexing is deliberately driven by query patterns rather than added indiscriminately.

**Project evidence:** `sql/azure_sql_schema.sql`, `ix_transaction_trade_date`, `ix_commission_date`, `ix_holding_valuation_date`, and `ix_price_valuation_date`.

## 4. Dimensional Modelling And Reporting Design

### Q11. What is a fact table?

**Answer:** A fact table records measurable business events or snapshots at a declared grain. It contains foreign keys to dimensions and numeric measures. `fact_transaction` records transaction-level measures; daily holdings and commission facts record periodic measures.

### Q12. What is a dimension table?

**Answer:** A dimension provides descriptive context used to filter, group, and label facts. In this project, agent, investor, fund, asset, and date are conformed dimensions shared across multiple reporting facts.

### Q13. What does grain mean, and why does it matter?

**Answer:** Grain is the exact meaning of one row in a table. It must be declared before choosing measures or joins, otherwise reports can double-count. For example, `fact_agent_commission_daily` has one row per commission date, agent, fund, commission type, and currency. `fact_investor_holding_daily` has one row per valuation date, investor, fund, and currency.

**Project evidence:** `docs/data_model.md`, section `Dimensional Model`; `databricks/04_silver_to_gold.py` aggregation `GROUP BY` clauses.

### Q14. Why is the date dimension conformed?

**Answer:** A conformed date dimension is consistently reused across facts. It lets reports compare trade dates, settlement dates, valuation dates, and commission dates using a common calendar, financial period, month, and year definition.

### Q15. What is a star schema and why use it?

**Answer:** A star schema places a measurable fact at the centre with descriptive dimensions around it. It is easier for dashboards and analysts to understand, supports predictable joins, and reduces the amount of complex normalized joining needed in reporting.

### Q16. Why do you have both daily and monthly reporting tables?

**Answer:** Daily tables retain a detailed reporting grain; monthly tables pre-aggregate the same measures for fast month-level analysis. This serves the common dashboard questions without forcing each report to repeatedly aggregate a larger daily dataset.

### Q17. How is AUM calculated in the project?

**Answer:** AUM is calculated by summing `market_value` from daily investor holdings by valuation date, fund, and currency. It is a snapshot-based metric, not a transaction-flow metric.

**Project evidence:** `databricks/04_silver_to_gold.py`, creation of `fund_aum_daily`.

### Q18. Why are only settled transactions used for fund flow?

**Answer:** Pending, rejected, and cancelled transactions should not be treated as completed investment flows. Filtering to `transaction_status = 'SETTLED'` gives the Gold fund-flow mart a clear and finance-appropriate business rule.

**Project evidence:** `databricks/04_silver_to_gold.py`, creation of `fund_flow_daily`.

## 5. Databricks, Delta Lake, And Medallion Architecture

### Q19. Explain the Bronze, Silver, and Gold layers in your project.

**Answer:** Bronze is a raw, append-only landing layer close to Azure SQL source data, plus ingestion metadata. Silver is the cleaned and conformed layer: it keeps the latest record per primary key and applies Delta upserts and constraints. Gold contains business-ready aggregates such as agent commission, holdings, fund flows, and AUM.

### Q20. Why use JDBC ingestion?

**Answer:** JDBC is appropriate because the initial source is Azure SQL, a relational operational database. It provides a direct batch read into Spark without first building an additional file-extract process. For a high-volume production system, I would also implement incremental predicates using a reliable watermark or change-data-capture mechanism.

**Project evidence:** `databricks/00_config.py`, JDBC URL/properties; `databricks/02_ingest_azure_sql_to_bronze.py`, `spark.read.jdbc`.

### Q21. Why did you use batch ingestion rather than Auto Loader?

**Answer:** The implemented source is Azure SQL, so JDBC is the natural connector. Auto Loader is designed for incremental file ingestion from cloud object storage such as ADLS Gen2 or S3. I would use Auto Loader if fund-price feeds or other sources arrived continuously as files in ADLS.

### Q22. What audit metadata is added in Bronze and why?

**Answer:** Bronze adds `_ingested_at`, `_source_system`, `_source_table`, `_batch_id`, `_record_hash`, and `_is_deleted`. They provide lineage, traceability, batch-level troubleshooting, and a mechanism to identify changed records or future delete handling.

**Project evidence:** `databricks/02_ingest_azure_sql_to_bronze.py`, `add_ingestion_metadata`.

### Q23. What does append mode mean in Bronze?

**Answer:** Append adds a new raw extract to the Bronze table instead of replacing earlier extracts. That preserves an ingestion history, so the Silver layer can select the latest version while operations can investigate prior batches.

### Q24. How does the project deduplicate records in Silver?

**Answer:** It partitions each Bronze table by its primary key, orders records by descending `_ingested_at`, assigns `row_number`, and retains the row numbered one. This gives the latest observed version per business key before the Silver merge.

**Project evidence:** `databricks/03_bronze_to_silver.py`, `latest_from_bronze`.

### Q25. What does Delta `MERGE` do in the Silver layer?

**Answer:** It performs an upsert. When the primary key already exists, it updates the existing Silver row; when it does not, it inserts a new row. This makes Silver idempotent for repeated source loads and keeps a current-state view of the source.

**Project evidence:** `databricks/03_bronze_to_silver.py`, `merge_to_silver`.

### Q26. Does the first Silver run overwrite data?

**Answer:** On the first run only, the target table does not exist, so it is created from the deduplicated Bronze dataset using overwrite mode. On subsequent runs, the table exists and the code uses Delta `MERGE`, so matching records are updated and new records inserted. The initial overwrite does not occur on each recurring run.

### Q27. What is Change Data Feed (CDF), and how is it used?

**Answer:** CDF records row-level inserts, updates, and deletes made to a Delta table after it is enabled. The Silver tables enable `delta.enableChangeDataFeed`, creating the option for downstream consumers to process only changes rather than repeatedly reading the full table.

**Project evidence:** `databricks/03_bronze_to_silver.py`, `ALTER TABLE ... delta.enableChangeDataFeed = true`.

### Q28. What Delta Lake features have you used?

**Answer:** Delta tables, ACID-backed writes, append and overwrite behavior, schema merge on Bronze writes, `MERGE` upserts in Silver, table constraints, Change Data Feed, `DESCRIBE HISTORY` validation, and `OPTIMIZE` maintenance. The project also uses Unity Catalog namespacing and managed Delta tables.

### Q29. What are Delta constraints and why add them?

**Answer:** Constraints reject data that violates defined business rules. The project protects against non-positive NAV, negative holding units, and invalid commission rates. They move basic quality rules closer to the data layer instead of relying only on downstream reports.

**Project evidence:** `databricks/03_bronze_to_silver.py`, `constraints` list.

### Q30. What is the difference between a managed and external Delta table?

**Answer:** A managed table is stored and lifecycle-managed by Unity Catalog; the physical path is hidden from the user. An external table registers data stored at an explicit cloud path, with the storage lifecycle managed separately. The current project tables are managed; the configured ADLS path is preparation for a later external-location implementation.

### Q31. What does `OPTIMIZE` do?

**Answer:** `OPTIMIZE` compacts many small Delta data files into fewer, larger files to improve read performance, particularly for Gold tables queried by dashboards. It is a maintenance task and should be scheduled based on table size and workload rather than run indiscriminately.

**Project evidence:** `databricks/05_delta_maintenance_and_quality.py`, Gold table loop.

### Q32. What is `DESCRIBE HISTORY` used for?

**Answer:** It exposes Delta operations such as writes, merges, and optimizations. I use it in validation queries as operational evidence that the tables are Delta and that expected pipeline activity occurred. It is also central to auditing and time-travel investigation.

**Project evidence:** `sql/Bronze_Data_Validation.sql`, `sql/Silver_Data_Validation.sql`, `sql/Gold_Data_Validation.sql`, and `sql/Maintenance_Quality.sql`.

## 6. Data Quality, Reconciliation, And Operations

### Q33. How do you validate a medallion pipeline?

**Answer:** I validate each layer separately: table existence and row counts in Bronze, source-to-target counts and duplicate keys in Silver, and aggregated business reconciliations in Gold. I also retain a quality summary table showing PASS/FAIL and break counts for finance-specific controls.

**Project evidence:** `sql/Bronze_Data_Validation.sql`, `sql/Silver_Data_Validation.sql`, `sql/Gold_Data_Validation.sql`, and `sql/Maintenance_Quality.sql`.

### Q34. Give examples of data-quality rules in this project.

**Answer:** A fund price must be positive; holdings cannot have negative units; commission rates must be between zero and one; and a holding's market value should match units multiplied by NAV within a small tolerance. These cover reference data, financial validity, and calculated-value reconciliation.

### Q35. Why keep a quality-run summary table rather than just printing notebook output?

**Answer:** Notebook output is temporary and hard to monitor. A persistent Delta summary gives a timestamped operational record that can be queried, reported, alerted on, and retained for audit evidence.

**Project evidence:** `databricks/05_delta_maintenance_and_quality.py`, `data_quality_run_summary`.

### Q36. What is idempotency and why does it matter here?

**Answer:** An idempotent pipeline can be rerun without creating inconsistent duplicate business records. Bronze deliberately retains raw batches, while Silver uses latest-record logic and `MERGE` by primary key to make the curated state repeatable. Gold is rebuilt from Silver, giving a consistent result for a given Silver state.

### Q37. What changes are needed for proper incremental JDBC ingestion?

**Answer:** Store a high-watermark for each source table, read only records created or updated after the last successful watermark, and update that watermark only after the full pipeline succeeds. The project already defines candidate watermark columns in `SOURCE_TABLES`; production code should apply them in the JDBC query and persist load-control state.

**Project evidence:** `databricks/00_config.py`, `SOURCE_TABLES` watermark field.

### Q38. What would you add for deletes from Azure SQL?

**Answer:** JDBC full extracts do not reliably identify source deletes by themselves. I would use CDC, change tracking, soft-delete flags, or reconciliation logic to identify deleted source keys. Then I would write a delete indicator to Bronze and apply a controlled Delta merge/delete pattern in Silver.

## 7. dbt Design And Concepts

### Q39. Where does dbt fit in this platform?

**Answer:** dbt is the analytics engineering layer. It reads curated Silver sources and builds reporting-friendly staging models, dimensions, and fact tables in SQL. Databricks handles Spark ingestion and Delta operations; dbt makes SQL transformations, dependencies, tests, and documentation explicit and reviewable.

### Q40. What is a dbt source definition?

**Answer:** It declares the upstream tables that dbt will read. In this project, the Silver catalog/schema tables are defined as dbt sources, providing a clear boundary between pipeline-owned Silver data and dbt-owned analytical models.

**Project evidence:** `dbt/mutual_fund_dbt/models/sources.yml`.

### Q41. What is the difference between `source()` and `ref()` in dbt?

**Answer:** `source()` references an upstream physical source table outside the current dbt model graph, such as `aaddata_mf.silver.transaction`. `ref()` references another dbt model and creates a dependency in the dbt DAG. This project uses `source()` in staging models and `ref()` from marts to staging models.

**Project evidence:** `dbt/mutual_fund_dbt/models/staging/stg_transaction.sql` and `dbt/mutual_fund_dbt/models/marts/fact_transaction.sql`.

### Q42. Why are staging models views and marts tables?

**Answer:** Staging views provide a lightweight, standardized layer over Silver sources with minimal storage duplication. Marts are materialized as tables because dimensions and facts are reused by dashboards and can benefit from persisted, query-ready results.

**Project evidence:** `dbt/mutual_fund_dbt/dbt_project.yml`.

### Q43. What dbt tests are defined?

**Answer:** The dbt schema file defines `not_null` and `unique` tests for primary business identifiers such as agent, fund, investor, date, and transaction keys, plus `not_null` tests for required measures and foreign-key-style fields. These are basic but valuable contract tests.

**Project evidence:** `dbt/mutual_fund_dbt/models/marts/schema.yml`.

### Q44. How would you run dbt in Databricks?

**Answer:** Configure a `dbt-databricks` profile pointing to the Databricks workspace, catalog, schema, and SQL warehouse or job compute. Run `dbt debug`, then `dbt run` and `dbt test`. In production, run dbt as a separate job task after Silver is ready, with test failure configured to stop downstream publishing.

### Q45. Has dbt been executed in the current project?

**Answer:** The repository contains the dbt project, models, source definitions, and tests. Execution has not yet been evidenced with a configured `profiles.yml` and `run_results.json`. I would state this clearly, then explain the exact next execution steps rather than overclaiming hands-on runtime experience.

## 8. Databricks Workflows And Scheduling

### Q46. How is the notebook pipeline orchestrated?

**Answer:** A Databricks Workflow definition chains setup, Azure SQL-to-Bronze ingestion, Bronze-to-Silver processing, Silver-to-Gold processing, and quality/maintenance. Each task waits for its dependency, so a failure prevents invalid downstream publishing.

**Project evidence:** `databricks/databricks_job.json`.

### Q47. How does this compare with Control-M, ESP, SQL Server Agent, or Windows Task Scheduler?

**Answer:** The scheduling concept is the same: execute work in a controlled order, manage dependencies, monitor status, retry failures, and notify support teams. Databricks Workflows keeps that orchestration close to the notebooks and compute that perform the data processing.

### Q48. What should be added before calling the workflow production-grade?

**Answer:** Add a schedule, retries, task timeouts, alert destinations such as email or webhook, job parameters, appropriate job compute/serverless selection, concurrency limits, audit logging, and an operational runbook. Also change the extraction to incremental loading with a persisted watermark.

### Q49. What does `max_concurrent_runs: 1` protect against?

**Answer:** It prevents two scheduled runs of the same workflow from overlapping. That avoids races such as one run merging Silver while another run is appending related Bronze data, and reduces the risk of inconsistent quality or Gold results.

**Project evidence:** `databricks/databricks_job.json`.

### Q50. What is a webhook in the context of job orchestration?

**Answer:** A webhook is an HTTP callback that sends an event to another system. In a production workflow, a failure webhook could notify Teams, Slack, PagerDuty, ServiceNow, or an internal operations endpoint with the job name, task, run ID, and error status.

## 9. Common Follow-Up Questions

### How would you handle real-time price feeds?

Use an event or file-based landing pattern: Kafka/Event Hubs for messages, or Auto Loader for files arriving in ADLS. Process the stream into Bronze Delta with checkpoints, apply quality and deduplication in Silver, and make the current price available to holdings/AUM calculations. The current JDBC design remains appropriate for batch Azure SQL source entities.

### Why not use a single wide reporting table?

A single wide table can be convenient initially but becomes hard to govern, reuse, and extend. Facts at clear grains and conformed dimensions let different reports combine consistent entities without repeatedly duplicating business logic.

### How would you implement SCD Type 2 for Investor or Fund?

Create a dimension with a surrogate key, business key, effective start/end timestamps, current flag, and tracked attributes. Compare incoming Silver records with the current dimension row, expire the old version when a tracked value changes, and insert a new current version. Facts then resolve to the correct surrogate key based on event date.

### How would you secure this platform?

Use secret scopes or Azure Key Vault for credentials, Unity Catalog permissions for catalogs/schemas/tables, least-privilege Azure SQL users, private networking where practical, and no secrets in Git. Apply PII classification and masking to investor data, audit privileged access, and use service principals/managed identities for scheduled workloads.

### How would you control costs?

Use job compute or serverless with auto-stop, size compute to the workload, avoid unnecessary SQL warehouse uptime, schedule `OPTIMIZE` selectively, and use Azure Cost Analysis grouped by Databricks meter. Keep development datasets small and add budget alerts.

## 10. Revision Checklist

- Be able to explain the grain of every Gold fact without looking at the code.
- Be able to trace one `Transaction` record from Azure SQL through Bronze, Silver, Gold, and dbt.
- Be ready to explain why the first Silver run creates a table and later runs use `MERGE`.
- Say clearly that dbt models and tests are implemented, while dbt execution is the next practical milestone until run evidence exists.
- Distinguish JDBC batch ingestion, Auto Loader file ingestion, and streaming/event ingestion.
- Distinguish Unity Catalog managed tables from external tables on ADLS.
- Explain how you would evolve the current full-extract design into a watermark/CDC incremental pipeline.
- Use the validation SQL files as evidence that you tested row counts, duplicates, relationships, business reconciliations, and Delta history.
