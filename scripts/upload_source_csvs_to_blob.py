from __future__ import annotations

import os
from pathlib import Path

try:
    from azure.storage.blob import BlobServiceClient, ContentSettings
except ImportError as exc:
    raise SystemExit(
        "azure-storage-blob is required. Install local dependencies with:\n"
        "pip install -r requirements-local.txt"
    ) from exc


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "sample_data" / "source"

DEFAULT_CONTAINER = "source-landing"
DEFAULT_PREFIX = "mutual-fund"


def blob_name_for(path: Path, prefix: str) -> str:
    name = path.name
    return f"{prefix.strip('/')}/{name}" if prefix else name


def main() -> None:
    connection_string = os.environ.get("AZURE_STORAGE_CONNECTION_STRING")
    if not connection_string:
        raise SystemExit(
            "Set AZURE_STORAGE_CONNECTION_STRING first. You can find it in:\n"
            "Azure Portal -> Storage Account -> Security + networking -> Access keys"
        )

    container_name = os.environ.get("AZURE_BLOB_CONTAINER", DEFAULT_CONTAINER)
    prefix = os.environ.get("AZURE_BLOB_PREFIX", DEFAULT_PREFIX)

    if not SOURCE.exists():
        raise SystemExit("Source files not found. Run: python scripts\\generate_sample_data.py")

    service = BlobServiceClient.from_connection_string(connection_string)
    container = service.get_container_client(container_name)

    try:
        container.create_container()
        print(f"Created container: {container_name}")
    except Exception:
        print(f"Using existing container: {container_name}")

    csv_files = sorted(SOURCE.glob("*.csv"))
    if not csv_files:
        raise SystemExit(f"No CSV files found in {SOURCE}")

    for path in csv_files:
        blob_name = blob_name_for(path, prefix)
        blob = container.get_blob_client(blob_name)
        with path.open("rb") as f:
            blob.upload_blob(
                f,
                overwrite=True,
                content_settings=ContentSettings(content_type="text/csv"),
            )
        print(f"Uploaded {path.name} -> {container_name}/{blob_name}")


if __name__ == "__main__":
    main()

