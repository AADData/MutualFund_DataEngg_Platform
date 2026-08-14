-- Gold data validation queries for Databricks SQL
-- Run after databricks/04_silver_to_gold.py has built Gold Delta tables.
-- Target catalog/schema: aaddata_mf.gold

-- 1. Confirm Gold tables exist.
SHOW TABLES IN aaddata_mf.gold;

-- 2. Gold row counts.
SELECT 'agent_commission_daily' AS table_name, COUNT(*) AS row_count FROM aaddata_mf.gold.agent_commission_daily
UNION ALL SELECT 'agent_commission_monthly', COUNT(*) FROM aaddata_mf.gold.agent_commission_monthly
UNION ALL SELECT 'investor_holding_daily', COUNT(*) FROM aaddata_mf.gold.investor_holding_daily
UNION ALL SELECT 'fund_flow_daily', COUNT(*) FROM aaddata_mf.gold.fund_flow_daily
UNION ALL SELECT 'fund_flow_monthly', COUNT(*) FROM aaddata_mf.gold.fund_flow_monthly
UNION ALL SELECT 'fund_aum_daily', COUNT(*) FROM aaddata_mf.gold.fund_aum_daily
ORDER BY table_name;

-- 3. Reconcile Gold daily commission to Silver commission.
SELECT
    'commission_amount' AS metric_name,
    ROUND((SELECT SUM(commission_amount) FROM aaddata_mf.silver.commission), 2) AS silver_amount,
    ROUND((SELECT SUM(commission_amount) FROM aaddata_mf.gold.agent_commission_daily), 2) AS gold_amount,
    ROUND(
        (SELECT SUM(commission_amount) FROM aaddata_mf.gold.agent_commission_daily)
        - (SELECT SUM(commission_amount) FROM aaddata_mf.silver.commission),
        2
    ) AS difference;

-- 4. Reconcile Gold fund flow to settled Silver transactions.
SELECT
    'settled_transaction_count' AS metric_name,
    (SELECT COUNT(*) FROM aaddata_mf.silver.transaction WHERE transaction_status = 'SETTLED') AS silver_count,
    (SELECT SUM(transaction_count) FROM aaddata_mf.gold.fund_flow_daily) AS gold_count,
    (SELECT SUM(transaction_count) FROM aaddata_mf.gold.fund_flow_daily)
        - (SELECT COUNT(*) FROM aaddata_mf.silver.transaction WHERE transaction_status = 'SETTLED') AS difference;

-- 5. Reconcile Gold investor holdings to Silver holdings.
SELECT
    'holding_market_value' AS metric_name,
    ROUND((SELECT SUM(market_value) FROM aaddata_mf.silver.holding), 2) AS silver_amount,
    ROUND((SELECT SUM(market_value) FROM aaddata_mf.gold.investor_holding_daily), 2) AS gold_amount,
    ROUND(
        (SELECT SUM(market_value) FROM aaddata_mf.gold.investor_holding_daily)
        - (SELECT SUM(market_value) FROM aaddata_mf.silver.holding),
        2
    ) AS difference;

-- 6. Agent commission daily sample with agent and fund details.
SELECT
    c.commission_date,
    a.agent_code,
    a.agent_name,
    f.fund_code,
    f.fund_name,
    c.commission_type,
    c.currency_code,
    c.commission_count,
    ROUND(c.commission_amount, 2) AS commission_amount
FROM aaddata_mf.gold.agent_commission_daily c
JOIN aaddata_mf.silver.agent a
    ON c.agent_id = a.agent_id
JOIN aaddata_mf.silver.fund f
    ON c.fund_id = f.fund_id
ORDER BY c.commission_date, a.agent_code, f.fund_code
LIMIT 50;

-- 7. Monthly commission sample for dashboard readiness.
SELECT
    commission_month,
    agent_id,
    fund_id,
    commission_type,
    currency_code,
    commission_count,
    ROUND(commission_amount, 2) AS commission_amount
FROM aaddata_mf.gold.agent_commission_monthly
ORDER BY commission_month, agent_id, fund_id
LIMIT 50;

-- 8. Fund flow daily sample with fund details.
SELECT
    ff.trade_date,
    f.fund_code,
    f.fund_name,
    ff.transaction_type,
    ff.currency_code,
    ff.transaction_count,
    ROUND(ff.units, 6) AS units,
    ROUND(ff.gross_amount, 2) AS gross_amount,
    ROUND(ff.net_amount, 2) AS net_amount
FROM aaddata_mf.gold.fund_flow_daily ff
JOIN aaddata_mf.silver.fund f
    ON ff.fund_id = f.fund_id
ORDER BY ff.trade_date, f.fund_code, ff.transaction_type
LIMIT 50;

-- 9. Investor holding daily sample with investor and fund details.
SELECT
    h.valuation_date,
    h.investor_id,
    i.investor_type,
    f.fund_code,
    f.fund_name,
    h.currency_code,
    ROUND(h.holding_units, 6) AS holding_units,
    ROUND(h.nav_price, 6) AS nav_price,
    ROUND(h.market_value, 2) AS market_value
FROM aaddata_mf.gold.investor_holding_daily h
JOIN aaddata_mf.silver.investor i
    ON h.investor_id = i.investor_id
JOIN aaddata_mf.silver.fund f
    ON h.fund_id = f.fund_id
ORDER BY h.valuation_date, h.investor_id, f.fund_code
LIMIT 50;

-- 10. Fund AUM daily sample.
SELECT
    aum.valuation_date,
    f.fund_code,
    f.fund_name,
    aum.currency_code,
    ROUND(aum.aum_amount, 2) AS aum_amount
FROM aaddata_mf.gold.fund_aum_daily aum
JOIN aaddata_mf.silver.fund f
    ON aum.fund_id = f.fund_id
ORDER BY aum.valuation_date, f.fund_code
LIMIT 50;

-- 11. Check for null business keys in Gold outputs.
SELECT 'agent_commission_daily' AS table_name, COUNT(*) AS null_key_count
FROM aaddata_mf.gold.agent_commission_daily
WHERE commission_date IS NULL OR agent_id IS NULL OR fund_id IS NULL
UNION ALL
SELECT 'investor_holding_daily', COUNT(*)
FROM aaddata_mf.gold.investor_holding_daily
WHERE valuation_date IS NULL OR investor_id IS NULL OR fund_id IS NULL
UNION ALL
SELECT 'fund_flow_daily', COUNT(*)
FROM aaddata_mf.gold.fund_flow_daily
WHERE trade_date IS NULL OR fund_id IS NULL OR transaction_type IS NULL
UNION ALL
SELECT 'fund_aum_daily', COUNT(*)
FROM aaddata_mf.gold.fund_aum_daily
WHERE valuation_date IS NULL OR fund_id IS NULL;

-- 12. Review Gold Delta table history.
DESCRIBE HISTORY aaddata_mf.gold.fund_flow_daily;
