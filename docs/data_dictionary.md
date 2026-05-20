# Data Dictionary

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
