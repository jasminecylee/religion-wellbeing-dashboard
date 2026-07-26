# ------------------------------------------------------------------------------
# Religious majority/minority wellbeing across countries
# An interactive dashboard of World Values Survey (2017-2022) descriptives
#
# Data prepared by prepare_dashboard_data.Rmd
# All figures are descriptive; no modelled estimates are shown. This will be updated once the publication is under review.
# ------------------------------------------------------------------------------

library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(ggplot2)
library(plotly)
library(DT)

# ---- Data --------------------------------------------------------------------

dash <- readRDS("data/dashboard_data.rds")

PAL <- list(
  majority = "#04BFAF",
  minority = "#0B2A5B",
  link     = "#C9CED6",
  low      = "#A40000",
  mid      = "#F7F7F7",
  high     = "#0B2A5B"
)

outcome_choices <- c(
  "Life satisfaction (1-10 scale)" = "life_satisfaction",
  "Happiness (1-4 scale)"          = "happiness",
  "Self-rated health (1-5 scale)"  = "health"
)

countries <- sort(unique(dash$gaps$country))

# ---- UI ----------------------------------------------------------------------

ui <- page_navbar(
  title = "Health and wellbeing of religious minorities and majorities across countries",
  theme = bs_theme(
    version = 5,
    bg = "#FFFFFF", fg = "#1B1F24",
    primary = PAL$minority,
    base_font = font_google("Inter"),
    heading_font = font_google("Inter")
  ),
  fillable = FALSE,
  
  # -- Tab 1: cross-country overview -------------------------------------------
  nav_panel(
    "Cross-country overview",
    div(
      class = "pt-3 pb-2 text-muted",
      style = "max-width: 900px; font-size: 0.9rem;",
      "Life satisfaction, happiness, and general health among adults from religious minority and majority groups across countries in the World Values Survey (2017-2022)."
    ),
    layout_sidebar(
      sidebar = sidebar(
        width = 300,
        selectInput("outcome", "Wellbeing measure",
                    choices = outcome_choices, selected = "life_satisfaction"),
        radioButtons("sort_by", "Order countries by",
                     choices = c("Size of minority-majority gap" = "gap",
                                 "Majority mean" = "majority",
                                 "Alphabetical" = "alpha"),
                     selected = "gap"),
        sliderInput("top_n", "Number of countries shown",
                    min = 5, max = length(countries),
                    value = length(countries), step = 1),
        helpText("All countries are shown by default. Reducing the number shows a less cluttered visualisation",
                 "but keeps countries with larger minority-majority gaps."),
        hr(),
        downloadButton("download_gaps", "Download country gaps (CSV)",
                       class = "btn-sm btn-outline-secondary")
      ),
      
      layout_columns(
        fill = FALSE,
        value_box("Countries", textOutput("vb_countries"), theme = "primary"),
        value_box("Respondents", textOutput("vb_n"), theme = "secondary"),
        value_box("Median country gap", textOutput("vb_gap"), theme = "light")
      ),
      
      card(
        card_header("Where are the gaps largest?"),
        plotlyOutput("map", height = "460px"),
        card_footer(
          class = "text-muted small",
          "Blue: minorities report higher average scores than the majority.",
          "Red: minorities report lower average scores than the majority.",
          "Grey: country not in the analytic sample."
        )
      ),
      
      card(
        card_header("Majority and minority averages within each country"),
        uiOutput("dumbbell_ui"),
        card_footer(
          class = "text-muted small",
          "Each line links the weighted mean for the religious majority",
          "to the mean for religious minorities in the same country.",
          "The number on the right is the difference between them."
        )
      )
    )
  ),
  
  # -- Tab 2: country profile ---------------------------------------------------
  nav_panel(
    "Country profile",
    layout_sidebar(
      sidebar = sidebar(
        width = 300,
        selectizeInput(
          "country", "Search for a country",
          choices  = countries,
          selected = countries[1],
          options  = list(placeholder = "Start typing a country name...")
        ),
        helpText("Religious composition is estimated from the weighted",
                 "share of World Values Survey respondents in each group.")
      ),
      
      layout_columns(
        fill = FALSE,
        value_box("Majority group", textOutput("vb_majority"),textOutput("vb_majority_pct"), theme = "primary"),
        value_box("Minority share of sample", textOutput("vb_minshare"), theme = "secondary"),
        value_box("Respondents", textOutput("vb_country_n"), theme = "light")
      ),
      
      layout_columns(
        col_widths = c(6, 6),
        card(
          card_header("Religious composition of the sample"),
          plotlyOutput("composition", height = "380px")
        ),
        card(
          card_header("Wellbeing by religious status"),
          plotlyOutput("country_means", height = "460px"),
          card_footer(
            class = "text-muted small",
            "Horizontal bars show 95% confidence intervals.",
            "Where the two intervals overlap, the difference between groups is imprecise."
          )
        )
        ),
      
      card(
        card_header("Group averages and differences"),
        DTOutput("country_table")
      )
    )
  ),
  
  # -- Tab 3: data and methods --------------------------------------------------
  nav_panel(
    "Data & methods",
    div(
      class = "container-sm py-3",
      style = "max-width: 820px;",
      
      markdown("
#### What this dashboard shows

Weighted descriptive averages of **three health and wellbeing measures for religious
majority and minority respondents in each country, using the World Values Survey
(Wave 7, 2017-2022)**. It is an *exploratory* tool: everything shown is a group mean
or a raw difference between two group means.

#### How majority and minority are defined

Religious composition is estimated from the survey itself. Within each country,
the weighted share of respondents in each religious group is calculated, and the
group holding **more than 50%** of the sample is treated as the religious majority.
All other respondents are classified as religious minorities.

Countries with no group above 50%, and countries where minorities make up less
than 1% of the sample, are excluded.

#### Weighting

All means use the survey's sampling weights. Standard errors use Kish's effective
sample size so that they reflect the weighting rather than the raw number of rows.

#### Caveats

- Differences are descriptive and are not adjusted for age, sex, or any other
  characteristic. **No causal conclusions can be drawn.**
- Religious minorities are more likely to not respond to the happiness item, so
  observed differences are likely conservative.
- Defining majority status from sample shares rather than national religious
  demography means the country set here differs from studies using external
  demographic sources.
- Minority groups are pooled together within each country and are not directly
  comparable across countries.

#### Item non-response by group
      "),
      
      tableOutput("missing_table"),
      
      markdown("
      
#### Source and code

Data: World Values Survey Wave 7 (2017-2022), available from
[worldvaluessurvey.org](https://www.worldvaluessurvey.org).

Microdata are not redistributed here; this app reads pre-aggregated country-level
tables produced by the preparation script in the
[repository](https://github.com/YOUR-USERNAME/YOUR-REPO).
      ")
    )
  )
)

# ---- Server ------------------------------------------------------------------

server <- function(input, output, session) {
  
  # -- Reactive slices ---------------------------------------------------------
  
  gaps_out <- reactive({
    dash$gaps %>% filter(outcome == input$outcome)
  })
  
  gaps_ranked <- reactive({
    df <- gaps_out() %>% slice_min(gap, n = input$top_n, with_ties = FALSE)
    df <- switch(
      input$sort_by,
      gap      = df %>% arrange(desc(gap)),
      majority = df %>% arrange(mean_Majority),
      alpha    = df %>% arrange(desc(country))
    )
    df %>% mutate(country = factor(country, levels = country))
  })
  
  means_ranked <- reactive({
    ord <- levels(gaps_ranked()$country)
    dash$means %>%
      filter(outcome == input$outcome, country %in% ord) %>%
      mutate(country = factor(country, levels = ord))
  })
  
  # -- Value boxes -------------------------------------------------------------
  
  output$vb_countries <- renderText(format(dash$meta$n_countries, big.mark = ","))
  output$vb_n         <- renderText(format(dash$meta$n_respondents, big.mark = ","))
  output$vb_gap       <- renderText(sprintf("%+.2f", median(gaps_out()$gap, na.rm = TRUE)))
  
  # -- Map ---------------------------------------------------------------------
  
  output$map <- renderPlotly({
    df  <- gaps_out() %>% filter(!is.na(iso3c))
    lim <- max(abs(df$gap), na.rm = TRUE)
    
    df <- df %>%
      mutate(hover = paste0(
        "<b>", country, "</b><br>",
        "Majority: ", majority_religion, "<br>",
        "Majority mean: ", sprintf("%.2f", mean_Majority), "<br>",
        "Minority mean: ", sprintf("%.2f", mean_Minority), "<br>",
        "Minority - majority: ", sprintf("%+.2f", gap)
      ))
    
    plot_ly(
      df,
      type       = "choropleth",
      locations  = ~iso3c,
      z          = ~gap,
      text       = ~hover,
      hoverinfo  = "text",
      colorscale = list(c(0, PAL$low), c(0.5, PAL$mid), c(1, PAL$high)),
      zmin       = -lim,
      zmax       =  lim,
      marker     = list(line = list(color = "white", width = 0.4)),
      colorbar   = list(title = list(text = "Difference\n(minority -\nmajority)"),
                        thickness = 12, len = 0.7)
    ) %>%
      layout(
        geo = list(
          projection    = list(type = "robinson"),
          showframe     = FALSE,
          showcoastlines = FALSE,
          showland      = TRUE,
          landcolor     = "#EDEFF2",
          bgcolor       = "rgba(0,0,0,0)"
        ),
        margin        = list(l = 0, r = 0, t = 10, b = 0),
        paper_bgcolor = "rgba(0,0,0,0)"
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # -- Dumbbell ----------------------------------------------------------------
  # Height scales with the number of countries so rows never crowd together.
  
  output$dumbbell_ui <- renderUI({
    plotlyOutput("dumbbell", height = paste0(max(320, 19 * input$top_n + 90), "px"))
  })
  
  output$dumbbell <- renderPlotly({
    pts  <- means_ranked()
    gaps <- gaps_ranked()
    
    rng     <- range(c(pts$mean), na.rm = TRUE)
    padding <- diff(rng) * 0.18
    label_x <- rng[2] + padding * 0.75
    
    p <- ggplot() +
      # faint link showing the size of the difference
      geom_segment(
        data = gaps,
        aes(y = country, yend = country, x = mean_Majority, xend = mean_Minority),
        colour = PAL$link, linewidth = 1.6, lineend = "round"
      ) +
      geom_point(
        data = pts,
        aes(x = mean, y = country, colour = religion_status,
            text = paste0("<b>", country, "</b><br>",
                          religion_status, ": ", sprintf("%.2f", mean),
                          "<br>n = ", format(n, big.mark = ","))),
        size = 2.6
      ) +
      # gap value in its own column on the right
      geom_text(
        data = gaps,
        aes(x = label_x, y = country, label = sprintf("%+.2f", gap)),
        hjust = 0, size = 3.1, colour = "#4A5058"
      ) +
      scale_colour_manual(
        values = c(Majority = PAL$majority, Minority = PAL$minority),
        name = NULL
      ) +
      scale_x_continuous(limits = c(rng[1] - padding * 0.3, label_x + padding)) +
      labs(x = names(outcome_choices)[outcome_choices == input$outcome], y = NULL) +
      theme_minimal(base_size = 12) +
      theme(
        panel.grid.major.y = element_line(colour = "#F2F3F5"),
        panel.grid.minor   = element_blank(),
        axis.text.y        = element_text(size = 10),
        legend.position    = "top"
      )
    
    ggplotly(p, tooltip = "text") %>%
      layout(legend = list(orientation = "h", x = 0, y = 1.04)) %>%
      config(displayModeBar = FALSE)
  })
  
  output$download_gaps <- downloadHandler(
    filename = function() paste0("country_gaps_", input$outcome, ".csv"),
    content  = function(file) readr::write_csv(gaps_out(), file)
  )
  
  # -- Country profile ---------------------------------------------------------
  
  country_comp <- reactive({
    dash$composition %>%
      filter(country == input$country) %>%
      arrange(share)
  })
  
  country_gaps <- reactive({
    dash$gaps %>% filter(country == input$country)
  })
  
  output$vb_majority <- renderText({
    g <- country_gaps()
    if (nrow(g) == 0) return("-")
    g$majority_religion[1]
  })
  
  output$vb_majority_pct <- renderText({
    g <- country_gaps()
    if (nrow(g) == 0) return("")
    sprintf("%.0f%% of the sample", g$majority_share[1])
  })
  
  output$vb_minshare <- renderText({
    g <- country_gaps()
    if (nrow(g) == 0) return("-")
    sprintf("%.1f%%", g$pct_minority[1])
  })
  
  output$vb_country_n <- renderText({
    g <- country_gaps()
    if (nrow(g) == 0) return("-")
    format(g$n_total[1], big.mark = ",")
  })
  
  output$composition <- renderPlotly({
    df <- country_comp() %>%
      mutate(religion = factor(religion, levels = religion))
    
    p <- ggplot(df, aes(x = share, y = religion, fill = status,
                        text = paste0(religion, "<br>",
                                      sprintf("%.1f%%", share),
                                      " of sample<br>n = ", format(n, big.mark = ",")))) +
      geom_col(width = 0.68) +
      scale_fill_manual(values = c(Majority = PAL$majority, Minority = PAL$minority),
                        name = NULL) +
      labs(x = "% of weighted sample", y = NULL) +
      theme_minimal(base_size = 12) +
      theme(panel.grid.major.y = element_blank(),
            panel.grid.minor   = element_blank(),
            legend.position    = "top")
    
    ggplotly(p, tooltip = "text") %>%
      layout(
        legend = list(orientation = "h", x = 0, y = 1.14,
                      xanchor = "left", yanchor = "bottom"),
        margin = list(t = 60)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  output$country_means <- renderPlotly({
    df <- dash$means %>%
      filter(country == input$country) %>%
      mutate(
        measure = factor(
          outcome,
          levels = c("life_satisfaction", "happiness", "health"),
          labels = c("Life satisfaction (1-10)", "Happiness (1-4)", "Self-rated health (1-5)")
        ),
        religion_status = factor(religion_status, levels = c("Minority", "Majority"))
      )
    
    links <- df %>%
      select(measure, religion_status, mean) %>%
      pivot_wider(names_from = religion_status, values_from = mean)
    
    p <- ggplot(df, aes(x = mean, y = religion_status, colour = religion_status)) +
      geom_segment(
        data = links, inherit.aes = FALSE,
        aes(x = Majority, xend = Minority, y = "Majority", yend = "Minority"),
        colour = PAL$link, linewidth = 1.4, lineend = "round"
      ) +
      geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.16, alpha = 0.55) +
      geom_point(
        aes(text = paste0("<b>", religion_status, "</b><br>",
                          "Mean: ", sprintf("%.2f", mean),
                          "<br>95% CI ", sprintf("%.2f", lower), " to ", sprintf("%.2f", upper),
                          "<br>n = ", format(n, big.mark = ","))),
        size = 3.6
      ) +
      facet_wrap(~ measure, ncol = 1, scales = "free_x") +
      scale_colour_manual(values = c(Majority = PAL$majority, Minority = PAL$minority)) +
      labs(x = NULL, y = NULL) +
      theme_minimal(base_size = 12) +
      theme(
        panel.grid.major.y = element_blank(),
        panel.grid.minor   = element_blank(),
        strip.text         = element_text(hjust = 0, face = "bold", size = 10),
        legend.position    = "none"
      )
    
    ggplotly(p, tooltip = "text") %>%
      layout(margin = list(t = 30)) %>%
      config(displayModeBar = FALSE)
  })
  
  output$country_table <- renderDT({
    country_gaps() %>%
      mutate(measure = factor(
        outcome,
        levels = c("life_satisfaction", "happiness", "health"),
        labels = c("Life satisfaction (1-10)", "Happiness (1-4)", "Self-rated health (1-5)")
      )) %>%
      arrange(measure) %>%
      transmute(
        Measure = as.character(measure),
        `Majority mean` = sprintf("%.2f", mean_Majority),
        `Minority mean` = sprintf("%.2f", mean_Minority),
        `Minority - majority (95% CI)` = sprintf("%+.2f (%+.2f to %+.2f)", gap, gap_lower, gap_upper),
        `n (maj / min)` = sprintf("%s / %s",
                                  format(n_Majority, big.mark = ","),
                                  format(n_Minority, big.mark = ","))
      ) %>%
      datatable(
        rownames = FALSE,
        class = "compact stripe hover",
        options = list(
          dom = "t", ordering = FALSE, paging = FALSE,
          columnDefs = list(list(className = "dt-right", targets = 1:4))
        )
      )
  })
  
  output$missing_table <- renderTable({
    dash$missingness %>%
      transmute(
        Group = as.character(religion_status),
        n = format(n, big.mark = ","),
        `Life satisfaction missing (%)` = pct_missing_ls,
        `Happiness missing (%)`         = pct_missing_happy,
        `Health missing (%)`            = pct_missing_health
      )
  }, striped = TRUE, hover = TRUE, digits = 1)
}

shinyApp(ui, server)
