# Dashboard

The dashboard should answer business questions, not just display tables.

## Pages

### Overview

- Total AUM.
- Daily net flow.
- Monthly net flow.
- Total commission.
- Active investors.
- Active funds.

### Agent Commission

Filters:

- Date range.
- Agent.
- Fund.
- Commission type.

Charts:

- Commission by day.
- Commission by month.
- Top agents by commission.
- Commission by fund.

### Investor Holdings

Filters:

- Valuation date.
- Investor.
- Fund.
- Asset class.

Charts:

- Holding market value by investor.
- Holding market value by fund.
- Units and market value trend.

### Fund Investment

Filters:

- Date range.
- Fund.
- Transaction type.

Charts:

- Subscription versus redemption by day.
- Monthly net flow by fund.
- Transaction volume by fund.

### Data Quality

Metrics:

- Rejected transactions.
- Missing prices.
- Negative holding exceptions.
- Commission reconciliation breaks.
- Last successful pipeline run.

## Deployment Options

- Local Streamlit for fast prototyping.
- Databricks Apps for a Databricks-native demo.
- Azure App Service for a portfolio-hosted app.
- Snowflake Streamlit if the marts are deployed to Snowflake.

