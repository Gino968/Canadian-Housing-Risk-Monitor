#!/usr/bin/env python3
"""Build housing affordability risk indicators and first-pass EDA figures."""

from __future__ import annotations

import os
from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
FIGURES_DIR = PROJECT_ROOT / "outputs" / "figures"
MPL_CONFIG_DIR = PROJECT_ROOT / ".cache" / "matplotlib"
MPL_CONFIG_DIR.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("MPLCONFIGDIR", str(MPL_CONFIG_DIR))

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

MASTER_DATASET = PROCESSED_DIR / "canadian_housing_macro_master.csv"
INDICATORS_OUTPUT = PROCESSED_DIR / "housing_risk_indicators.csv"

BASELINE_HOME_PRICE_CAD = 700_000
BASELINE_HOME_PRICE_INDEX = 100
BASELINE_DOWN_PAYMENT_PERCENT = 20
AMORTIZATION_YEARS = 25
RISK_SCENARIOS = {
    "minus_0_5pp": -0.5,
    "plus_0_5pp": 0.5,
    "plus_1_0pp": 1.0,
    "plus_2_0pp": 2.0,
}


def calculate_monthly_payment(
    principal: pd.Series | float,
    annual_rate_percent: pd.Series | float,
    amortization_years: int = AMORTIZATION_YEARS,
) -> pd.Series | float:
    """Calculate a fixed-payment mortgage monthly payment."""
    monthly_rate = annual_rate_percent / 100 / 12
    number_of_payments = amortization_years * 12
    zero_rate_payment = principal / number_of_payments
    if np.isscalar(monthly_rate) and monthly_rate == 0:
        return zero_rate_payment
    amortized_payment = (
        principal
        * monthly_rate
        * (1 + monthly_rate) ** number_of_payments
        / ((1 + monthly_rate) ** number_of_payments - 1)
    )
    return np.where(monthly_rate == 0, zero_rate_payment, amortized_payment)


def classify_payment_to_income(payment_to_income_percent: pd.Series) -> pd.Series:
    """Classify affordability risk using payment-to-income thresholds."""
    return pd.cut(
        payment_to_income_percent,
        bins=[-np.inf, 30, 40, np.inf],
        labels=["Low Risk", "Medium Risk", "High Risk"],
        right=False,
    ).astype("string")


def classify_relative_pressure(payment_to_income_percent: pd.Series) -> pd.Series:
    """Classify historical pressure using within-series tertiles."""
    lower_threshold = payment_to_income_percent.quantile(1 / 3)
    upper_threshold = payment_to_income_percent.quantile(2 / 3)
    return pd.cut(
        payment_to_income_percent,
        bins=[-np.inf, lower_threshold, upper_threshold, np.inf],
        labels=["Low Relative Pressure", "Medium Relative Pressure", "High Relative Pressure"],
        include_lowest=True,
    ).astype("string")


def build_indicators(master: pd.DataFrame) -> pd.DataFrame:
    df = master.copy()
    df = df.dropna(
        subset=[
            "new_housing_price_index_canada_201612_100",
            "new_housing_price_index_toronto_201612_100",
            "cmhc_5yr_conventional_mortgage_rate_percent",
            "median_after_tax_income_cad_annual",
        ]
    ).reset_index(drop=True)
    df["date"] = pd.to_datetime(df["month"] + "-01")
    df["proxy_home_price_canada_cad"] = (
        df["new_housing_price_index_canada_201612_100"]
        / BASELINE_HOME_PRICE_INDEX
        * BASELINE_HOME_PRICE_CAD
    ).round(2)
    df["proxy_home_price_toronto_cad"] = (
        df["new_housing_price_index_toronto_201612_100"]
        / BASELINE_HOME_PRICE_INDEX
        * BASELINE_HOME_PRICE_CAD
    ).round(2)

    down_payment_share = BASELINE_DOWN_PAYMENT_PERCENT / 100
    df["proxy_mortgage_principal_canada_cad"] = (
        df["proxy_home_price_canada_cad"] * (1 - down_payment_share)
    ).round(2)
    df["monthly_income_cad"] = (df["median_after_tax_income_cad_annual"] / 12).round(2)
    df["monthly_mortgage_payment_canada_cad"] = calculate_monthly_payment(
        df["proxy_mortgage_principal_canada_cad"],
        df["cmhc_5yr_conventional_mortgage_rate_percent"],
    ).round(2)
    df["payment_to_income_percent"] = (
        df["monthly_mortgage_payment_canada_cad"] / df["monthly_income_cad"] * 100
    ).round(2)
    df["price_to_income_ratio_canada"] = (
        df["proxy_home_price_canada_cad"] / df["median_after_tax_income_cad_annual"]
    ).round(2)

    for scenario_name, rate_delta in RISK_SCENARIOS.items():
        scenario_rate = df["cmhc_5yr_conventional_mortgage_rate_percent"] + rate_delta
        scenario_rate = scenario_rate.clip(lower=0)
        scenario_payment = calculate_monthly_payment(
            df["proxy_mortgage_principal_canada_cad"],
            scenario_rate,
        )
        payment_col = f"monthly_payment_{scenario_name}_cad"
        change_col = f"monthly_payment_change_{scenario_name}_cad"
        ratio_col = f"payment_to_income_{scenario_name}_percent"
        df[payment_col] = scenario_payment.round(2)
        df[change_col] = (df[payment_col] - df["monthly_mortgage_payment_canada_cad"]).round(2)
        df[ratio_col] = (df[payment_col] / df["monthly_income_cad"] * 100).round(2)

    df["risk_level"] = classify_payment_to_income(df["payment_to_income_percent"])
    df["risk_level_plus_2_0pp"] = classify_payment_to_income(
        df["payment_to_income_plus_2_0pp_percent"]
    )
    df["relative_risk_level"] = classify_relative_pressure(df["payment_to_income_percent"])
    df["relative_risk_level_plus_2_0pp"] = classify_relative_pressure(
        df["payment_to_income_plus_2_0pp_percent"]
    )

    ordered_columns = [
        "month",
        "date",
        "income_reference_year",
        "median_after_tax_income_cad_annual",
        "monthly_income_cad",
        "proxy_home_price_canada_cad",
        "proxy_home_price_toronto_cad",
        "proxy_mortgage_principal_canada_cad",
        "cmhc_5yr_conventional_mortgage_rate_percent",
        "monthly_mortgage_payment_canada_cad",
        "payment_to_income_percent",
        "price_to_income_ratio_canada",
        "risk_level",
        "relative_risk_level",
        "monthly_payment_minus_0_5pp_cad",
        "monthly_payment_change_minus_0_5pp_cad",
        "payment_to_income_minus_0_5pp_percent",
        "monthly_payment_plus_0_5pp_cad",
        "monthly_payment_change_plus_0_5pp_cad",
        "payment_to_income_plus_0_5pp_percent",
        "monthly_payment_plus_1_0pp_cad",
        "monthly_payment_change_plus_1_0pp_cad",
        "payment_to_income_plus_1_0pp_percent",
        "monthly_payment_plus_2_0pp_cad",
        "monthly_payment_change_plus_2_0pp_cad",
        "payment_to_income_plus_2_0pp_percent",
        "risk_level_plus_2_0pp",
        "relative_risk_level_plus_2_0pp",
        "cpi_inflation_yoy_percent",
        "unemployment_rate_percent",
        "new_housing_price_index_canada_201612_100",
        "new_housing_price_index_canada_yoy_percent",
        "new_housing_price_index_toronto_201612_100",
        "new_housing_price_index_toronto_yoy_percent",
        "boc_policy_rate_monthly_average_percent",
    ]
    return df[ordered_columns]


def save_line_chart(
    df: pd.DataFrame,
    columns: list[str],
    labels: list[str],
    title: str,
    ylabel: str,
    filename: str,
) -> None:
    fig, ax = plt.subplots(figsize=(11, 6))
    for column, label in zip(columns, labels):
        ax.plot(df["date"], df[column], linewidth=1.8, label=label)
    ax.set_title(title)
    ax.set_ylabel(ylabel)
    ax.set_xlabel("")
    ax.grid(True, alpha=0.25)
    ax.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(FIGURES_DIR / filename, dpi=180)
    plt.close(fig)


def save_figures(indicators: pd.DataFrame) -> None:
    FIGURES_DIR.mkdir(parents=True, exist_ok=True)
    plot_df = indicators[indicators["month"] <= indicators["month"].max()].copy()

    save_line_chart(
        plot_df,
        [
            "new_housing_price_index_canada_201612_100",
            "new_housing_price_index_toronto_201612_100",
        ],
        ["Canada", "Toronto"],
        "New Housing Price Index",
        "Index, Dec. 2016 = 100",
        "housing_price_index_canada_toronto.png",
    )
    save_line_chart(
        plot_df,
        [
            "cmhc_5yr_conventional_mortgage_rate_percent",
            "boc_policy_rate_monthly_average_percent",
        ],
        ["CMHC 5-year mortgage rate", "Bank of Canada policy rate"],
        "Interest Rates",
        "Percent",
        "interest_rates.png",
    )
    save_line_chart(
        plot_df,
        ["cpi_inflation_yoy_percent", "unemployment_rate_percent"],
        ["CPI inflation, YoY", "Unemployment rate"],
        "Inflation and Unemployment",
        "Percent",
        "inflation_unemployment.png",
    )
    save_line_chart(
        plot_df,
        ["payment_to_income_percent", "payment_to_income_plus_2_0pp_percent"],
        ["Baseline", "+2 percentage point rate shock"],
        "Mortgage Payment-to-Income Risk Proxy",
        "Monthly payment / monthly after-tax income (%)",
        "payment_to_income_risk_proxy.png",
    )


def write_summary(indicators: pd.DataFrame) -> None:
    latest = indicators.dropna(subset=["payment_to_income_percent"]).iloc[-1]
    summary = [
        "Canadian Housing Risk Monitor analysis summary",
        "",
        f"Latest month: {latest['month']}",
        f"Proxy Canada home price: ${latest['proxy_home_price_canada_cad']:,.0f}",
        f"CMHC 5-year mortgage rate: {latest['cmhc_5yr_conventional_mortgage_rate_percent']:.2f}%",
        f"Monthly mortgage payment: ${latest['monthly_mortgage_payment_canada_cad']:,.0f}",
        f"Payment-to-income ratio: {latest['payment_to_income_percent']:.1f}%",
        f"Absolute risk level: {latest['risk_level']}",
        f"Relative historical pressure: {latest['relative_risk_level']}",
        f"+2pp shock payment-to-income ratio: {latest['payment_to_income_plus_2_0pp_percent']:.1f}%",
        f"+2pp shock absolute risk level: {latest['risk_level_plus_2_0pp']}",
        f"+2pp shock relative historical pressure: {latest['relative_risk_level_plus_2_0pp']}",
        "",
        "Assumptions:",
        f"- Baseline Canada home price proxy is ${BASELINE_HOME_PRICE_CAD:,.0f} when the housing price index equals {BASELINE_HOME_PRICE_INDEX}.",
        f"- Down payment is {BASELINE_DOWN_PAYMENT_PERCENT}% and amortization is {AMORTIZATION_YEARS} years.",
        "- Risk bands use monthly mortgage payment divided by monthly after-tax income: Low below 30%, Medium 30% to below 40%, High at 40% and above.",
        "- Relative pressure bands split the available historical series into low, medium, and high thirds.",
    ]
    (PROCESSED_DIR / "housing_risk_analysis_summary.txt").write_text(
        "\n".join(summary) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    master = pd.read_csv(MASTER_DATASET)
    indicators = build_indicators(master)
    indicators.to_csv(INDICATORS_OUTPUT, index=False)
    save_figures(indicators)
    write_summary(indicators)


if __name__ == "__main__":
    main()
