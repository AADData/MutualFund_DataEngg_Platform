# Databricks Implementation Notes

## Workspace Objects

Recommended notebooks or jobs:

- `01_ingest_azure_sql_to_bronze`
- `02_bronze_to_silver_entities`
- `03_silver_to_gold_metrics`
- `04_delta_maintenance`
- `05_reconciliation_checks`

## Bronze Pattern

Use JDBC ingestion from Azure SQL for the first Databricks version. The upstream file landing step is Azure Blob Storage, where generated CSV files are uploaded before loading the Azure SQL OLTP source.

Later, add event or file-based ingestion from Blob/ADLS to practice Auto Loader as an extension.

Bronze table columns:

- Source columns.
- `_ingested_at`
- `_source_system`
- `_source_table`
- `_batch_id`
- `_record_hash`

## Silver Pattern

Use `MERGE INTO` based on source primary keys and `updated_at`.

Example merge strategy:

```sql
MERGE INTO aaddata_mf.silver.fund AS target
USING aaddata_mf.bronze.fund AS source
ON target.fund_id = source.fund_id
WHEN MATCHED AND source.updated_at >= target.updated_at THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *
```

## Delta Features Checklist

- Create managed Delta tables in Bronze, Silver, and Gold.
- Enable Change Data Feed on selected Silver tables.
- Use Delta table constraints for price, holding, and commission rules.
- Use time travel to compare a corrected commission run with a previous run.
- Run optimize on high-read Gold tables.
- Run vacuum only after documenting the retention policy.
- Use generated date keys for marts where useful.

## Suggested Table Properties

```sql
ALTER TABLE aaddata_mf.silver.transaction
SET TBLPROPERTIES (delta.enableChangeDataFeed = true);

ALTER TABLE aaddata_mf.silver.price
ADD CONSTRAINT valid_nav_price CHECK (nav_price > 0);

ALTER TABLE aaddata_mf.silver.commission
ADD CONSTRAINT valid_commission_rate CHECK (commission_rate >= 0 AND commission_rate <= 1);
```

## Gold Metric Examples

- Daily commission by agent, fund, and type.
- Monthly commission by agent and fund.
- Investor holdings with market value.
- Fund flow by day and month.
- AUM by fund and valuation date.
