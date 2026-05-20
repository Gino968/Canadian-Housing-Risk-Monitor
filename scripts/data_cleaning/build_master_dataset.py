#!/usr/bin/env python3
"""Build the first monthly macro-housing master dataset with pandas."""

from __future__ import annotations

import zipfile
from datetime import datetime
from pathlib import Path
from typing import Optional

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = PROJECT_ROOT / "data" / "raw"
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
MASTER_START_MONTH = "1981-01"


def resolve_csv_member(archive: zipfile.ZipFile, csv_name: str) -> str:
    names = archive.namelist()
    if csv_name in names:
        return csv_name

    table_id = Path(csv_name).stem
    candidates = [
        name
        for name in names
        if name.lower().endswith(".csv")
        and "metadata" not in Path(name).stem.lower()
        and Path(name).stem.startswith(table_id)
    ]
    if len(candidates) == 1:
        return candidates[0]

    data_csvs = [
        name
        for name in names
        if name.lower().endswith(".csv") and "metadata" not in Path(name).stem.lower()
    ]
    if len(data_csvs) == 1:
        return data_csvs[0]

    raise FileNotFoundError(
        f"Could not find data CSV '{csv_name}' in {archive.filename}. Available CSV files: {names}"
    )


def read_statcan_csv(zip_name: str, csv_name: str, usecols: Optional[list[str]] = None) -> pd.DataFrame:
    path = RAW_DIR / zip_name
    with zipfile.ZipFile(path) as archive:
        member = resolve_csv_member(archive, csv_name)
    with zipfile.ZipFile(path) as archive, archive.open(member) as handle:
        return pd.read_csv(handle, usecols=usecols, encoding="utf-8-sig", low_memory=False)


def month_from_ref_date(series: pd.Series) -> pd.Series:
    return series.astype(str).str.slice(0, 7)


def numeric(series: pd.Series) -> pd.Series:
    return pd.to_numeric(series, errors="coerce")


def add_yoy(df: pd.DataFrame, value_col: str, yoy_col: str) -> pd.DataFrame:
    df = df.sort_values("month").copy()
    df[yoy_col] = (df[value_col].pct_change(12) * 100).round(4)
    return df


def write_csv(df: pd.DataFrame, filename: str) -> None:
    path = PROCESSED_DIR / filename
    df.to_csv(path, index=False)


def assert_unique_months(df: pd.DataFrame, name: str) -> None:
    if "month" in df.columns and df["month"].duplicated().any():
        duplicates = df.loc[df["month"].duplicated(), "month"].head().tolist()
        raise ValueError(f"{name} has duplicate months: {duplicates}")


def cpi_canada() -> pd.DataFrame:
    df = read_statcan_csv(
        "statcan_18100004_cpi.zip",
        "18100004.csv",
        usecols=["REF_DATE", "GEO", "Products and product groups", "VALUE"],
    )
    df = df[(df["GEO"] == "Canada") & (df["Products and product groups"] == "All-items")].copy()
    df["month"] = month_from_ref_date(df["REF_DATE"])
    df["cpi_all_items_index_2002_100"] = numeric(df["VALUE"])
    df = df[["month", "cpi_all_items_index_2002_100"]].dropna()
    df = add_yoy(df, "cpi_all_items_index_2002_100", "cpi_inflation_yoy_percent")
    assert_unique_months(df, "cpi_canada")
    return df


def unemployment_canada() -> pd.DataFrame:
    df = read_statcan_csv(
        "statcan_14100287_labour_force.zip",
        "14100287.csv",
        usecols=[
            "REF_DATE",
            "GEO",
            "Labour force characteristics",
            "Gender",
            "Age group",
            "Statistics",
            "Data type",
            "VALUE",
        ],
    )
    df = df[
        (df["GEO"] == "Canada")
        & (df["Labour force characteristics"] == "Unemployment rate")
        & (df["Gender"] == "Total - Gender")
        & (df["Age group"] == "15 years and over")
        & (df["Statistics"] == "Estimate")
        & (df["Data type"] == "Seasonally adjusted")
    ].copy()
    df["month"] = month_from_ref_date(df["REF_DATE"])
    df["unemployment_rate_percent"] = numeric(df["VALUE"])
    df = df[["month", "unemployment_rate_percent"]].dropna()
    assert_unique_months(df, "unemployment_canada")
    return df


def housing_price_indexes() -> pd.DataFrame:
    df = read_statcan_csv(
        "statcan_18100205_new_housing_price_index.zip",
        "18100205.csv",
        usecols=["REF_DATE", "GEO", "New housing price indexes", "VALUE"],
    )
    df = df[
        (df["New housing price indexes"] == "Total (house and land)")
        & (df["GEO"].isin(["Canada", "Toronto, Ontario"]))
    ].copy()
    df["month"] = month_from_ref_date(df["REF_DATE"])
    df["VALUE"] = numeric(df["VALUE"])
    df = df.pivot_table(index="month", columns="GEO", values="VALUE", aggfunc="first").reset_index()
    df = df.rename(
        columns={
            "Canada": "new_housing_price_index_canada_201612_100",
            "Toronto, Ontario": "new_housing_price_index_toronto_201612_100",
        }
    )
    df = add_yoy(
        df,
        "new_housing_price_index_canada_201612_100",
        "new_housing_price_index_canada_yoy_percent",
    )
    df = add_yoy(
        df,
        "new_housing_price_index_toronto_201612_100",
        "new_housing_price_index_toronto_yoy_percent",
    )
    df = df[
        [
            "month",
            "new_housing_price_index_canada_201612_100",
            "new_housing_price_index_canada_yoy_percent",
            "new_housing_price_index_toronto_201612_100",
            "new_housing_price_index_toronto_yoy_percent",
        ]
    ]
    assert_unique_months(df, "housing_price_indexes")
    return df


def mortgage_rate_canada() -> pd.DataFrame:
    df = read_statcan_csv(
        "statcan_34100145_cmhc_5yr_mortgage_rate.zip",
        "34100145.csv",
        usecols=["REF_DATE", "GEO", "VALUE"],
    )
    df = df[df["GEO"] == "Canada"].copy()
    df["month"] = month_from_ref_date(df["REF_DATE"])
    df["cmhc_5yr_conventional_mortgage_rate_percent"] = numeric(df["VALUE"])
    df = df[["month", "cmhc_5yr_conventional_mortgage_rate_percent"]].dropna()
    assert_unique_months(df, "mortgage_rate_canada")
    return df


def income_canada() -> pd.DataFrame:
    df = read_statcan_csv(
        "statcan_11100190_income.zip",
        "11100190.csv",
        usecols=["REF_DATE", "GEO", "Income concept", "Economic family type", "VALUE"],
    )
    df = df[
        (df["GEO"] == "Canada")
        & (df["Income concept"] == "Median after-tax income")
        & (df["Economic family type"] == "Economic families and persons not in an economic family")
    ].copy()
    df["year"] = numeric(df["REF_DATE"]).astype("Int64")
    df["median_after_tax_income_cad_annual"] = numeric(df["VALUE"])
    df = df[["year", "median_after_tax_income_cad_annual"]].dropna()
    df["year"] = df["year"].astype(int)
    df = df.sort_values("year").drop_duplicates("year", keep="last")
    return df


def policy_rate_canada() -> pd.DataFrame:
    path = RAW_DIR / "bank_of_canada_v39079_policy_rate.csv"
    lines = path.read_text(encoding="utf-8-sig").splitlines()
    observations_index = lines.index('"OBSERVATIONS"')
    df = pd.read_csv(path, skiprows=observations_index + 1)
    df["date"] = pd.to_datetime(df["date"], errors="coerce")
    df["V39079"] = numeric(df["V39079"])
    df = df.dropna(subset=["date", "V39079"]).sort_values("date")
    df["month"] = df["date"].dt.to_period("M").astype(str)

    monthly_average = df.groupby("month", as_index=False)["V39079"].mean()
    monthly_average = monthly_average.rename(columns={"V39079": "boc_policy_rate_monthly_average_percent"})
    monthly_average["boc_policy_rate_monthly_average_percent"] = monthly_average[
        "boc_policy_rate_monthly_average_percent"
    ].round(4)

    monthly_last = df.groupby("month", as_index=False).tail(1)[["month", "V39079"]]
    monthly_last = monthly_last.rename(columns={"V39079": "boc_policy_rate_month_end_percent"})

    policy = monthly_average.merge(monthly_last, on="month", how="outer").sort_values("month")
    assert_unique_months(policy, "policy_rate_canada")
    return policy


def merge_monthly_tables(tables: list[pd.DataFrame]) -> pd.DataFrame:
    master = tables[0]
    for table in tables[1:]:
        master = master.merge(table, on="month", how="outer")
    master = master[master["month"] >= MASTER_START_MONTH].sort_values("month").reset_index(drop=True)
    assert_unique_months(master, "master_dataset")
    return master


def add_latest_available_income(master: pd.DataFrame, income: pd.DataFrame) -> pd.DataFrame:
    master = master.copy()
    master["year"] = master["month"].str.slice(0, 4).astype(int)
    income = income.rename(columns={"year": "income_reference_year"}).sort_values("income_reference_year")
    income["income_reference_year"] = income["income_reference_year"].astype(int)
    master = pd.merge_asof(
        master.sort_values("year"),
        income,
        left_on="year",
        right_on="income_reference_year",
        direction="backward",
    )
    master = master.sort_values("month").drop(columns=["year"]).reset_index(drop=True)
    return master


def quality_report(datasets: dict[str, pd.DataFrame], master: pd.DataFrame) -> str:
    lines = [
        "Canadian Housing Risk Monitor data quality report",
        f"Generated at: {datetime.now().isoformat(timespec='seconds')}",
        "",
        "Dataset ranges:",
    ]
    for name, df in datasets.items():
        if "month" in df.columns:
            lines.append(f"- {name}: {len(df):,} rows, {df['month'].min()} to {df['month'].max()}")
        elif "year" in df.columns:
            lines.append(f"- {name}: {len(df):,} rows, {int(df['year'].min())} to {int(df['year'].max())}")

    lines.extend(["", "Master dataset:", f"- Rows: {len(master):,}", f"- Range: {master['month'].min()} to {master['month'].max()}"])
    lines.append(f"- Duplicate months: {int(master['month'].duplicated().sum())}")
    lines.append("")
    lines.append("Missing values by master column:")
    missing = master.isna().sum().sort_values(ascending=False)
    for column, count in missing.items():
        lines.append(f"- {column}: {int(count):,}")
    return "\n".join(lines) + "\n"


def main() -> None:
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    datasets = {
        "cpi_canada": cpi_canada(),
        "unemployment_canada": unemployment_canada(),
        "housing_price_indexes": housing_price_indexes(),
        "mortgage_rate_canada": mortgage_rate_canada(),
        "policy_rate_canada": policy_rate_canada(),
        "income_canada": income_canada(),
    }

    master = merge_monthly_tables(
        [
            datasets["cpi_canada"],
            datasets["unemployment_canada"],
            datasets["housing_price_indexes"],
            datasets["mortgage_rate_canada"],
            datasets["policy_rate_canada"],
        ]
    )
    master = add_latest_available_income(master, datasets["income_canada"])

    write_csv(datasets["cpi_canada"], "cpi_canada.csv")
    write_csv(datasets["unemployment_canada"], "unemployment_canada.csv")
    write_csv(
        datasets["housing_price_indexes"][
            [
                "month",
                "new_housing_price_index_canada_201612_100",
                "new_housing_price_index_toronto_201612_100",
            ]
        ],
        "new_housing_price_index_canada_toronto.csv",
    )
    write_csv(datasets["mortgage_rate_canada"], "mortgage_rate_canada.csv")
    write_csv(datasets["policy_rate_canada"], "policy_rate_canada.csv")
    write_csv(datasets["income_canada"], "income_canada_annual.csv")
    write_csv(master, "canadian_housing_macro_master.csv")

    report = quality_report(datasets, master)
    (PROCESSED_DIR / "data_quality_report.txt").write_text(report, encoding="utf-8")

    print(f"Wrote {len(master)} monthly rows to {PROCESSED_DIR / 'canadian_housing_macro_master.csv'}")
    print(f"Latest month in master dataset: {master['month'].max()}")
    print(f"Wrote quality report to {PROCESSED_DIR / 'data_quality_report.txt'}")


if __name__ == "__main__":
    main()
