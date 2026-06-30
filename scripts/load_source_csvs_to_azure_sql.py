from __future__ import annotations

import csv
import os
from io import StringIO
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
DEFAULT_CONTAINER = "source-landing"
DEFAULT_PREFIX = "mutual-fund"

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


def read_rows_from_local(csv_name: str) -> list[dict]:
    path = SOURCE / f"{csv_name}.csv"
    if not path.exists():
        raise FileNotFoundError(path)

    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def read_rows_from_blob(csv_name: str) -> list[dict]:
    try:
        from azure.storage.blob import BlobServiceClient
    except ImportError as exc:
        raise SystemExit(
            "azure-storage-blob is required for Blob load mode. Install local dependencies with:\n"
            "pip install -r requirements-local.txt"
        ) from exc

    connection_string = os.environ.get("AZURE_STORAGE_CONNECTION_STRING")
    if not connection_string:
        raise SystemExit("Set AZURE_STORAGE_CONNECTION_STRING for Blob load mode.")

    container_name = os.environ.get("AZURE_BLOB_CONTAINER", DEFAULT_CONTAINER)
    prefix = os.environ.get("AZURE_BLOB_PREFIX", DEFAULT_PREFIX).strip("/")
    blob_name = f"{prefix}/{csv_name}.csv" if prefix else f"{csv_name}.csv"

    service = BlobServiceClient.from_connection_string(connection_string)
    blob = service.get_blob_client(container=container_name, blob=blob_name)
    text = blob.download_blob().content_as_text(encoding="utf-8")
    return list(csv.DictReader(StringIO(text)))


def read_rows(csv_name: str) -> list[dict]:
    source_mode = os.environ.get("AZURE_SQL_LOAD_SOURCE", "blob").lower()
    if source_mode == "local":
        return read_rows_from_local(csv_name)
    if source_mode == "blob":
        return read_rows_from_blob(csv_name)
    raise SystemExit("AZURE_SQL_LOAD_SOURCE must be either 'blob' or 'local'.")


def load_csv(cursor, csv_name: str, table_name: str) -> int:
    rows = read_rows(csv_name)

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

    source_mode = os.environ.get("AZURE_SQL_LOAD_SOURCE", "blob").lower()
    print(f"Loading Azure SQL from {source_mode} source")

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
