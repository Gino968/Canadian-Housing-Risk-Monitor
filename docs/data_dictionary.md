# Data Dictionary

## Master Dataset

Main file: `data/processed/canadian_housing_macro_master.csv`

| Column | Description |
| --- | --- |
| `month` | Monthly observation period, formatted as `YYYY-MM` |
| `cpi_all_items_index_2002_100` | Canada CPI all-items index, 2002 = 100 |
| `cpi_inflation_yoy_percent` | Year-over-year CPI inflation rate |
| `unemployment_rate_percent` | Canada unemployment rate, seasonally adjusted |
| `new_housing_price_index_canada_201612_100` | Canada new housing price index, total house and land, 2016-12 = 100 |
| `new_housing_price_index_canada_yoy_percent` | Year-over-year growth in the Canada new housing price index |
| `new_housing_price_index_toronto_201612_100` | Toronto new housing price index, total house and land, 2016-12 = 100 |
| `new_housing_price_index_toronto_yoy_percent` | Year-over-year growth in the Toronto new housing price index |
| `cmhc_5yr_conventional_mortgage_rate_percent` | CMHC conventional mortgage lending rate, 5-year term |
| `boc_policy_rate_monthly_average_percent` | Monthly average of Bank of Canada target overnight rate observations |
| `boc_policy_rate_month_end_percent` | Last available Bank of Canada target overnight rate observation in the month |
| `median_after_tax_income_cad_annual` | Canada median after-tax income, annual dollars, latest available reference year |
| `income_reference_year` | Source year for the annual income value |

Blank cells mean the source dataset has not published that observation or the series does not cover that period.

## Housing Risk Indicators

Main file: `data/processed/housing_risk_indicators.csv`

This file powers the Shiny dashboard and preserves selected macro fields from the master dataset while adding affordability and rate-shock indicators.

| Column | Description |
| --- | --- |
| `month` | Monthly observation period, formatted as `YYYY-MM` |
| `date` | Month converted to a first-of-month date for plotting |
| `income_reference_year` | Source year for the annual income value |
| `median_after_tax_income_cad_annual` | Canada median after-tax income, annual dollars |
| `monthly_income_cad` | Annual after-tax income divided by 12 |
| `proxy_home_price_canada_cad` | Canada home-price proxy derived from the Canada new housing price index |
| `proxy_home_price_toronto_cad` | Toronto home-price proxy derived from the Toronto new housing price index |
| `proxy_mortgage_principal_canada_cad` | Canada proxy home price after the baseline down payment assumption |
| `cmhc_5yr_conventional_mortgage_rate_percent` | CMHC conventional mortgage lending rate, 5-year term |
| `monthly_mortgage_payment_canada_cad` | Baseline monthly mortgage payment using the fixed-rate amortization formula |
| `payment_to_income_percent` | Baseline monthly mortgage payment divided by monthly after-tax income |
| `price_to_income_ratio_canada` | Canada proxy home price divided by annual after-tax income |
| `risk_level` | Baseline risk band: Low below 30%, Medium from 30% to below 40%, High at 40% and above |
| `monthly_payment_minus_0_5pp_cad` | Monthly payment under a -0.5 percentage point rate shock |
| `monthly_payment_change_minus_0_5pp_cad` | Difference between the -0.5pp scenario payment and baseline payment |
| `payment_to_income_minus_0_5pp_percent` | Payment-to-income ratio under the -0.5pp scenario |
| `monthly_payment_plus_0_5pp_cad` | Monthly payment under a +0.5 percentage point rate shock |
| `monthly_payment_change_plus_0_5pp_cad` | Difference between the +0.5pp scenario payment and baseline payment |
| `payment_to_income_plus_0_5pp_percent` | Payment-to-income ratio under the +0.5pp scenario |
| `monthly_payment_plus_1_0pp_cad` | Monthly payment under a +1.0 percentage point rate shock |
| `monthly_payment_change_plus_1_0pp_cad` | Difference between the +1.0pp scenario payment and baseline payment |
| `payment_to_income_plus_1_0pp_percent` | Payment-to-income ratio under the +1.0pp scenario |
| `monthly_payment_plus_2_0pp_cad` | Monthly payment under a +2.0 percentage point rate shock |
| `monthly_payment_change_plus_2_0pp_cad` | Difference between the +2.0pp scenario payment and baseline payment |
| `payment_to_income_plus_2_0pp_percent` | Payment-to-income ratio under the +2.0pp scenario |
| `risk_level_plus_2_0pp` | Risk band under the +2.0 percentage point rate shock |
| `cpi_inflation_yoy_percent` | Year-over-year CPI inflation rate |
| `unemployment_rate_percent` | Canada unemployment rate, seasonally adjusted |
| `new_housing_price_index_canada_201612_100` | Canada new housing price index, total house and land, 2016-12 = 100 |
| `new_housing_price_index_canada_yoy_percent` | Year-over-year growth in the Canada new housing price index |
| `new_housing_price_index_toronto_201612_100` | Toronto new housing price index, total house and land, 2016-12 = 100 |
| `new_housing_price_index_toronto_yoy_percent` | Year-over-year growth in the Toronto new housing price index |
| `boc_policy_rate_monthly_average_percent` | Monthly average of Bank of Canada target overnight rate observations |
