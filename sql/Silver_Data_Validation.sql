-- Silver data validation queries for Databricks SQL
-- Run after databricks/03_bronze_to_silver.py has built Silver Delta tables.
-- Target catalog/schema: aaddata_mf.silver

-- 1. Confirm Silver tables exist.
SHOW TABLES IN aaddata_mf.silver;

-- 2. Silver row counts.
SELECT 'agent' AS table_name, COUNT(*) AS row_count FROM aaddata_mf.silver.agent
UNION ALL SELECT 'investor', COUNT(*) FROM aaddata_mf.silver.investor
UNION ALL SELECT 'fund', COUNT(*) FROM aaddata_mf.silver.fund
UNION ALL SELECT 'transaction', COUNT(*) FROM aaddata_mf.silver.transaction
UNION ALL SELECT 'price', COUNT(*) FROM aaddata_mf.silver.price
UNION ALL SELECT 'holding', COUNT(*) FROM aaddata_mf.silver.holding
UNION ALL SELECT 'commission', COUNT(*) FROM aaddata_mf.silver.commission
UNION ALL SELECT 'asset', COUNT(*) FROM aaddata_mf.silver.asset
ORDER BY table_name;

-- 3. Bronze-to-Silver row count reconciliation.
SELECT
    bronze.table_name,
    bronze.row_count AS bronze_row_count,
    silver.row_count AS silver_row_count,
    silver.row_count - bronze.row_count AS row_count_difference
FROM (
    SELECT 'agent' AS table_name, COUNT(*) AS row_count FROM aaddata_mf.bronze.agent
    UNION ALL SELECT 'investor', COUNT(*) FROM aaddata_mf.bronze.investor
    UNION ALL SELECT 'fund', COUNT(*) FROM aaddata_mf.bronze.fund
    UNION ALL SELECT 'transaction', COUNT(*) FROM aaddata_mf.bronze.transaction
    UNION ALL SELECT 'price', COUNT(*) FROM aaddata_mf.bronze.price
    UNION ALL SELECT 'holding', COUNT(*) FROM aaddata_mf.bronze.holding
    UNION ALL SELECT 'commission', COUNT(*) FROM aaddata_mf.bronze.commission
    UNION ALL SELECT 'asset', COUNT(*) FROM aaddata_mf.bronze.asset
) bronze
JOIN (
    SELECT 'agent' AS table_name, COUNT(*) AS row_count FROM aaddata_mf.silver.agent
    UNION ALL SELECT 'investor', COUNT(*) FROM aaddata_mf.silver.investor
    UNION ALL SELECT 'fund', COUNT(*) FROM aaddata_mf.silver.fund
    UNION ALL SELECT 'transaction', COUNT(*) FROM aaddata_mf.silver.transaction
    UNION ALL SELECT 'price', COUNT(*) FROM aaddata_mf.silver.price
    UNION ALL SELECT 'holding', COUNT(*) FROM aaddata_mf.silver.holding
    UNION ALL SELECT 'commission', COUNT(*) FROM aaddata_mf.silver.commission
    UNION ALL SELECT 'asset', COUNT(*) FROM aaddata_mf.silver.asset
) silver
    ON bronze.table_name = silver.table_name
ORDER BY bronze.table_name;

-- 4. Check duplicate primary keys after Silver merge/conformance.
SELECT 'agent' AS table_name, COUNT(*) AS duplicate_key_count
FROM (
    SELECT agent_id FROM aaddata_mf.silver.agent GROUP BY agent_id HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'investor', COUNT(*)
FROM (
    SELECT investor_id FROM aaddata_mf.silver.investor GROUP BY investor_id HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'fund', COUNT(*)
FROM (
    SELECT fund_id FROM aaddata_mf.silver.fund GROUP BY fund_id HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'transaction', COUNT(*)
FROM (
    SELECT transaction_id FROM aaddata_mf.silver.transaction GROUP BY transaction_id HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'price', COUNT(*)
FROM (
    SELECT price_id FROM aaddata_mf.silver.price GROUP BY price_id HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'holding', COUNT(*)
FROM (
    SELECT holding_id FROM aaddata_mf.silver.holding GROUP BY holding_id HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'commission', COUNT(*)
FROM (
    SELECT commission_id FROM aaddata_mf.silver.commission GROUP BY commission_id HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'asset', COUNT(*)
FROM (
    SELECT asset_id FROM aaddata_mf.silver.asset GROUP BY asset_id HAVING COUNT(*) > 1
)
ORDER BY table_name;

-- 5. Validate core data quality rules.
SELECT 'invalid_nav_price' AS check_name, COUNT(*) AS break_count
FROM aaddata_mf.silver.price
WHERE nav_price IS NULL OR nav_price <= 0
UNION ALL
SELECT 'negative_holding_units', COUNT(*)
FROM aaddata_mf.silver.holding
WHERE units < 0
UNION ALL
SELECT 'invalid_commission_rate', COUNT(*)
FROM aaddata_mf.silver.commission
WHERE commission_rate < 0 OR commission_rate > 1
UNION ALL
SELECT 'negative_commission_amount', COUNT(*)
FROM aaddata_mf.silver.commission
WHERE commission_amount < 0
UNION ALL
SELECT 'holding_value_mismatch', COUNT(*)
FROM aaddata_mf.silver.holding
WHERE ABS(market_value - (units * nav_price)) > 0.05;

-- 6. Validate relationship integrity in Silver.
SELECT 'investor_without_agent' AS check_name, COUNT(*) AS break_count
FROM aaddata_mf.silver.investor i
LEFT JOIN aaddata_mf.silver.agent a
    ON i.agent_id = a.agent_id
WHERE a.agent_id IS NULL
UNION ALL
SELECT 'transaction_without_investor', COUNT(*)
FROM aaddata_mf.silver.transaction t
LEFT JOIN aaddata_mf.silver.investor i
    ON t.investor_id = i.investor_id
WHERE i.investor_id IS NULL
UNION ALL
SELECT 'transaction_without_agent', COUNT(*)
FROM aaddata_mf.silver.transaction t
LEFT JOIN aaddata_mf.silver.agent a
    ON t.agent_id = a.agent_id
WHERE a.agent_id IS NULL
UNION ALL
SELECT 'transaction_without_fund', COUNT(*)
FROM aaddata_mf.silver.transaction t
LEFT JOIN aaddata_mf.silver.fund f
    ON t.fund_id = f.fund_id
WHERE f.fund_id IS NULL
UNION ALL
SELECT 'commission_without_transaction', COUNT(*)
FROM aaddata_mf.silver.commission c
LEFT JOIN aaddata_mf.silver.transaction t
    ON c.transaction_id = t.transaction_id
WHERE t.transaction_id IS NULL
UNION ALL
SELECT 'asset_without_fund', COUNT(*)
FROM aaddata_mf.silver.asset ast
LEFT JOIN aaddata_mf.silver.fund f
    ON ast.fund_id = f.fund_id
WHERE f.fund_id IS NULL;

-- 7. Sample conformed transaction view.
SELECT
    t.transaction_id,
    t.trade_date,
    t.transaction_type,
    t.transaction_status,
    i.investor_type,
    a.agent_code,
    a.agent_name,
    f.fund_code,
    f.fund_name,
    t.units,
    t.price,
    t.gross_amount,
    t.fee_amount,
    t.net_amount,
    t.currency_code
FROM aaddata_mf.silver.transaction t
JOIN aaddata_mf.silver.investor i
    ON t.investor_id = i.investor_id
JOIN aaddata_mf.silver.agent a
    ON t.agent_id = a.agent_id
JOIN aaddata_mf.silver.fund f
    ON t.fund_id = f.fund_id
ORDER BY t.trade_date, t.transaction_id
LIMIT 50;

-- 8. Confirm Change Data Feed table property is enabled.
SHOW TBLPROPERTIES aaddata_mf.silver.transaction;

-- 9. Review Silver Delta history.
DESCRIBE HISTORY aaddata_mf.silver.transaction;
