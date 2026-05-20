from __future__ import annotations

import numpy as np
import pandas as pd
import pytest

from scripts.analysis.build_risk_indicators import (
    AMORTIZATION_YEARS,
    BASELINE_DOWN_PAYMENT_PERCENT,
    BASELINE_HOME_PRICE_CAD,
    calculate_monthly_payment,
    classify_relative_pressure,
    classify_payment_to_income,
    build_indicators,
)


def as_float(value) -> float:
    return float(np.asarray(value))


def test_monthly_payment_uses_straight_line_payment_for_zero_rate() -> None:
    principal = 300_000

    payment = calculate_monthly_payment(principal, 0)

    assert as_float(payment) == pytest.approx(principal / (AMORTIZATION_YEARS * 12))


def test_monthly_payment_matches_fixed_rate_formula() -> None:
    principal = 560_000
    annual_rate_percent = 5.13
    monthly_rate = annual_rate_percent / 100 / 12
    number_of_payments = AMORTIZATION_YEARS * 12
    expected = (
        principal
        * monthly_rate
        * (1 + monthly_rate) ** number_of_payments
        / ((1 + monthly_rate) ** number_of_payments - 1)
    )

    payment = calculate_monthly_payment(principal, annual_rate_percent)

    assert as_float(payment) == pytest.approx(expected)


def test_risk_classification_matches_documented_thresholds() -> None:
    ratios = pd.Series([29.99, 30.0, 39.99, 40.0])

    levels = classify_payment_to_income(ratios)

    assert levels.tolist() == ["Low Risk", "Medium Risk", "Medium Risk", "High Risk"]


def test_relative_pressure_classification_splits_history_into_tertiles() -> None:
    ratios = pd.Series([10, 20, 30, 40, 50, 60])

    levels = classify_relative_pressure(ratios)

    assert set(levels) == {
        "Low Relative Pressure",
        "Medium Relative Pressure",
        "High Relative Pressure",
    }


def test_build_indicators_creates_expected_affordability_columns() -> None:
    master = pd.DataFrame(
        {
            "month": ["2024-01", "2024-02"],
            "income_reference_year": [2022, 2022],
            "median_after_tax_income_cad_annual": [84_000, 84_000],
            "new_housing_price_index_canada_201612_100": [100.0, 105.0],
            "new_housing_price_index_toronto_201612_100": [120.0, 126.0],
            "cmhc_5yr_conventional_mortgage_rate_percent": [0.25, 5.25],
            "cpi_inflation_yoy_percent": [2.1, 2.3],
            "unemployment_rate_percent": [6.0, 6.1],
            "new_housing_price_index_canada_yoy_percent": [1.0, 1.2],
            "new_housing_price_index_toronto_yoy_percent": [1.4, 1.6],
            "boc_policy_rate_monthly_average_percent": [5.0, 5.0],
        }
    )

    indicators = build_indicators(master)

    assert len(indicators) == 2
    assert indicators.loc[0, "proxy_home_price_canada_cad"] == pytest.approx(BASELINE_HOME_PRICE_CAD)
    assert indicators.loc[0, "proxy_mortgage_principal_canada_cad"] == pytest.approx(
        BASELINE_HOME_PRICE_CAD * (1 - BASELINE_DOWN_PAYMENT_PERCENT / 100)
    )
    assert indicators.loc[0, "monthly_payment_minus_0_5pp_cad"] > 0
    assert indicators.loc[0, "monthly_payment_minus_0_5pp_cad"] <= indicators.loc[
        0, "monthly_mortgage_payment_canada_cad"
    ]
    assert set(indicators["risk_level"].dropna().unique()).issubset(
        {"Low Risk", "Medium Risk", "High Risk"}
    )
    assert "relative_risk_level" in indicators.columns
    assert indicators["relative_risk_level"].notna().all()
