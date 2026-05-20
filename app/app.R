local_cache_dir <- file.path(tempdir(), "canadian-housing-risk-monitor-r-cache")
dir.create(local_cache_dir, recursive = TRUE, showWarnings = FALSE)
Sys.setenv(R_USER_CACHE_DIR = local_cache_dir, XDG_CACHE_HOME = local_cache_dir)

library(shiny)
library(bslib)

candidate_roots <- unique(normalizePath(c(getwd(), file.path(getwd(), "..")), mustWork = FALSE))
project_root <- candidate_roots[
  file.exists(file.path(candidate_roots, "data", "processed", "housing_risk_indicators.csv"))
][1]
if (is.na(project_root)) {
  stop("Could not find data/processed/housing_risk_indicators.csv from the current working directory.")
}

data_path <- file.path(project_root, "data", "processed", "housing_risk_indicators.csv")
risk_data <- read.csv(data_path, stringsAsFactors = FALSE)
risk_data$date <- as.Date(risk_data$date)
risk_data <- risk_data[order(risk_data$date), ]
latest_row <- risk_data[which.max(risk_data$date), ]

currency <- function(x) {
  sign <- ifelse(x < 0, "-$", "$")
  paste0(sign, format(abs(round(x, 0)), big.mark = ",", scientific = FALSE))
}

percent <- function(x, digits = 1) {
  paste0(format(round(x, digits), nsmall = digits, scientific = FALSE), "%")
}

monthly_payment <- function(principal, annual_rate_percent, amortization_years) {
  monthly_rate <- annual_rate_percent / 100 / 12
  n_payments <- amortization_years * 12
  if (monthly_rate == 0) {
    return(principal / n_payments)
  }
  principal * monthly_rate * (1 + monthly_rate)^n_payments /
    ((1 + monthly_rate)^n_payments - 1)
}

risk_level <- function(payment_to_income_percent) {
  if (is.na(payment_to_income_percent)) {
    return("Unknown")
  }
  if (payment_to_income_percent < 30) {
    "Low Risk"
  } else if (payment_to_income_percent < 40) {
    "Medium Risk"
  } else {
    "High Risk"
  }
}

risk_class <- function(level) {
  switch(
    level,
    "Low Risk" = "risk-low",
    "Medium Risk" = "risk-medium",
    "High Risk" = "risk-high",
    "risk-unknown"
  )
}

metric_card <- function(label, value, caption = NULL, class = "") {
  div(
    class = paste("metric-card", class),
    span(class = "metric-label", label),
    div(class = "metric-value", value),
    if (!is.null(caption)) div(class = "metric-caption", caption)
  )
}

plot_line <- function(df, columns, labels, colors, y_label, main) {
  y_values <- unlist(df[columns], use.names = FALSE)
  y_limits <- range(y_values[is.finite(y_values)], na.rm = TRUE)
  plot(
    df$date,
    df[[columns[1]]],
    type = "l",
    lwd = 2.6,
    col = colors[1],
    ylim = y_limits,
    xlab = "",
    ylab = y_label,
    main = main,
    las = 1,
    bty = "n",
    cex.main = 1.05,
    cex.lab = 0.9,
    cex.axis = 0.85
  )
  grid(col = "#e7edf3", lty = 1)
  for (i in seq_along(columns)) {
    lines(df$date, df[[columns[i]]], lwd = 2.6, col = colors[i])
  }
  legend(
    "topleft",
    legend = labels,
    col = colors,
    lwd = 2.6,
    bty = "n",
    cex = 0.86
  )
}

ui <- page_navbar(
  title = "Canadian Housing Risk Monitor",
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#22577a"
  ),
  header = tags$head(
    tags$style(HTML("
      body {
        background: #f6f8fb;
        color: #1d2733;
        font-family: Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      }
      .navbar {
        border-bottom: 1px solid #dce4ed;
        box-shadow: 0 1px 8px rgba(25, 42, 62, 0.05);
      }
      .page-wrap {
        max-width: 1280px;
        margin: 0 auto;
        padding: 22px 18px 36px;
      }
      .section-title {
        display: flex;
        justify-content: space-between;
        gap: 16px;
        align-items: flex-end;
        margin: 4px 0 18px;
      }
      .section-title h2 {
        font-size: 1.45rem;
        margin: 0;
        letter-spacing: 0;
      }
      .section-title p {
        margin: 4px 0 0;
        color: #64748b;
        max-width: 760px;
      }
      .metric-grid {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        gap: 12px;
        margin-bottom: 16px;
      }
      .metric-card, .panel {
        background: #ffffff;
        border: 1px solid #dce4ed;
        border-radius: 8px;
        box-shadow: 0 6px 18px rgba(31, 44, 60, 0.05);
      }
      .metric-card {
        padding: 16px;
        min-height: 118px;
      }
      .metric-label {
        display: block;
        color: #64748b;
        font-size: 0.82rem;
        font-weight: 700;
        text-transform: uppercase;
      }
      .metric-value {
        font-size: 1.55rem;
        font-weight: 800;
        margin-top: 8px;
        line-height: 1.1;
      }
      .metric-caption {
        color: #64748b;
        font-size: 0.88rem;
        margin-top: 8px;
      }
      .risk-low .metric-value, .risk-low-text { color: #1b7f5a; }
      .risk-medium .metric-value, .risk-medium-text { color: #9a6a00; }
      .risk-high .metric-value, .risk-high-text { color: #b42318; }
      .panel {
        padding: 18px;
        margin-bottom: 14px;
      }
      .chart-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 14px;
      }
      .calculator-layout {
        display: grid;
        grid-template-columns: 360px minmax(0, 1fr);
        gap: 14px;
        align-items: start;
      }
      .form-panel .form-group {
        margin-bottom: 14px;
      }
      .result-band {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 12px;
        margin-bottom: 14px;
      }
      table {
        width: 100%;
      }
      table td, table th {
        vertical-align: middle;
      }
      table td:last-child, table th:last-child {
        white-space: nowrap;
      }
      .table {
        margin-bottom: 0;
      }
      .note {
        color: #64748b;
        font-size: 0.9rem;
        margin-top: 8px;
      }
      @media (max-width: 980px) {
        .metric-grid, .chart-grid, .calculator-layout, .result-band {
          grid-template-columns: 1fr;
        }
        .section-title {
          flex-direction: column;
          align-items: flex-start;
        }
      }
    "))
  ),
  nav_panel(
    "Overview",
    div(
      class = "page-wrap",
      div(
        class = "section-title",
        div(
          h2("Market and Affordability Snapshot"),
          p("A first-pass view of housing price pressure, mortgage rates, macro risk, and payment burden using the processed project dataset.")
        ),
        div(class = "note", paste("Latest complete month:", latest_row$month))
      ),
      div(
        class = "metric-grid",
        metric_card("Proxy Canada Home Price", currency(latest_row$proxy_home_price_canada_cad), "Indexed to Dec. 2016 = 100"),
        metric_card("5-Year Mortgage Rate", percent(latest_row$cmhc_5yr_conventional_mortgage_rate_percent, 2), "CMHC conventional rate"),
        metric_card("Payment-to-Income", percent(latest_row$payment_to_income_percent), "Baseline monthly burden"),
        metric_card("Risk Level", latest_row$risk_level, "+2pp scenario remains visible in Historical Risk", risk_class(latest_row$risk_level))
      ),
      div(
        class = "chart-grid",
        div(class = "panel", plotOutput("price_plot", height = 310)),
        div(class = "panel", plotOutput("rate_plot", height = 310)),
        div(class = "panel", plotOutput("macro_plot", height = 310)),
        div(class = "panel", plotOutput("burden_plot", height = 310))
      )
    )
  ),
  nav_panel(
    "Mortgage Stress Calculator",
    div(
      class = "page-wrap",
      div(
        class = "section-title",
        div(
          h2("Mortgage Stress Calculator"),
          p("Change the borrower assumptions and compare baseline payments with common interest-rate shocks.")
        )
      ),
      div(
        class = "calculator-layout",
        div(
          class = "panel form-panel",
          numericInput("house_price", "House price", value = 850000, min = 50000, step = 25000),
          sliderInput("down_payment", "Down payment (%)", min = 5, max = 50, value = 20, step = 1),
          numericInput("annual_income", "Annual after-tax income", value = 75500, min = 10000, step = 2500),
          sliderInput("interest_rate", "Interest rate (%)", min = 0, max = 12, value = 5.13, step = 0.05),
          sliderInput("amortization", "Amortization (years)", min = 5, max = 30, value = 25, step = 1)
        ),
        div(
          div(
            class = "result-band",
            uiOutput("calc_payment_card"),
            uiOutput("calc_ratio_card"),
            uiOutput("calc_risk_card")
          ),
          div(
            class = "panel",
            h4("Rate Shock Scenarios"),
            tableOutput("shock_table"),
            div(class = "note", "Risk bands use monthly mortgage payment divided by monthly after-tax income: Low < 30%, Medium 30-40%, High > 40%.")
          )
        )
      )
    )
  ),
  nav_panel(
    "Historical Risk",
    div(
      class = "page-wrap",
      div(
        class = "section-title",
        div(
          h2("Historical Risk Monitor"),
          p("The historical series shows how the project’s affordability proxy changes when rates and prices move through time.")
        )
      ),
      div(
        class = "metric-grid",
        uiOutput("highest_burden_card"),
        uiOutput("lowest_burden_card"),
        uiOutput("latest_shock_card"),
        uiOutput("latest_price_income_card")
      ),
      div(class = "panel", plotOutput("historical_risk_plot", height = 390)),
      div(class = "panel", h4("Recent Months"), tableOutput("recent_table"))
    )
  ),
  nav_panel(
    "Data",
    div(
      class = "page-wrap",
      div(
        class = "section-title",
        div(
          h2("Analysis Dataset"),
          p("This table previews the processed indicators that power the dashboard.")
        )
      ),
      div(class = "panel", tableOutput("data_preview"))
    )
  )
)

server <- function(input, output, session) {
  output$price_plot <- renderPlot({
    plot_line(
      risk_data,
      c("new_housing_price_index_canada_201612_100", "new_housing_price_index_toronto_201612_100"),
      c("Canada", "Toronto"),
      c("#22577a", "#d97706"),
      "Index",
      "New Housing Price Index"
    )
  })

  output$rate_plot <- renderPlot({
    plot_line(
      risk_data,
      c("cmhc_5yr_conventional_mortgage_rate_percent", "boc_policy_rate_monthly_average_percent"),
      c("CMHC 5-year mortgage", "BoC policy rate"),
      c("#22577a", "#b42318"),
      "Percent",
      "Interest Rates"
    )
  })

  output$macro_plot <- renderPlot({
    plot_line(
      risk_data,
      c("cpi_inflation_yoy_percent", "unemployment_rate_percent"),
      c("CPI inflation YoY", "Unemployment"),
      c("#6d5dfc", "#1b7f5a"),
      "Percent",
      "Inflation and Unemployment"
    )
  })

  output$burden_plot <- renderPlot({
    plot_line(
      risk_data,
      c("payment_to_income_percent", "payment_to_income_plus_2_0pp_percent"),
      c("Baseline", "+2pp shock"),
      c("#22577a", "#b42318"),
      "Payment / income (%)",
      "Mortgage Payment Burden"
    )
    abline(h = c(30, 40), col = c("#1b7f5a", "#d97706"), lty = 2)
  })

  calc <- reactive({
    principal <- input$house_price * (1 - input$down_payment / 100)
    payment <- monthly_payment(principal, input$interest_rate, input$amortization)
    monthly_income <- input$annual_income / 12
    ratio <- payment / monthly_income * 100
    level <- risk_level(ratio)
    list(
      principal = principal,
      payment = payment,
      monthly_income = monthly_income,
      ratio = ratio,
      level = level
    )
  })

  output$calc_payment_card <- renderUI({
    value <- calc()
    metric_card("Monthly Payment", currency(value$payment), paste("Mortgage principal:", currency(value$principal)))
  })

  output$calc_ratio_card <- renderUI({
    value <- calc()
    metric_card("Payment-to-Income", percent(value$ratio), paste("Monthly income:", currency(value$monthly_income)))
  })

  output$calc_risk_card <- renderUI({
    value <- calc()
    metric_card("Risk Level", value$level, "Based on payment burden", risk_class(value$level))
  })

  output$shock_table <- renderTable({
    value <- calc()
    shocks <- c(-0.5, 0.5, 1.0, 2.0)
    rates <- pmax(input$interest_rate + shocks, 0)
    payments <- vapply(rates, function(rate) monthly_payment(value$principal, rate, input$amortization), numeric(1))
    ratios <- payments / value$monthly_income * 100
    data.frame(
      Scenario = c("-0.5 percentage point", "+0.5 percentage point", "+1.0 percentage point", "+2.0 percentage points"),
      Rate = percent(rates, 2),
      `Monthly Payment` = currency(payments),
      `Payment Change` = paste0(ifelse(payments - value$payment >= 0, "+", ""), currency(payments - value$payment)),
      `Payment-to-Income` = percent(ratios),
      Risk = vapply(ratios, risk_level, character(1)),
      check.names = FALSE
    )
  }, striped = TRUE, bordered = FALSE, spacing = "s")

  output$highest_burden_card <- renderUI({
    row <- risk_data[which.max(risk_data$payment_to_income_percent), ]
    metric_card("Highest Burden", percent(row$payment_to_income_percent), row$month, "risk-high")
  })

  output$lowest_burden_card <- renderUI({
    row <- risk_data[which.min(risk_data$payment_to_income_percent), ]
    metric_card("Lowest Burden", percent(row$payment_to_income_percent), row$month, "risk-low")
  })

  output$latest_shock_card <- renderUI({
    metric_card("+2pp Shock Burden", percent(latest_row$payment_to_income_plus_2_0pp_percent), latest_row$risk_level_plus_2_0pp, risk_class(latest_row$risk_level_plus_2_0pp))
  })

  output$latest_price_income_card <- renderUI({
    metric_card("Price-to-Income", paste0(round(latest_row$price_to_income_ratio_canada, 1), "x"), "Canada proxy")
  })

  output$historical_risk_plot <- renderPlot({
    plot_line(
      risk_data,
      c("payment_to_income_percent", "payment_to_income_plus_2_0pp_percent"),
      c("Baseline", "+2pp shock"),
      c("#22577a", "#b42318"),
      "Payment / income (%)",
      "Historical Affordability Risk"
    )
    abline(h = c(30, 40), col = c("#1b7f5a", "#d97706"), lty = 2)
    text(min(risk_data$date, na.rm = TRUE), 30, " Low / Medium", pos = 3, cex = 0.8, col = "#1b7f5a")
    text(min(risk_data$date, na.rm = TRUE), 40, " Medium / High", pos = 3, cex = 0.8, col = "#d97706")
  })

  output$recent_table <- renderTable({
    recent <- tail(risk_data, 8)
    data.frame(
      Month = recent$month,
      `Mortgage Rate` = percent(recent$cmhc_5yr_conventional_mortgage_rate_percent, 2),
      `Monthly Payment` = currency(recent$monthly_mortgage_payment_canada_cad),
      `Payment-to-Income` = percent(recent$payment_to_income_percent),
      Risk = recent$risk_level,
      `+2pp Risk` = recent$risk_level_plus_2_0pp,
      check.names = FALSE
    )
  }, striped = TRUE, bordered = FALSE, spacing = "s")

  output$data_preview <- renderTable({
    preview <- tail(risk_data, 12)
    data.frame(
      Month = preview$month,
      `Home Price Proxy` = currency(preview$proxy_home_price_canada_cad),
      `Mortgage Rate` = percent(preview$cmhc_5yr_conventional_mortgage_rate_percent, 2),
      `Monthly Payment` = currency(preview$monthly_mortgage_payment_canada_cad),
      `Payment-to-Income` = percent(preview$payment_to_income_percent),
      `Price-to-Income` = paste0(round(preview$price_to_income_ratio_canada, 1), "x"),
      `Inflation YoY` = percent(preview$cpi_inflation_yoy_percent),
      `Unemployment` = percent(preview$unemployment_rate_percent),
      Risk = preview$risk_level,
      check.names = FALSE
    )
  }, striped = TRUE, bordered = FALSE, spacing = "s")
}

shinyApp(ui, server)
