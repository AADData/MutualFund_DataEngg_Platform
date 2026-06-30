# Pipeline And Azure Setup

## Correct Data Flow

The source data files are for the Azure SQL operational database, not for the data warehouse.

Recommended flow:

```mermaid
flowchart LR
    A["Generated source CSV files"] --> B["Azure Blob Storage landing"]
    B --> C["Azure SQL OLTP tables"]
    C --> D["Databricks Bronze Delta"]
    D --> E["Databricks Silver Delta"]
    E --> F["Databricks Gold Delta"]
    F --> G["DBT mart facts and dimensions"]
    G --> H["Dashboard"]
    H --> I["AADData.com"]
```

## Why This Pipeline

This design is stronger for your CV because it mirrors an enterprise source-to-lakehouse platform:

- Azure Blob Storage behaves like the file landing area used before source-system loading.
- Azure SQL behaves like the operational transfer agency source.
- Databricks demonstrates lakehouse ingestion, Delta Lake, data quality, and transformation.
- DBT demonstrates analytics engineering discipline over curated data.
- Dashboard reads from facts and dimensions, not from raw source tables.

## Local-To-Cloud Steps

### 1. Generate source files

Run:

```powershell
python scripts\generate_sample_data.py
```

This creates:

- `sample_data/source/*.csv` for Azure SQL source loading.
- `sample_data/marts/*.csv` only for local dashboard demo mode.

### 2. Upload source files to Azure Blob Storage

Use:

```powershell
pip install -r requirements-local.txt
$env:AZURE_STORAGE_CONNECTION_STRING="<storage-account-connection-string>"
$env:AZURE_BLOB_CONTAINER="source-landing"
$env:AZURE_BLOB_PREFIX="mutual-fund"
python scripts\upload_source_csvs_to_blob.py
```

This uploads files to:

```text
source-landing/mutual-fund/*.csv
```

### 3. Create Azure SQL tables

Run this script in Azure Data Studio or SQL Server Management Studio:

```text
sql/azure_sql_schema.sql
```

### 4. Load source CSV files into Azure SQL

Use:

```powershell
pip install -r requirements-local.txt
$env:AZURE_SQL_CONNECTION_STRING="Server=tcp:<server>.database.windows.net,1433;Database:<db>;Uid:<user>;Pwd:<password>;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
$env:AZURE_STORAGE_CONNECTION_STRING="<storage-account-connection-string>"
$env:AZURE_SQL_LOAD_SOURCE="blob"
$env:AZURE_BLOB_CONTAINER="source-landing"
$env:AZURE_BLOB_PREFIX="mutual-fund"
python scripts\load_source_csvs_to_azure_sql.py
```

If you want a local development fallback without Blob Storage:

```powershell
$env:AZURE_SQL_LOAD_SOURCE="local"
python scripts\load_source_csvs_to_azure_sql.py
```

If `pyodbc` complains, install the Microsoft ODBC Driver for SQL Server.

### 5. Import Databricks notebooks

Import these files into a Databricks workspace folder such as `/Workspace/MutualFund`:

- `databricks/00_config.py`
- `databricks/01_setup_catalog_schemas.py`
- `databricks/02_ingest_azure_sql_to_bronze.py`
- `databricks/03_bronze_to_silver.py`
- `databricks/04_silver_to_gold.py`
- `databricks/05_delta_maintenance_and_quality.py`

Update `00_config.py` with:

- Azure SQL server host.
- Azure SQL database.
- ADLS Gen2 storage path.
- Databricks secret scope name.

### 6. Run Databricks pipeline

Run notebooks in this order:

1. `01_setup_catalog_schemas`
2. `02_ingest_azure_sql_to_bronze`
3. `03_bronze_to_silver`
4. `04_silver_to_gold`
5. `05_delta_maintenance_and_quality`

Later, create a Databricks Workflow using `databricks/databricks_job.json` as the design template.

### 7. Run DBT

Point DBT to Databricks or Snowflake, then run:

```powershell
dbt debug
dbt run
dbt test
dbt docs generate
```

## Azure Services To Create This Week

Create one dedicated resource group, for example:

```text
rg-aad-mutual-fund-dev
```

Minimum services:

- Azure SQL Database for OLTP source.
- Azure Storage Account with Blob landing and ADLS Gen2 enabled for Delta Lake storage.
- Azure Databricks workspace.
- Azure Key Vault for secrets.
- Azure Static Web Apps for AADData.com.

Optional later:

- Azure Data Factory if you want to demonstrate orchestration outside Databricks.
- Azure App Service or Azure Container Apps for the dashboard.
- Microsoft Entra ID app registration if you want dashboard authentication.

## Recommended Development Pipeline

For this project, start with Databricks Workflows, not Azure Data Factory.

Reason:

- You are studying for Databricks Data Engineer Associate.
- Databricks Workflows keeps ingestion, Delta Lake processing, quality checks, and maintenance in one place.
- It is simpler and cheaper for a portfolio project.

Add Azure Data Factory later as an orchestration extension:

- Trigger Databricks jobs.
- Copy files into landing storage.
- Demonstrate Azure-native orchestration knowledge.

## Cost-Control Settings

Use a dev-only setup:

- Single small Azure SQL Database or serverless Azure SQL where available.
- Small Databricks job cluster.
- Auto-termination set to 10-20 minutes.
- Avoid always-on SQL warehouses while learning.
- Use ADLS lifecycle rules only after the basic project works.
- Add a budget alert in Azure Cost Management on day one.

## Suggested First Cloud Milestone

The first success milestone should be small:

1. Create Azure SQL.
2. Create Azure Storage Account and Blob landing container.
3. Upload generated source CSV files to Blob Storage.
4. Load Azure SQL from Blob landing.
5. Create Databricks workspace and secret scope.
6. Run Bronze ingestion from Azure SQL.
7. Confirm Bronze Delta tables exist.

After that, build Silver, Gold, DBT, and dashboard.
