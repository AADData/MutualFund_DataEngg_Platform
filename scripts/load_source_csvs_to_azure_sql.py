from __future__ import annotations

import csv
import os
from pathlib import Path

try:
    import pyodbc
except ImportError as exc:
    raise SystemExit(
        "pyodbc is required. Install it with: pip install pyodbc\n"
        "You also need the Microsoft ODBC Driver for SQL Server."
    ) from exc


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "sample_data" / "source"

LOAD_ORDER = [
    ("Agent", "dbo.Agent"),
    ("Fund", "dbo.Fund"),
    ("Investor", "dbo.Investor"),
    ("Price", "dbo.Price"),
    ("Transaction", "dbo.[Transaction]"),
    ("Holding", "dbo.Holding"),
    ("Commission", "dbo.Commission"),
    ("Asset", "dbo.Asset"),
]

TRUNCATE_ORDER = [
    "dbo.Asset",
    "dbo.Commission",
    "dbo.Holding",
    "dbo.[Transaction]",
    "dbo.Price",
    "dbo.Investor",
    "dbo.Fund",
    "dbo.Agent",
]


def clean(value: str) -> str | None:
    return None if value == "" else value


def load_csv(cursor, csv_name: str, table_name: str) -> int:
    path = SOURCE / f"{csv_name}.csv"
    if not path.exists():
        raise FileNotFoundError(path)

    with path.open(newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    if not rows:
        return 0

    columns = list(rows[0].keys())
    placeholders = ", ".join("?" for _ in columns)
    column_sql = ", ".join(f"[{column}]" for column in columns)
    insert_sql = f"INSERT INTO {table_name} ({column_sql}) VALUES ({placeholders})"
    values = [[clean(row[column]) for column in columns] for row in rows]

    cursor.fast_executemany = True
    cursor.execute(f"SET IDENTITY_INSERT {table_name} ON")
    cursor.executemany(insert_sql, values)
    cursor.execute(f"SET IDENTITY_INSERT {table_name} OFF")
    return len(rows)


def main() -> None:
    connection_string = os.environ.get("AZURE_SQL_CONNECTION_STRING")
    if not connection_string:
        raise SystemExit(
            "Set AZURE_SQL_CONNECTION_STRING first. Example:\n"
            "Server=tcp:<server>.database.windows.net,1433;Database=<db>;"
            "Uid=<user>;Pwd=<password>;Encrypt=yes;TrustServerCertificate=no;"
            "Connection Timeout=30;"
        )

    with pyodbc.connect(connection_string) as conn:
        cursor = conn.cursor()
        for table in TRUNCATE_ORDER:
            cursor.execute(f"DELETE FROM {table}")
        conn.commit()

        for csv_name, table_name in LOAD_ORDER:
            count = load_csv(cursor, csv_name, table_name)
            conn.commit()
            print(f"Loaded {count:>5} rows into {table_name}")


if __name__ == "__main__":
    main()
