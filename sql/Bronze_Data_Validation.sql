-- Bronze data validation queries for Databricks SQL
-- Run after databricks/02_ingest_azure_sql_to_bronze.py has loaded Bronze Delta tables.
-- Target catalog/schema: aaddata_mf.bronze

-- 1. Confirm Bronze tables exist.
SHOW TABLES IN aaddata_mf.bronze;

-- 2. Source-to-Bronze row count reconciliation.
SELECT 'agent' AS table_name, COUNT(*) AS row_count FROM aaddata_mf.bronze.agent
UNION ALL SELECT 'investor', COUNT(*) FROM aaddata_mf.bronze.investor
UNION ALL SELECT 'fund', COUNT(*) FROM aaddata_mf.bronze.fund
UNION ALL SELECT 'transaction', COUNT(*) FROM aaddata_mf.bronze.transaction
UNION ALL SELECT 'price', COUNT(*) FROM aaddata_mf.bronze.price
UNION ALL SELECT 'holding', COUNT(*) FROM aaddata_mf.bronze.holding
UNION ALL SELECT 'commission', COUNT(*) FROM aaddata_mf.bronze.commission
UNION ALL SELECT 'asset', COUNT(*) FROM aaddata_mf.bronze.asset
ORDER BY table_name;

-- 3. View sample transaction records.
SELECT *
FROM aaddata_mf.bronze.transaction
ORDER BY trade_date, transaction_id
LIMIT 20;

-- 4. Validate investor-to-agent relationships.
SELECT
    i.investor_id,
    i.investor_type,
    i.country_code AS investor_country,
    i.kyc_status,
    a.agent_code,
    a.agent_name,
    a.channel
FROM aaddata_mf.bronze.investor i
LEFT JOIN aaddata_mf.bronze.agent a
    ON i.agent_id = a.agent_id
ORDER BY i.investor_id
LIMIT 20;

-- 5. Fund transaction summary by fund and transaction type.
SELECT
    f.fund_code,
    f.fund_name,
    t.transaction_type,
    COUNT(*) AS transaction_count,
    ROUND(SUM(t.gross_amount), 2) AS gross_amount,
    ROUND(SUM(t.net_amount), 2) AS net_amount
FROM aaddata_mf.bronze.transaction t
JOIN aaddata_mf.bronze.fund f
    ON t.fund_id = f.fund_id
GROUP BY
    f.fund_code,
    f.fund_name,
    t.transaction_type
ORDER BY f.fund_code, t.transaction_type;

-- 6. Agent commission summary.
SELECT
    a.agent_code,
    a.agent_name,
    c.commission_type,
    COUNT(*) AS commission_count,
    ROUND(SUM(c.commission_amount), 2) AS total_commission
FROM aaddata_mf.bronze.commission c
JOIN aaddata_mf.bronze.agent a
    ON c.agent_id = a.agent_id
GROUP BY
    a.agent_code,
    a.agent_name,
    c.commission_type
ORDER BY total_commission DESC;

-- 7. Investor holdings with fund details.
SELECT
    h.valuation_date,
    i.investor_id,
    i.investor_type,
    f.fund_code,
    f.fund_name,
    h.units,
    h.nav_price,
    h.market_value
FROM aaddata_mf.bronze.holding h
JOIN aaddata_mf.bronze.investor i
    ON h.investor_id = i.investor_id
JOIN aaddata_mf.bronze.fund f
    ON h.fund_id = f.fund_id
ORDER BY h.valuation_date, i.investor_id
LIMIT 50;

-- 8. Fund asset and portfolio composition.
SELECT
    valuation_date,
    fund_id,
    asset_type,
    sector,
    country_code,
    ROUND(SUM(market_value), 2) AS market_value
FROM aaddata_mf.bronze.asset
GROUP BY
    valuation_date,
    fund_id,
    asset_type,
    sector,
    country_code
ORDER BY valuation_date, fund_id, asset_type;

-- 9. Confirm Bronze ingestion metadata columns.
SELECT
    transaction_id,
    trade_date,
    transaction_type,
    transaction_status,
    _ingested_at,
    _source_system,
    _source_table,
    _batch_id,
    _record_hash,
    _is_deleted
FROM aaddata_mf.bronze.transaction
LIMIT 10;

-- 10. Review Delta transaction history for auditability.
DESCRIBE HISTORY aaddata_mf.bronze.transaction;
