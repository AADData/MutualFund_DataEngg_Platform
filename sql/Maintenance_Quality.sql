-- Delta maintenance and data quality validation queries for Databricks SQL
-- Run after databricks/05_delta_maintenance_and_quality.py has completed.
-- Target catalog/schema: aaddata_mf.gold

-- 1. Review the latest data quality run summary.
SELECT *
FROM aaddata_mf.gold.data_quality_run_summary
ORDER BY checked_at DESC, check_name;

-- 2. Summarize quality check status.
SELECT
    status,
    COUNT(*) AS check_count
FROM aaddata_mf.gold.data_quality_run_summary
GROUP BY status;

-- 3. Confirm there are no failed quality checks.
SELECT *
FROM aaddata_mf.gold.data_quality_run_summary
WHERE status <> 'PASS'
   OR break_count <> 0;

-- 4. Validate Gold reporting tables still return data after OPTIMIZE.
SELECT 'agent_commission_daily' AS table_name, COUNT(*) AS row_count FROM aaddata_mf.gold.agent_commission_daily
UNION ALL SELECT 'agent_commission_monthly', COUNT(*) FROM aaddata_mf.gold.agent_commission_monthly
UNION ALL SELECT 'investor_holding_daily', COUNT(*) FROM aaddata_mf.gold.investor_holding_daily
UNION ALL SELECT 'fund_flow_daily', COUNT(*) FROM aaddata_mf.gold.fund_flow_daily
UNION ALL SELECT 'fund_flow_monthly', COUNT(*) FROM aaddata_mf.gold.fund_flow_monthly
UNION ALL SELECT 'fund_aum_daily', COUNT(*) FROM aaddata_mf.gold.fund_aum_daily
UNION ALL SELECT 'data_quality_run_summary', COUNT(*) FROM aaddata_mf.gold.data_quality_run_summary
ORDER BY table_name;

-- 5. Review Delta history for OPTIMIZE on fund flow daily.
DESCRIBE HISTORY aaddata_mf.gold.fund_flow_daily;

-- 6. Review Delta history for OPTIMIZE on agent commission daily.
DESCRIBE HISTORY aaddata_mf.gold.agent_commission_daily;

-- 7. Review Delta history for OPTIMIZE on investor holding daily.
DESCRIBE HISTORY aaddata_mf.gold.investor_holding_daily;

-- 8. Optional detail check for Gold table metadata.
DESCRIBE DETAIL aaddata_mf.gold.fund_flow_daily;
