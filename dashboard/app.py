from pathlib import Path

import pandas as pd
import streamlit as st


ROOT = Path(__file__).resolve().parents[1]
MARTS = ROOT / "sample_data" / "marts"


def read_mart(name: str) -> pd.DataFrame:
    path = MARTS / f"{name}.csv"
    if path.exists():
        return pd.read_csv(path)
    return pd.DataFrame()

st.set_page_config(page_title="Mutual Fund Data Platform", layout="wide")

st.title("Mutual Fund Data Platform")
st.caption("Portfolio dashboard for commissions, holdings, fund flows, and data quality.")

st.sidebar.header("Filters")
page = st.sidebar.radio(
    "View",
    ["Overview", "Agent Commission", "Investor Holdings", "Fund Investment", "Data Quality"],
)

dim_agent = read_mart("dim_agent")
dim_fund = read_mart("dim_fund")
fact_commission = read_mart("fact_agent_commission_daily")
fact_holding = read_mart("fact_investor_holding_daily")
fact_flow = read_mart("fact_fund_flow_daily")

if fact_commission.empty:
    st.info("Run `python scripts/generate_sample_data.py` for demo mode, or connect the app to Databricks SQL Warehouse or Snowflake.")

if page == "Overview":
    col1, col2, col3, col4 = st.columns(4)
    total_aum = fact_holding["market_value"].sum() if not fact_holding.empty else 0
    total_flow = fact_flow["net_amount"].sum() if not fact_flow.empty else 0
    total_commission = fact_commission["commission_amount"].sum() if not fact_commission.empty else 0
    active_investors = fact_holding["investor_id"].nunique() if not fact_holding.empty else 0
    col1.metric("AUM", f"${total_aum:,.0f}")
    col2.metric("Net Flow", f"${total_flow:,.0f}")
    col3.metric("Commission", f"${total_commission:,.0f}")
    col4.metric("Active Investors", f"{active_investors:,}")

elif page == "Agent Commission":
    st.subheader("Agent Commission")
    if not fact_commission.empty:
        data = fact_commission.merge(dim_agent, on="agent_id", how="left").merge(dim_fund, on="fund_id", how="left")
        st.bar_chart(data.groupby("agent_name")["commission_amount"].sum())
        st.dataframe(data[["commission_date", "agent_name", "fund_name", "commission_type", "commission_amount"]])
    else:
        st.dataframe(pd.DataFrame(columns=["commission_date", "agent_name", "fund_name", "commission_amount"]))

elif page == "Investor Holdings":
    st.subheader("Investor Holdings")
    if not fact_holding.empty:
        data = fact_holding.merge(dim_fund, on="fund_id", how="left")
        st.bar_chart(data.groupby("fund_name")["market_value"].sum())
        st.dataframe(data[["valuation_date", "investor_id", "fund_name", "holding_units", "market_value"]])
    else:
        st.dataframe(pd.DataFrame(columns=["valuation_date", "investor_id", "fund_name", "market_value"]))

elif page == "Fund Investment":
    st.subheader("Fund Investment")
    if not fact_flow.empty:
        data = fact_flow.merge(dim_fund, on="fund_id", how="left")
        st.bar_chart(data.groupby("fund_name")["net_amount"].sum())
        st.dataframe(data[["trade_date", "fund_name", "transaction_type", "transaction_count", "net_amount"]])
    else:
        st.dataframe(pd.DataFrame(columns=["trade_date", "fund_name", "transaction_type", "net_amount"]))

else:
    st.subheader("Data Quality")
    st.write("Expected source: Gold reconciliation and pipeline audit tables.")
    st.dataframe(pd.DataFrame(columns=["check_name", "status", "break_count", "last_checked_at"]))
