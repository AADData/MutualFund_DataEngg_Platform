from __future__ import annotations

import csv
import random
from datetime import date, timedelta
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "sample_data"
SOURCE = OUT / "source"
MARTS = OUT / "marts"


def write_csv(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    random.seed(42)
    start = date(2026, 1, 1)
    days = [start + timedelta(days=i) for i in range(90)]

    agents = [
        {"agent_id": 1, "agent_code": "AG001", "agent_name": "Northstar Advisory", "channel": "IFA", "country_code": "IN", "active_flag": 1, "created_at": "2026-01-01T00:00:00", "updated_at": ""},
        {"agent_id": 2, "agent_code": "AG002", "agent_name": "Harbour Wealth", "channel": "Bank", "country_code": "AU", "active_flag": 1, "created_at": "2026-01-01T00:00:00", "updated_at": ""},
        {"agent_id": 3, "agent_code": "AG003", "agent_name": "Summit Financial", "channel": "Platform", "country_code": "GB", "active_flag": 1, "created_at": "2026-01-01T00:00:00", "updated_at": ""},
    ]

    funds = [
        {"fund_id": 1, "fund_code": "MF-EQ-01", "fund_name": "AAD Equity Growth", "asset_class": "Equity", "currency_code": "USD", "fund_status": "ACTIVE", "launch_date": "2020-01-01", "created_at": "2026-01-01T00:00:00", "updated_at": ""},
        {"fund_id": 2, "fund_code": "MF-BD-01", "fund_name": "AAD Income Bond", "asset_class": "Fixed Income", "currency_code": "USD", "fund_status": "ACTIVE", "launch_date": "2020-01-01", "created_at": "2026-01-01T00:00:00", "updated_at": ""},
        {"fund_id": 3, "fund_code": "MF-BL-01", "fund_name": "AAD Balanced Opportunities", "asset_class": "Balanced", "currency_code": "USD", "fund_status": "ACTIVE", "launch_date": "2020-01-01", "created_at": "2026-01-01T00:00:00", "updated_at": ""},
    ]

    investors = [
        {
            "investor_id": i,
            "agent_id": random.choice(agents)["agent_id"],
            "investor_type": random.choice(["Individual", "Corporate", "Trust"]),
            "first_name": f"Investor{i:03d}",
            "last_name": "Demo",
            "country_code": random.choice(["IN", "AU", "GB"]),
            "kyc_status": "Approved",
            "risk_rating": random.choice(["Low", "Medium", "High"]),
            "created_at": "2026-01-01T00:00:00",
            "updated_at": "",
        }
        for i in range(1, 51)
    ]

    prices: list[dict] = []
    transactions: list[dict] = []
    commissions: list[dict] = []
    holdings: list[dict] = []
    assets: list[dict] = []

    price_id = 1
    transaction_id = 1
    commission_id = 1
    holding_id = 1
    asset_id = 1

    for day in days:
        for fund in funds:
            prices.append(
                {
                    "price_id": price_id,
                    "fund_id": fund["fund_id"],
                    "valuation_date": day.isoformat(),
                    "nav_price": round(random.uniform(10, 250), 4),
                    "currency_code": "USD",
                    "price_source": "DEMO_NAV",
                    "created_at": f"{day.isoformat()}T18:00:00",
                }
            )
            price_id += 1

    for day in days:
        for _ in range(random.randint(8, 18)):
            investor = random.choice(investors)
            agent = next(a for a in agents if a["agent_id"] == investor["agent_id"])
            fund = random.choice(funds)
            tx_type = random.choices(["SUBSCRIPTION", "REDEMPTION"], weights=[0.68, 0.32])[0]
            amount = round(random.uniform(1000, 50000), 2)
            signed_amount = amount if tx_type == "SUBSCRIPTION" else -amount
            price = round(random.uniform(10, 250), 4)
            units = round(abs(amount) / price, 6)
            commission_rate = random.choice([0.0025, 0.003, 0.004, 0.005])
            commission_amount = round(abs(amount) * commission_rate, 2)

            transactions.append(
                {
                    "transaction_id": transaction_id,
                    "investor_id": investor["investor_id"],
                    "agent_id": agent["agent_id"],
                    "fund_id": fund["fund_id"],
                    "transaction_type": tx_type,
                    "transaction_status": "SETTLED",
                    "trade_date": day.isoformat(),
                    "settlement_date": (day + timedelta(days=2)).isoformat(),
                    "units": units,
                    "price": price,
                    "gross_amount": signed_amount,
                    "fee_amount": 0,
                    "net_amount": signed_amount,
                    "currency_code": "USD",
                    "created_at": f"{day.isoformat()}T10:00:00",
                    "updated_at": "",
                }
            )
            commissions.append(
                {
                    "commission_id": commission_id,
                    "transaction_id": transaction_id,
                    "agent_id": agent["agent_id"],
                    "fund_id": fund["fund_id"],
                    "commission_date": day.isoformat(),
                    "commission_type": "TRAIL",
                    "commission_rate": commission_rate,
                    "commission_amount": commission_amount,
                    "currency_code": "USD",
                    "created_at": f"{day.isoformat()}T11:00:00",
                }
            )
            transaction_id += 1
            commission_id += 1

    for day in days[::7]:
        for investor in investors:
            for fund in funds:
                units = round(random.uniform(0, 1200), 6)
                nav_price = round(random.uniform(10, 250), 4)
                holdings.append(
                    {
                        "holding_id": holding_id,
                        "investor_id": investor["investor_id"],
                        "fund_id": fund["fund_id"],
                        "valuation_date": day.isoformat(),
                        "units": units,
                        "nav_price": nav_price,
                        "market_value": round(units * nav_price, 2),
                        "currency_code": "USD",
                        "created_at": f"{day.isoformat()}T18:30:00",
                    }
                )
                holding_id += 1

    for day in days[::30]:
        for fund in funds:
            for asset_type, sector in [("Equity", "Financials"), ("Bond", "Government"), ("Cash", "Treasury")]:
                assets.append(
                    {
                        "asset_id": asset_id,
                        "fund_id": fund["fund_id"],
                        "asset_code": f"{fund['fund_code']}-{asset_type[:2].upper()}",
                        "asset_name": f"{fund['fund_name']} {asset_type}",
                        "asset_type": asset_type,
                        "sector": sector,
                        "country_code": random.choice(["US", "IN", "AU", "GB"]),
                        "market_value": round(random.uniform(100000, 5000000), 2),
                        "valuation_date": day.isoformat(),
                    }
                )
                asset_id += 1

    commission_daily: dict[tuple, float] = {}
    for row in commissions:
        key = (row["commission_date"], row["agent_id"], row["fund_id"], row["commission_type"], row["currency_code"])
        commission_daily.setdefault(key, 0)
        commission_daily[key] += row["commission_amount"]

    fact_commission = [
        {
            "commission_date": key[0],
            "agent_id": key[1],
            "fund_id": key[2],
            "commission_type": key[3],
            "currency_code": key[4],
            "commission_amount": round(value, 2),
        }
        for key, value in sorted(commission_daily.items())
    ]

    fund_flow_daily: dict[tuple, dict] = {}
    for row in transactions:
        key = (row["trade_date"], row["fund_id"], row["transaction_type"], row["currency_code"])
        fund_flow_daily.setdefault(key, {"transaction_count": 0, "net_amount": 0.0})
        fund_flow_daily[key]["transaction_count"] += 1
        fund_flow_daily[key]["net_amount"] += row["net_amount"]

    fact_flow = [
        {
            "trade_date": key[0],
            "fund_id": key[1],
            "transaction_type": key[2],
            "currency_code": key[3],
            "transaction_count": value["transaction_count"],
            "net_amount": round(value["net_amount"], 2),
        }
        for key, value in sorted(fund_flow_daily.items())
    ]

    write_csv(SOURCE / "Agent.csv", agents)
    write_csv(SOURCE / "Fund.csv", funds)
    write_csv(SOURCE / "Investor.csv", investors)
    write_csv(SOURCE / "Price.csv", prices)
    write_csv(SOURCE / "Transaction.csv", transactions)
    write_csv(SOURCE / "Holding.csv", holdings)
    write_csv(SOURCE / "Commission.csv", commissions)
    write_csv(SOURCE / "Asset.csv", assets)

    mart_agents = [{k: row[k] for k in ["agent_id", "agent_code", "agent_name", "channel"]} for row in agents]
    mart_funds = [{k: row[k] for k in ["fund_id", "fund_code", "fund_name", "asset_class"]} for row in funds]
    mart_investors = [{k: row[k] for k in ["investor_id", "agent_id", "investor_type", "country_code", "kyc_status", "risk_rating"]} for row in investors]
    mart_holdings = [
        {
            "valuation_date": row["valuation_date"],
            "investor_id": row["investor_id"],
            "fund_id": row["fund_id"],
            "currency_code": row["currency_code"],
            "holding_units": row["units"],
            "nav_price": row["nav_price"],
            "market_value": row["market_value"],
        }
        for row in holdings
    ]

    write_csv(MARTS / "dim_agent.csv", mart_agents)
    write_csv(MARTS / "dim_fund.csv", mart_funds)
    write_csv(MARTS / "dim_investor.csv", mart_investors)
    write_csv(MARTS / "fact_transaction.csv", transactions)
    write_csv(MARTS / "fact_agent_commission_daily.csv", fact_commission)
    write_csv(MARTS / "fact_investor_holding_daily.csv", mart_holdings)
    write_csv(MARTS / "fact_fund_flow_daily.csv", fact_flow)

    print(f"Source CSVs written to {SOURCE}")
    print(f"Demo mart CSVs written to {MARTS}")


if __name__ == "__main__":
    main()
