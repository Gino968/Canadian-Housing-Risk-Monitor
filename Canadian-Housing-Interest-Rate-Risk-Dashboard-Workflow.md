# Canadian Housing & Interest Rate Risk Dashboard

## Project Overview

This project will build an interactive analytics dashboard for Canadian housing affordability and interest-rate risk. It combines historical data on Canadian real estate, interest rates, mortgage rates, income, inflation, and unemployment to explain how housing affordability changes under different economic conditions.

The goal is not only to predict housing prices. The platform focuses on risk analytics, affordability stress testing, and economic interpretation:

When interest rates change, how does household mortgage burden change, and which economic factors increase housing market risk?

## Core Platform Functions

### 1. Mortgage Stress Calculator

Users will enter:

- House price
- Down payment percentage
- Annual income
- Loan term
- Current interest rate

The platform will calculate:

- Monthly mortgage payment
- Annual mortgage cost
- Debt-to-income ratio
- Housing affordability risk level

### 2. Interest Rate Scenario Simulation

The dashboard will simulate several rate-change scenarios:

- Interest rate increases by 0.5%
- Interest rate increases by 1%
- Interest rate increases by 2%
- Interest rate decreases by 0.5%

For each scenario, the dashboard will show:

- Change in monthly payment
- Change in household affordability ratio
- Whether the risk level increases or decreases

### 3. Canadian Housing Market Visualization

The platform will visualize historical trends such as:

- Average home prices in Canada and Toronto
- Bank of Canada policy rate
- Mortgage rates
- Household income
- CPI and inflation
- Unemployment rate

### 4. Statistical Modeling and Forecasting

The project will use historical data to analyze:

- The relationship between interest rates and home prices
- The impact of income, unemployment, and inflation on housing risk
- Future trends in home prices or affordability pressure

The modeling process can start with simple regression and later expand to:

- Multiple linear regression
- Time series models
- Random forest or XGBoost models

### 5. Risk Scoring System

The dashboard will generate a risk level:

- Low Risk
- Medium Risk
- High Risk

The score can be based on indicators such as:

- Monthly mortgage payment divided by monthly income
- House price divided by annual income
- Interest-rate stress test result
- Unemployment rate
- Inflation level

## Project Workflow

### Part 1: Data Collection

Collect Canadian housing and macroeconomic data, including:

- Housing price data
- Bank of Canada interest rate data
- Mortgage rate data
- Income data
- CPI and inflation data
- Unemployment rate data

### Part 2: Data Cleaning

Prepare the datasets by:

- Standardizing date formats
- Handling missing values
- Merging data from different sources
- Converting units where needed
- Creating new analytical variables

### Part 3: Exploratory Data Analysis

Perform initial analysis on:

- Housing price trends
- Interest rate trends
- Income trends
- House-price-to-income ratio
- Relationship between interest rates and home prices
- Correlations among economic indicators

### Part 4: Mortgage Calculator

Build a mortgage calculation module that computes:

- Loan amount
- Monthly mortgage payment
- Total interest paid
- Affordability ratio

### Part 5: Scenario Simulation

Build a rate-change simulation module that compares:

- Monthly payment under the current interest rate
- Monthly payment after rate increases or decreases
- Percentage change in monthly payment
- Change in affordability risk level

### Part 6: Statistical Modeling

Develop predictive and explanatory models such as:

- Regression model
- Time series model
- Machine learning model

Possible targets include:

- Future housing price trend
- Affordability stress
- Housing risk score

### Part 7: Interactive Dashboard

Build the final interactive platform using R Shiny with:

- User input panel
- Charts and visualizations
- Risk score output
- Forecasting results
- Interest-rate scenario simulation results

### Part 8: Deployment and Documentation

Complete the portfolio-ready project with:

- GitHub repository
- README documentation
- Deployed Shiny app
- Data source documentation
- Model explanation
- Project methodology notes

## Tools and Technologies

### Programming

- R
- Python

### Python Tools

- pandas: data cleaning, merging, and transformation
- numpy: numerical calculation
- matplotlib: basic data visualization
- statsmodels: regression and time series modeling
- scikit-learn: machine learning models
- xgboost: advanced prediction model, optional later-stage addition

### R Tools

- shiny: interactive web dashboard
- tidyverse: data manipulation
- ggplot2: data visualization
- plotly: interactive charts
- DT: interactive tables
- leaflet: optional map module for later development
- readr / readxl: reading data files

### Version Control and Deployment

- Git
- GitHub
- shinyapps.io
- README.md
- requirements.txt
- renv, optional for managing the R package environment

## Skills Demonstrated

### Data Analytics

- Data collection
- Data cleaning
- Data merging
- Exploratory data analysis
- Indicator construction
- Trend analysis

### Statistics

- Multiple linear regression
- Correlation analysis
- Model interpretation
- Confidence intervals and prediction intervals
- Time series forecasting

### Machine Learning

- Train-test split
- Cross-validation
- Random forest
- Gradient boosting / XGBoost
- Model evaluation

### Economics and Finance

- Interest rate analysis
- Mortgage affordability
- Housing market analysis
- Inflation and unemployment interpretation
- Risk stress testing

### Data Visualization

- Line charts
- Scatter plots
- Heatmaps
- Interactive dashboard
- Risk score visualization

### Software and Portfolio Development

- R Shiny app development
- Python data pipeline
- GitHub project organization
- Deployment
- Technical documentation

## Project Value

- Risk analytics
- Economic interpretation
- Mortgage stress testing
- Interactive dashboard design
- Portfolio-ready software organization


