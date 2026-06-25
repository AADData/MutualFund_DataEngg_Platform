# Project Brief

## Project Name

Mutual Fund Data Engineering Platform

## Portfolio Positioning

This is a senior data engineering portfolio project for Amar A. Deshmukh, a TOGAF-certified architect and Azure Data Engineer with 17+ years of experience across finance, transfer agency, data warehousing, data lake hydration, ETL, reporting, and stakeholder-facing delivery.

The project is designed to support three goals:

1. Learn and demonstrate Databricks Lakehouse engineering.
2. Practice concepts useful for Snowflake SnowPro Core.
3. Strengthen the AADData.com portfolio site with a domain-rich, finance-focused data platform case study.

## Business Scenario

A mutual fund distributor platform records investors, agents, funds, daily prices, assets, transactions, holdings, and commissions. Operations teams need reliable daily and monthly reporting for:

- Agent commissions.
- Investor holdings.
- Fund inflows and outflows.
- Fund assets under management.
- Reconciliation between transaction source, lakehouse, and warehouse marts.

## Functional Entities

- Investor - person or organization investing in mutual funds.
- Agent - distributor, adviser, or channel receiving commission.
- Fund - mutual fund scheme or share class.
- Transaction - subscription, redemption, switch, dividend, fee, or adjustment.
- Asset - underlying asset or asset classification for fund exposure.
- Commission - agent commission derived from transactions or holdings.
- Holding - investor fund position by valuation date.
- Price - fund NAV or unit price by valuation date.

## Technology Scope

### Source

- Azure SQL Database as the operational relational system.
- SQL constraints and realistic transactional design.
- Optional SQL Server temporal tables for audit learning.

### Lakehouse

- Databricks Delta Lake medallion architecture.
- Bronze raw Delta tables.
- Silver validated and conformed Delta tables.
- Gold analytics and serving Delta tables.
- Databricks Workflows for orchestration.
- Delta features: `MERGE`, schema enforcement, schema evolution, time travel, optimize, vacuum, change data feed, constraints, and generated columns where useful.

### Transformation

- DBT for warehouse marts, testing, documentation, lineage, and deployment discipline.
- DBT staging models over curated Delta or Snowflake tables.
- DBT marts for facts and dimensions.

### Analytics

- Web dashboard for commission, holdings, fund movement, and data quality.
- Streamlit starter included for fast local prototyping.
- Later deployment options: Azure App Service, Databricks Apps, Streamlit Community Cloud, or containerized app.

### Portfolio

- AADData.com bio page.
- Project case study with architecture, dashboard link, certification learning notes, and CV-aligned achievements.

## Success Criteria

- End-to-end pipeline from Azure SQL source to dashboard-ready marts.
- Incremental processing rather than full reload only.
- Reconciliation checks between transaction totals, holdings, commissions, and warehouse facts.
- DBT docs generated with model lineage and tests.
- Dashboard demonstrates business-value metrics, not only technical tables.
- AADData.com presents the project as a credible finance data engineering platform.

