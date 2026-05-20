# Methodology

This project uses a rule-based affordability framework to monitor Canadian housing and interest-rate risk. The current version is designed for transparent analysis and dashboard communication, not bank underwriting or house-price forecasting.

## Data Flow

```text
Official source files
        |
data/processed/canadian_housing_macro_master.csv
        |
data/processed/housing_risk_indicators.csv
        |
R Shiny dashboard
```

The dashboard reads `housing_risk_indicators.csv`, which preserves key macro variables and adds affordability indicators.

## Mortgage Payment Formula

The monthly mortgage payment uses the standard fixed-rate amortization formula:

```text
monthly payment = P * r * (1 + r)^n / ((1 + r)^n - 1)
```

Where:

- `P` is mortgage principal
- `r` is monthly interest rate, calculated as annual rate / 100 / 12
- `n` is total number of monthly payments, calculated as amortization years * 12

If the interest rate is zero, the payment is:

```text
monthly payment = P / n
```

## Mortgage Principal

```text
mortgage principal = house price * (1 - down payment percent)
```

The first-pass historical analysis assumes:

- 20% down payment
- 25-year amortization
- CMHC 5-year conventional mortgage rate

The Shiny calculator lets users change house price, down payment, income, rate, and amortization.

## Payment-to-Income Ratio

```text
payment-to-income ratio = monthly mortgage payment / monthly after-tax income * 100
```

Where:

```text
monthly after-tax income = annual after-tax income / 12
```

## Risk Classification

The project keeps two risk views.

The absolute affordability bands are:

- Low Risk: payment-to-income below 30%
- Medium Risk: payment-to-income from 30% to below 40%
- High Risk: payment-to-income at 40% and above

These thresholds are transparent portfolio assumptions. They are not official Canadian mortgage qualification rules.

The dashboard also calculates relative historical pressure bands. These compare each month with the project's own historical payment-to-income series:

- Low Relative Pressure: bottom third of the historical series
- Medium Relative Pressure: middle third of the historical series
- High Relative Pressure: top third of the historical series

Relative pressure is useful because the current proxy assumptions put every historical month above the absolute 40% high-risk threshold. It should be read as a within-series comparison, not as a claim that low relative pressure is objectively affordable.

## Rate Shock Scenarios

The dashboard recalculates monthly payment and payment-to-income under four interest-rate scenarios:

- -0.5 percentage point
- +0.5 percentage point
- +1.0 percentage point
- +2.0 percentage points

For each scenario:

```text
scenario rate = current rate + rate shock
scenario payment change = scenario monthly payment - baseline monthly payment
```

## Historical Home Price Proxy

The historical analysis uses a home-price proxy based on the new housing price index:

```text
proxy home price = new housing price index / 100 * 700,000
```

This makes the historical affordability series comparable through time. It is not an observed average transaction price.

## Macro Variables

The dashboard-ready dataset includes:

- CPI inflation
- unemployment rate
- CMHC 5-year mortgage rate
- Bank of Canada policy rate
- Canada and Toronto new housing price indexes
- annual median after-tax income

CPI, unemployment, and policy rates provide macro context in the dashboard. They do not currently enter the household calculator's risk score directly.

## Current Limitations

The model does not yet include:

- property tax
- condo fees
- home insurance
- utilities
- other household debt
- credit score or borrower qualification rules
- mortgage insurance premiums
- official stress-test qualifying rate
- regional resale home prices
- statistical forecasting or machine-learning prediction

The current version should be interpreted as an affordability risk monitor and scenario tool.
