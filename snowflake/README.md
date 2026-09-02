# Snowflake Mutual Fund Data Platform

This folder contains a Snowflake implementation path for the same mutual fund data engineering platform used in the Azure SQL and Databricks build.

## Goal

Use the existing mutual fund source files and Azure landing pattern to practice SnowPro Core concepts:

- Roles, users, grants, and least privilege
- Warehouses, auto-suspend, and cost controls
- Databases, schemas, raw tables, curated tables, and mart tables
- Azure external stages and CSV file formats
- `COPY INTO` file loading
- Streams and tasks for change processing
- Dynamic tables for managed transformations
- Time Travel and zero-copy cloning
- Resource monitors, query history, and access governance

## Suggested Run Order

Run the scripts in this order from a Snowflake worksheet:

1. `00_account_setup.sql`
2. `01_roles_warehouses_databases.sql`
3. `02_stages_file_formats.sql`
4. `03_raw_tables.sql`
5. `04_copy_into_raw.sql`
6. `05_curated_tables.sql`
7. `06_streams_tasks.sql`
8. `07_dynamic_tables.sql`
9. `08_security_governance.sql`
10. `09_time_travel_clone.sql`
11. `10_exam_revision_queries.sql`

## Data Source

The scripts assume the source CSV files are available in Azure Blob or ADLS landing storage:

```text
source-landing/mutual-fund/Agent.csv
source-landing/mutual-fund/Investor.csv
source-landing/mutual-fund/Fund.csv
source-landing/mutual-fund/Price.csv
source-landing/mutual-fund/Transaction.csv
source-landing/mutual-fund/Holding.csv
source-landing/mutual-fund/Commission.csv
source-landing/mutual-fund/Asset.csv
```

## Important

Do not put passwords, SAS tokens, Azure account keys, or private keys in these files. Use placeholders and configure secrets in Snowflake or Azure as appropriate.

