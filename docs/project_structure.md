# Project Structure

```text
data/
  raw/            Official downloaded source files
  processed/      Cleaned analysis-ready CSV files
  external/       Optional third-party/manual datasets
scripts/
  data_collection/  Data download scripts
  data_cleaning/    Data cleaning and merge scripts
  analysis/         Affordability indicators, EDA figures, and modelling helpers
notebooks/        Exploratory analysis notebooks
app/              R Shiny dashboard application
docs/             Project documentation
outputs/
  figures/        Exported charts
  models/         Saved model outputs
```

The first reproducible path is:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python scripts/data_collection/download_data.py
.venv/bin/python scripts/data_cleaning/build_master_dataset.py
.venv/bin/python scripts/analysis/build_risk_indicators.py
```

`download_data.py` uses cached files by default. Add `--force` when you want to refresh all raw files from the official sources.

The first analysis script writes `data/processed/housing_risk_indicators.csv`, a short summary text file, and chart images in `outputs/figures/`.
