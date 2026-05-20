local_cache_dir <- file.path(tempdir(), "canadian-housing-risk-monitor-r-cache")
dir.create(local_cache_dir, recursive = TRUE, showWarnings = FALSE)
Sys.setenv(R_USER_CACHE_DIR = local_cache_dir, XDG_CACHE_HOME = local_cache_dir)

library(shiny)
library(bslib)

candidate_data_paths <- unique(normalizePath(
  c(
    file.path(getwd(), "data", "housing_risk_indicators.csv"),
    file.path(getwd(), "data", "processed", "housing_risk_indicators.csv"),
    file.path(getwd(), "..", "data", "processed", "housing_risk_indicators.csv")
  ),
  mustWork = FALSE
))
data_path <- candidate_data_paths[file.exists(candidate_data_paths)][1]
if (is.na(data_path)) {
  stop(
    paste(
      "Could not find housing_risk_indicators.csv. Checked:",
      paste(candidate_data_paths, collapse = ", ")
    )
  )
}

risk_data <- read.csv(data_path, stringsAsFactors = FALSE)
risk_data$date <- as.Date(risk_data$date)
risk_data <- risk_data[order(risk_data$date), ]
latest_row <- risk_data[which.max(risk_data$date), ]
data_range_label <- paste0(min(risk_data$month), " to ", max(risk_data$month))

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

market_context <- function(row) {
  paste(
    "As of", row$month,
    "the Canada home-price proxy is", currency(row$proxy_home_price_canada_cad),
    "and the CMHC 5-year conventional mortgage rate is",
    paste0(percent(row$cmhc_5yr_conventional_mortgage_rate_percent, 2), "."),
    "The implied monthly payment is", currency(row$monthly_mortgage_payment_canada_cad),
    "or", paste0(percent(row$payment_to_income_percent), " of monthly after-tax income,"),
    "which places the baseline affordability proxy in", paste0(row$risk_level, ".")
  )
}

shock_context <- function(row) {
  paste(
    "Under a +2 percentage point rate shock, the payment-to-income ratio rises to",
    paste0(percent(row$payment_to_income_plus_2_0pp_percent), ","),
    "with the risk classification at", paste0(row$risk_level_plus_2_0pp, "."),
    "This calculator is a rule-based affordability measure, not a loan approval or price forecast model."
  )
}

historical_context <- function(df, row) {
  highest <- df[which.max(df$payment_to_income_percent), ]
  lowest <- df[which.min(df$payment_to_income_percent), ]
  paste(
    "Across the historical proxy series, the highest baseline burden is",
    percent(highest$payment_to_income_percent), "in", paste0(highest$month, ","),
    "while the lowest is", percent(lowest$payment_to_income_percent), "in", paste0(lowest$month, "."),
    "The latest complete month is", row$month,
    "at", paste0(percent(row$payment_to_income_percent), ".")
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

status_pill <- function(label, value, class = "") {
  div(
    class = paste("status-pill", class),
    span(label),
    strong(value)
  )
}

plot_line <- function(df, columns, labels, colors, y_label, main) {
  y_values <- unlist(df[columns], use.names = FALSE)
  y_limits <- range(y_values[is.finite(y_values)], na.rm = TRUE)
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))
  par(
    bg = "#ffffff",
    mar = c(4.2, 4.4, 3.2, 1.2),
    family = "sans"
  )
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
    cex.axis = 0.85,
    col.axis = "#5b6778",
    col.lab = "#4b5565",
    col.main = "#172033"
  )
  grid(col = "#e8eef5", lty = 1)
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
    primary = "#285f7a"
  ),
  header = tags$head(
    tags$style(HTML("
      :root {
        --ink: #172033;
        --muted: #5b6778;
        --line: #d9e3ee;
        --panel: #ffffff;
        --page: #f3f7fb;
        --brand: #285f7a;
        --brand-dark: #19364c;
        --accent: #2f9f8f;
        --warning: #b7791f;
        --danger: #b42318;
      }
      body {
        background:
          radial-gradient(circle at top left, rgba(47, 159, 143, 0.12), transparent 28rem),
          linear-gradient(180deg, #eef5fa 0, var(--page) 18rem, #f7f9fc 100%);
        color: var(--ink);
        font-family: Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      }
      .navbar {
        background: linear-gradient(90deg, #19364c 0%, #285f7a 58%, #2f9f8f 100%) !important;
        border-bottom: 1px solid rgba(255,255,255,0.18);
        box-shadow: 0 10px 28px rgba(25, 42, 62, 0.18);
      }
      .navbar-brand, .navbar .nav-link {
        color: rgba(255,255,255,0.92) !important;
      }
      .navbar .nav-link.active {
        color: #ffffff !important;
        font-weight: 800;
      }
      .page-wrap {
        max-width: 1320px;
        margin: 0 auto;
        padding: 26px 22px 42px;
      }
      .section-title {
        display: flex;
        justify-content: space-between;
        gap: 16px;
        align-items: flex-end;
        margin: 6px 0 18px;
      }
      .section-title h2 {
        font-size: 1.7rem;
        margin: 0;
        letter-spacing: 0;
        font-weight: 850;
      }
      .section-title p {
        margin: 6px 0 0;
        color: var(--muted);
        max-width: 760px;
        font-size: 1.02rem;
      }
      .metric-grid {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        gap: 14px;
        margin-bottom: 18px;
      }
      .metric-card, .panel {
        background: rgba(255, 255, 255, 0.96);
        border: 1px solid var(--line);
        border-radius: 10px;
        box-shadow: 0 14px 34px rgba(31, 44, 60, 0.08);
      }
      .metric-card {
        padding: 18px 18px 16px;
        min-height: 124px;
        position: relative;
        overflow: hidden;
      }
      .metric-card::before {
        content: '';
        position: absolute;
        left: 0;
        top: 0;
        bottom: 0;
        width: 4px;
        background: var(--accent);
      }
      .metric-label {
        display: block;
        color: var(--muted);
        font-size: 0.82rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.04em;
      }
      .metric-value {
        font-size: 1.75rem;
        font-weight: 800;
        margin-top: 8px;
        line-height: 1.1;
      }
      .metric-caption {
        color: var(--muted);
        font-size: 0.88rem;
        margin-top: 8px;
      }
      .risk-low .metric-value, .risk-low-text { color: #1b7f5a; }
      .risk-medium .metric-value, .risk-medium-text { color: var(--warning); }
      .risk-high .metric-value, .risk-high-text { color: var(--danger); }
      .risk-high::before { background: var(--danger); }
      .panel {
        padding: 20px;
        margin-bottom: 16px;
      }
      .chart-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 16px;
      }
      .calculator-layout {
        display: grid;
        grid-template-columns: 360px minmax(0, 1fr);
        gap: 16px;
        align-items: start;
      }
      .form-panel .form-group {
        margin-bottom: 14px;
      }
      .result-band {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 14px;
        margin-bottom: 16px;
      }
      .table-wrap {
        overflow-x: auto;
      }
      table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
      }
      table td, table th {
        vertical-align: middle;
        padding: 11px 12px !important;
        border-color: #e3eaf2 !important;
      }
      table td:last-child, table th:last-child {
        white-space: nowrap;
      }
      table th {
        color: #243145;
        font-weight: 800;
        background: #f8fbfe;
      }
      .table {
        margin-bottom: 0;
      }
      .note {
        color: var(--muted);
        font-size: 0.9rem;
        margin-top: 8px;
      }
      .insight-panel {
        border-left: 5px solid var(--brand);
        background: linear-gradient(90deg, rgba(40, 95, 122, 0.06), rgba(255, 255, 255, 0.98) 42%);
      }
      .insight-panel h3 {
        font-size: 1.05rem;
        margin: 0 0 10px;
        font-weight: 850;
      }
      .insight-panel p {
        color: #425066;
        margin: 0 0 8px;
        line-height: 1.55;
      }
      .status-strip {
        display: flex;
        gap: 10px;
        flex-wrap: wrap;
        margin-bottom: 18px;
      }
      .status-pill {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 8px 11px;
        border-radius: 999px;
        background: rgba(255,255,255,0.78);
        border: 1px solid var(--line);
        color: var(--muted);
        font-size: 0.86rem;
        box-shadow: 0 8px 20px rgba(31, 44, 60, 0.05);
      }
      .status-pill strong {
        color: var(--ink);
      }
      .status-pill.risk-high strong {
        color: var(--danger);
      }
      .method-list {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 10px;
        margin-top: 10px;
      }
      .method-list div {
        background: #f8fbfe;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        padding: 12px 14px;
        color: #425066;
        font-size: 0.92rem;
      }
      .form-control, .selectize-input {
        border-color: #d6e1eb;
        border-radius: 8px;
      }
      .irs--shiny .irs-bar,
      .irs--shiny .irs-single {
        background: var(--brand);
        border-color: var(--brand);
      }
      .irs--shiny .irs-handle {
        border-color: var(--brand);
      }
      .shiny-plot-output img {
        width: 100%;
      }
      @media (max-width: 980px) {
        .metric-grid, .chart-grid, .calculator-layout, .result-band, .method-list {
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
        class = "status-strip",
        status_pill("Data range", data_range_label),
        status_pill("Latest month", latest_row$month),
        status_pill("Current risk", latest_row$risk_level, risk_class(latest_row$risk_level))
      ),
      div(
        class = "metric-grid",
        metric_card("Proxy Canada Home Price", currency(latest_row$proxy_home_price_canada_cad), "Indexed to Dec. 2016 = 100"),
        metric_card("5-Year Mortgage Rate", percent(latest_row$cmhc_5yr_conventional_mortgage_rate_percent, 2), "CMHC conventional rate"),
        metric_card("Payment-to-Income", percent(latest_row$payment_to_income_percent), "Baseline monthly burden"),
        metric_card("Risk Level", latest_row$risk_level, "+2pp scenario remains visible in Historical Risk", risk_class(latest_row$risk_level))
      ),
      div(
        class = "panel insight-panel",
        h3("Automated Interpretation"),
        p(market_context(latest_row)),
        p(shock_context(latest_row)),
        p(historical_context(risk_data, latest_row))
      ),
      div(
        class = "chart-grid",
        div(class = "panel", plotOutput("price_plot", height = 320)),
        div(class = "panel", plotOutput("rate_plot", height = 320)),
        div(class = "panel", plotOutput("macro_plot", height = 320)),
        div(class = "panel", plotOutput("burden_plot", height = 320))
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
            div(class = "table-wrap", tableOutput("shock_table")),
            uiOutput("calc_interpretation"),
            div(class = "note", "Risk bands use monthly mortgage payment divided by monthly after-tax income: Low < 30%, Medium 30% to < 40%, High >= 40%.")
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
          p("The historical series shows how the project's affordability proxy changes when rates and prices move through time.")
        ),
        div(class = "note", paste("Full history:", data_range_label))
      ),
      div(
        class = "metric-grid",
        uiOutput("highest_burden_card"),
        uiOutput("lowest_burden_card"),
        uiOutput("latest_shock_card"),
        uiOutput("latest_price_income_card")
      ),
      div(class = "panel", plotOutput("historical_risk_plot", height = 390)),
      div(
        class = "panel insight-panel",
        h3("Historical Reading"),
        p(historical_context(risk_data, latest_row)),
        p("The historical risk proxy combines housing price index movement, mortgage rates, and income data into a comparable monthly burden series. CPI, unemployment, and policy rates provide macro context rather than directly determining the household risk score.")
      ),
      div(
        class = "panel",
        h4("Latest 8 Complete Months"),
        div(class = "note", paste("Full dashboard-ready history runs from", data_range_label, ". Use the Data tab to inspect earlier records.")),
        div(class = "table-wrap", tableOutput("recent_table"))
      )
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
      div(
        class = "panel",
        h4("Method Notes"),
        div(
          class = "method-list",
          div("Monthly payment uses the standard fixed-rate mortgage amortization formula."),
          div("Historical home prices are index-based proxies, not observed transaction prices."),
          div("Risk levels are rule-based affordability bands, not bank underwriting decisions.")
        ),
        br(),
        div(
          class = "calculator-layout",
          div(
            dateRangeInput(
              "history_dates",
              "Month range",
              start = min(risk_data$date),
              end = max(risk_data$date),
              min = min(risk_data$date),
              max = max(risk_data$date),
              format = "yyyy-mm"
            ),
            selectInput(
              "risk_filter",
              "Risk level",
              choices = c("All", sort(unique(risk_data$risk_level))),
              selected = "All"
            )
          )
        ),
        uiOutput("data_filter_summary"),
        div(class = "table-wrap", tableOutput("data_preview")),
        div(
          class = "note",
          paste(
            "Full dashboard-ready history:",
            paste0(data_range_label, "."),
            "The current proxy risk classification is High Risk for all months because the lowest historical payment-to-income ratio is still above the 40% threshold."
          )
        )
      )
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

  output$calc_interpretation <- renderUI({
    value <- calc()
    plus_two_rate <- input$interest_rate + 2
    plus_two_payment <- monthly_payment(value$principal, plus_two_rate, input$amortization)
    plus_two_ratio <- plus_two_payment / value$monthly_income * 100
    div(
      class = "note",
      paste(
        "For the current inputs, the baseline monthly payment is",
        paste0(currency(value$payment), ","),
        "or", paste0(percent(value$ratio), " of monthly after-tax income."),
        "At a +2pp rate shock, the payment rises to",
        paste0(currency(plus_two_payment), ","),
        "or", paste0(percent(plus_two_ratio), ".")
      )
    )
  })

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

  filtered_history <- reactive({
    df <- risk_data
    if (!is.null(input$history_dates) && all(!is.na(input$history_dates))) {
      df <- df[df$date >= input$history_dates[1] & df$date <= input$history_dates[2], ]
    }
    if (!is.null(input$risk_filter) && input$risk_filter != "All") {
      df <- df[df$risk_level == input$risk_filter, ]
    }
    df
  })

  output$data_filter_summary <- renderUI({
    df <- filtered_history()
    if (nrow(df) == 0) {
      return(div(class = "note", "No records match the selected month range."))
    }
    div(
      class = "note",
      paste(
        "Showing",
        nrow(df),
        "monthly records from",
        min(df$month),
        "to",
        paste0(max(df$month), ".")
      )
    )
  })

  output$data_preview <- renderTable({
    preview <- filtered_history()
    if (nrow(preview) == 0) {
      return(data.frame(
        Message = paste(
          "No records match the selected filters.",
          "In the current proxy model, the full historical series may not contain every risk level."
        ),
        check.names = FALSE
      ))
    }
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
