from __future__ import annotations

import zipfile

import pandas as pd
import pytest

from scripts.data_cleaning.build_master_dataset import (
    add_latest_available_income,
    add_yoy,
    assert_unique_months,
    merge_monthly_tables,
    resolve_csv_member,
)


def test_resolve_csv_member_finds_table_csv_inside_statcan_zip(tmp_path) -> None:
    archive_path = tmp_path / "statcan.zip"
    with zipfile.ZipFile(archive_path, "w") as archive:
        archive.writestr("18100004_MetaData.csv", "metadata")
        archive.writestr("18100004.csv", "REF_DATE,VALUE\n2024-01,1\n")

    with zipfile.ZipFile(archive_path) as archive:
        member = resolve_csv_member(archive, "18100004.csv")

    assert member == "18100004.csv"


def test_add_yoy_uses_12_month_percent_change() -> None:
    df = pd.DataFrame(
        {
            "month": pd.period_range("2023-01", periods=13, freq="M").astype(str),
            "value": list(range(100, 113)),
        }
    )

    result = add_yoy(df, "value", "value_yoy_percent")

    assert pd.isna(result.loc[0, "value_yoy_percent"])
    assert result.loc[12, "value_yoy_percent"] == pytest.approx(12.0)


def test_assert_unique_months_raises_for_duplicate_months() -> None:
    df = pd.DataFrame({"month": ["2024-01", "2024-01"], "value": [1, 2]})

    with pytest.raises(ValueError, match="duplicate months"):
        assert_unique_months(df, "example")


def test_merge_monthly_tables_preserves_unique_sorted_months() -> None:
    left = pd.DataFrame({"month": ["1981-02", "1981-01"], "a": [2, 1]})
    right = pd.DataFrame({"month": ["1981-01", "1981-02"], "b": [10, 20]})

    result = merge_monthly_tables([left, right])

    assert result["month"].tolist() == ["1981-01", "1981-02"]
    assert result["b"].tolist() == [10, 20]


def test_add_latest_available_income_uses_most_recent_prior_income_year() -> None:
    master = pd.DataFrame({"month": ["2021-12", "2022-01", "2024-06"]})
    income = pd.DataFrame(
        {
            "year": [2020, 2022],
            "median_after_tax_income_cad_annual": [70_000, 76_000],
        }
    )

    result = add_latest_available_income(master, income)

    assert result["income_reference_year"].tolist() == [2020, 2022, 2022]
    assert result["median_after_tax_income_cad_annual"].tolist() == [70_000, 76_000, 76_000]
