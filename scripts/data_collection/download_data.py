#!/usr/bin/env python3
"""Download first-pass official datasets for the housing risk monitor."""

from __future__ import annotations

import json
import time
import urllib.request
from argparse import ArgumentParser
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = PROJECT_ROOT / "data" / "raw"

SOURCES = [
    {
        "id": "statcan_cpi_18100004",
        "title": "Statistics Canada Table 18-10-0004-01, Consumer Price Index",
        "url": "https://www150.statcan.gc.ca/n1/tbl/csv/18100004-eng.zip",
        "filename": "statcan_18100004_cpi.zip",
    },
    {
        "id": "statcan_unemployment_14100287",
        "title": "Statistics Canada Table 14-10-0287-01, Labour force characteristics",
        "url": "https://www150.statcan.gc.ca/n1/tbl/csv/14100287-eng.zip",
        "filename": "statcan_14100287_labour_force.zip",
    },
    {
        "id": "statcan_new_housing_price_18100205",
        "title": "Statistics Canada Table 18-10-0205-01, New housing price index",
        "url": "https://www150.statcan.gc.ca/n1/tbl/csv/18100205-eng.zip",
        "filename": "statcan_18100205_new_housing_price_index.zip",
    },
    {
        "id": "statcan_mortgage_rate_34100145",
        "title": "Statistics Canada Table 34-10-0145-01, CMHC conventional mortgage lending rate, 5-year term",
        "url": "https://www150.statcan.gc.ca/n1/tbl/csv/34100145-eng.zip",
        "filename": "statcan_34100145_cmhc_5yr_mortgage_rate.zip",
    },
    {
        "id": "statcan_income_11100190",
        "title": "Statistics Canada Table 11-10-0190-01, Market, total and after-tax income",
        "url": "https://www150.statcan.gc.ca/n1/tbl/csv/11100190-eng.zip",
        "filename": "statcan_11100190_income.zip",
    },
    {
        "id": "boc_policy_rate_v39079",
        "title": "Bank of Canada Valet API, target for the overnight rate",
        "url": "https://www.bankofcanada.ca/valet/observations/V39079/csv?start_date=2000-01-01",
        "filename": "bank_of_canada_v39079_policy_rate.csv",
    },
]


def download(url: str, destination: Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": "Canadian-Housing-Risk-Monitor/0.1"})
    with urllib.request.urlopen(request, timeout=180) as response:
        destination.write_bytes(response.read())


def parse_args():
    parser = ArgumentParser(description="Download official raw data files.")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-download files even when they already exist in data/raw.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    manifest = []

    for source in SOURCES:
        destination = RAW_DIR / source["filename"]
        downloaded_at = None
        status = "cached"

        if args.force or not destination.exists():
            print(f"Downloading {source['id']} -> {destination}")
            download(source["url"], destination)
            downloaded_at = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            status = "downloaded"
        else:
            print(f"Using cached {source['id']} -> {destination}")

        manifest.append(
            {
                **source,
                "local_path": str(destination.relative_to(PROJECT_ROOT)),
                "status": status,
                "downloaded_at": downloaded_at,
                "checked_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "bytes": destination.stat().st_size,
            }
        )

    (RAW_DIR / "source_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Wrote manifest: {RAW_DIR / 'source_manifest.json'}")


if __name__ == "__main__":
    main()
