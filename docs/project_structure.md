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
.venv/bin/python scripts/run_pipeline.py
```

`scripts/run_pipeline.py` uses cached raw files by default through the download script, rebuilds processed data, rebuilds indicators and figures, and copies `housing_risk_indicators.csv` into `app/data/` for the Shiny dashboard. Add `--force-download` when you want to refresh all raw files from the official sources, or `--skip-download` when you want to rebuild from existing raw files only.

The first analysis script writes `data/processed/housing_risk_indicators.csv`, a short summary text file, and chart images in `outputs/figures/`.

Run the Python test suite with:

```bash
.venv/bin/python -m pytest
```

See `docs/methodology.md` for the mortgage formulas, risk thresholds, assumptions, and current limitations.
