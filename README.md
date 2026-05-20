# Canadian-Housing-Risk-Monitor
Canadian Housing Risk Monitor is an interactive analytics platform that uses Canadian housing and economic data to analyze mortgage affordability, housing market trends, and interest-rate risk through statistical modelling, scenario simulation, and data visualization.

## Live Demo
**Interactive dashboard:** [Canadian Housing Risk Monitor](https://ginoli.shinyapps.io/canadian-housing-risk-monitor/)

## Dashboard Features

- Market overview with housing price indexes, mortgage rates, policy rates, CPI inflation, unemployment, and affordability pressure
- Mortgage affordability calculator with custom house price, down payment, income, interest rate, and amortization inputs
- Interest-rate shock scenarios for -0.5pp, +0.5pp, +1.0pp, and +2.0pp
- Historical market risk proxy with highest, lowest, latest, and recent-month affordability readings
- Data page with month-range and risk-level filters for reviewing previous records
- Automated interpretation text that explains the latest risk reading and scenario impact

## Current Status

The project has a reproducible data foundation, first analysis layer, and working Shiny dashboard MVP. Official data download scripts, cleaned master data, housing affordability risk indicators, EDA figures, and interactive dashboard views have been created.

## First Data Pipeline

Install Python dependencies with:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
```

Run the first-pass data pipeline with:

```bash
.venv/bin/python scripts/data_collection/download_data.py
.venv/bin/python scripts/data_cleaning/build_master_dataset.py
```

By default, `download_data.py` reuses files that already exist in `data/raw`, so normal runs are faster and do not repeatedly hit the official websites. To force a fresh download, run:

```bash
.venv/bin/python scripts/data_collection/download_data.py --force
```

The main analysis-ready file is:

```text
data/processed/canadian_housing_macro_master.csv
```

The data cleaning pipeline uses pandas and also writes a quality report to:

```text
data/processed/data_quality_report.txt
```

It currently contains monthly Canada housing and macroeconomic indicators from `1981-01` onward, including:

- CPI and year-over-year inflation
- Canada unemployment rate
- Canada and Toronto new housing price indexes
- CMHC 5-year conventional mortgage lending rate
- Bank of Canada policy rate
- Annual median after-tax income with reference year

## First Analysis Layer

Build affordability risk indicators and first-pass EDA figures with:

```bash
.venv/bin/python scripts/analysis/build_risk_indicators.py
```

This writes:

```text
data/processed/housing_risk_indicators.csv
data/processed/housing_risk_analysis_summary.txt
outputs/figures/housing_price_index_canada_toronto.png
outputs/figures/interest_rates.png
outputs/figures/inflation_unemployment.png
outputs/figures/payment_to_income_risk_proxy.png
```

The first-pass risk calculation uses a Canada home-price proxy indexed to a baseline home price, a 20% down payment, a 25-year amortization, and CMHC 5-year conventional mortgage rates. Risk bands are based on monthly mortgage payment divided by monthly after-tax income:

- Low Risk: below 30%
- Medium Risk: 30% to 40%
- High Risk: above 40%

See `docs/methodology.md` for formulas, assumptions, and limitations.

## Run the Dashboard

Run the first Shiny dashboard locally with:

```bash
Rscript -e "shiny::runApp('app', host='127.0.0.1', port=3838, launch.browser=FALSE)"
```

Then open:

```text
http://127.0.0.1:3838
```

The app includes an overview of historical indicators, a mortgage stress calculator, historical affordability risk views, and a preview of the analysis dataset.

## Project Outputs

```text
data/processed/canadian_housing_macro_master.csv
data/processed/housing_risk_indicators.csv
data/processed/housing_risk_analysis_summary.txt
outputs/figures/
app/app.R
```

## Method Summary

The monthly mortgage payment uses the standard fixed-rate amortization formula. Historical affordability pressure is measured as monthly mortgage payment divided by monthly after-tax income. The historical home price series is a proxy based on the new housing price index and a baseline home price assumption; it is not an observed average resale price.

The risk levels are transparent rule-based bands, not bank underwriting decisions:

- Low Risk: payment-to-income below 30%
- Medium Risk: payment-to-income from 30% to 40%
- High Risk: payment-to-income above 40%

## Current Limitations

The current MVP does not yet include property tax, condo fees, insurance, other debts, credit score, mortgage insurance premiums, official stress-test qualification rules, regional resale home prices, or statistical forecasting. It should be read as an affordability scenario and monitoring tool.

See `docs/data_sources.md` for source details, `docs/methodology.md` for formulas and assumptions, and `docs/project_structure.md` for the folder layout.
