# Canadian-Housing-Risk-Monitor
Canadian Housing Risk Monitor is an interactive analytics platform that uses Canadian housing and economic data to analyze mortgage affordability, housing market trends, and interest-rate risk through statistical modelling, scenario simulation, and data visualization.

## Current Status

The project is in the data foundation stage. The first project structure, official data download scripts, and initial cleaned master dataset have been created.

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

See `docs/data_sources.md` for source details and `docs/project_structure.md` for the folder layout.
