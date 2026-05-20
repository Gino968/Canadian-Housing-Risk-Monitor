# Data Sources

This project starts with official Canadian data sources that are stable enough for a reproducible portfolio project.

| Dataset | Local raw file | Source |
| --- | --- | --- |
| Consumer Price Index, all-items | `data/raw/statcan_18100004_cpi.zip` | Statistics Canada Table 18-10-0004-01 |
| Labour force characteristics, unemployment rate | `data/raw/statcan_14100287_labour_force.zip` | Statistics Canada Table 14-10-0287-01 |
| New housing price index, Canada and Toronto | `data/raw/statcan_18100205_new_housing_price_index.zip` | Statistics Canada Table 18-10-0205-01 |
| CMHC conventional mortgage lending rate, 5-year term | `data/raw/statcan_34100145_cmhc_5yr_mortgage_rate.zip` | Statistics Canada Table 34-10-0145-01 |
| Median after-tax income | `data/raw/statcan_11100190_income.zip` | Statistics Canada Table 11-10-0190-01 |
| Bank of Canada policy rate | `data/raw/bank_of_canada_v39079_policy_rate.csv` | Bank of Canada Valet API series `V39079` |

## First Processed Dataset

Raw downloads are cached in `data/raw`. Running `scripts/data_collection/download_data.py` again uses existing raw files by default; running it with `--force` refreshes all sources from the official websites.

The initial merged dataset is:

`data/processed/canadian_housing_macro_master.csv`

The pandas cleaning script also writes:

`data/processed/data_quality_report.txt`

Each row is a month, starting in `1981-01`, when the new housing price index begins.
The first version includes:

- CPI all-items index and year-over-year inflation
- Canada unemployment rate
- Canada and Toronto new housing price indexes
- Canada and Toronto new housing price index year-over-year growth
- CMHC 5-year conventional mortgage lending rate
- Bank of Canada policy rate, monthly average and month-end value
- Annual median after-tax income, using the latest available reference year

Income is annual and usually published with a delay, so the monthly master file carries the latest available income value and keeps `income_reference_year` to make that limitation explicit.
