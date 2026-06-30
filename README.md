# Mutual Fund Data Engineering Platform

Portfolio project for a senior data engineer preparing for Databricks Data Engineer Associate and Snowflake SnowPro Core certifications.

The project models a mutual fund transfer agency platform with investor transactions, agent commissions, fund prices, holdings, and warehouse analytics. It is designed to show enterprise data engineering skills across Azure SQL, Databricks Delta Lake, DBT, analytics marts, and a web dashboard.

## Why This Project

This project is intentionally aligned to real transfer agency and asset servicing work:

- Investor, agent, fund, transaction, holding, price, asset, and commission domains.
- EOD and intraday reporting patterns.
- Retrocession and commission-style calculations.
- Data lake hydration from a relational source.
- Data quality, lineage, reconciliation, and auditability.
- Warehouse facts and dimensions for BI consumption.

## Target Architecture

```mermaid
flowchart LR
    A["Generated CSV files\nAgent, Investor, Fund, Transaction, Asset, Commission, Holding, Price"] --> B["Azure Blob Storage\nsource-landing container"]
    B --> C["Azure SQL OLTP\nNormalized source tables"]
    C --> D["Databricks Ingestion\nJDBC / Workflows"]
    D --> E["Bronze Delta\nRaw append-only source copies"]
    E --> F["Silver Delta\nValidated, conformed entities"]
    F --> G["Gold Delta\nBusiness aggregates and serving tables"]
    G --> H["DBT Warehouse Marts\nFacts, dimensions, tests, docs"]
    H --> I["Dashboard\nAgent commission, investor holdings, fund flows"]
    I --> J["AADData.com\nBio and project showcase"]
```

## Repository Map

- `docs/` - project brief, architecture, data model, implementation roadmap.
- `sql/` - Azure SQL transactional schema and source-load plan.
- `scripts/` - sample data generation, Blob landing upload, and Azure SQL load utilities.
- `databricks/` - notebook and job design notes for Delta Lake ingestion and processing.
- `docs/pipeline_and_azure_setup.md` - recommended pipeline and Azure services setup.
- `dbt/mutual_fund_dbt/` - starter DBT project for facts, dimensions, tests, and documentation.
- `dashboard/` - web dashboard specification and starter Streamlit app.
- `website/` - AADData.com bio site starter page and portfolio copy.

## Learning Outcomes

By completing this project you will practice:

- Azure SQL relational modelling and source-system constraints.
- Incremental ingestion into Delta Lake.
- Delta Lake features including schema enforcement, merge, time travel, change data feed, optimize, vacuum, constraints, and medallion architecture.
- Databricks workflows, notebooks, SQL warehouses, Unity Catalog-oriented naming, and data quality checks.
- DBT modelling, sources, staging, marts, generic tests, custom tests, snapshots, and documentation.
- Dimensional modelling with daily and monthly fact tables.
- Dashboard-ready serving tables and KPI definitions.
- Portfolio storytelling through AADData.com.

## Suggested Build Order

1. Generate realistic source CSV data.
2. Upload generated source CSV files to Azure Blob Storage landing.
3. Load Blob landing files into Azure SQL OLTP source tables.
4. Ingest Azure SQL source tables into Bronze Delta.
5. Build Silver Delta tables with data quality checks and deduplication.
6. Build Gold business tables for holdings, commissions, fund flows, and AUM.
7. Use DBT to publish warehouse facts and dimensions.
8. Build dashboard pages over the curated marts.
9. Publish AADData.com as a bio plus project showcase website.

## Core Dashboards

- Agent commission by day, month, fund, and commission type.
- Investor holdings by fund, asset class, and valuation date.
- Investment and redemption flows by fund per day and month.
- Fund AUM, NAV movement, and transaction volume.
- Data quality and reconciliation status for portfolio credibility.
