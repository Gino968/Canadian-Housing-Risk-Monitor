#!/usr/bin/env python3
"""Run the local data pipeline and sync dashboard-ready data."""

from __future__ import annotations

import shutil
import subprocess
import sys
from argparse import ArgumentParser
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
APP_DATA_DIR = PROJECT_ROOT / "app" / "data"
INDICATORS_FILE = "housing_risk_indicators.csv"


def run_step(args: list[str]) -> None:
    subprocess.run([sys.executable, *args], cwd=PROJECT_ROOT, check=True)


def parse_args():
    parser = ArgumentParser(description="Run the Canadian Housing Risk Monitor data pipeline.")
    parser.add_argument(
        "--skip-download",
        action="store_true",
        help="Use existing raw files and skip the download step entirely.",
    )
    parser.add_argument(
        "--force-download",
        action="store_true",
        help="Refresh raw files from the official sources before rebuilding outputs.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    if not args.skip_download:
        download_args = ["scripts/data_collection/download_data.py"]
        if args.force_download:
            download_args.append("--force")
        run_step(download_args)

    run_step(["scripts/data_cleaning/build_master_dataset.py"])
    run_step(["scripts/analysis/build_risk_indicators.py"])

    APP_DATA_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copy2(PROCESSED_DIR / INDICATORS_FILE, APP_DATA_DIR / INDICATORS_FILE)
    print(f"Synced dashboard data to {APP_DATA_DIR / INDICATORS_FILE}")


if __name__ == "__main__":
    main()
