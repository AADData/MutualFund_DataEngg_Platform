# AADData Diagram Assets

These SVG files are downloadable portfolio diagrams for AADData.com.

## Files

- `architecture-diagram.svg` - end-to-end platform architecture.
- `warehouse-star-schema.svg` - dimensional warehouse star schema.

## How To Use

Open either file in a browser and use **Save as** or download the file directly from GitHub.

For the website, they can later be embedded with:

```html
<img src="assets/architecture-diagram.svg" alt="AADData mutual fund platform architecture">
<img src="assets/warehouse-star-schema.svg" alt="Mutual fund data warehouse star schema">
```

## Architecture Clarification

ADLS Gen2 is the physical storage layer for Delta tables when Databricks uses external lakehouse storage.

DBT is not storage. DBT is the transformation and testing framework that creates or updates warehouse mart objects such as fact and dimension tables.

In this project:

```text
Azure SQL -> Databricks Bronze/Silver/Gold -> dbt mart models -> dashboard
```

The Bronze, Silver, Gold and mart tables can all be physically stored in ADLS Gen2 as Delta tables.
