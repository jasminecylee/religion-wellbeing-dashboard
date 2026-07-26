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
  "Life satisfaction (1-10)" = "life_satisfaction",
  "Happiness (1-4)"          = "happiness",
  "Self-rated health (1-5)"  = "health"
)

countries <- sort(unique(dash$gaps$country))

# ---- UI ----------------------------------------------------------------------

ui <- page_navbar(
  title = "Wellbeing of religious minorities and majorities across countries in the World Values Survey (2017-2022)",
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
    layout_sidebar(
      sidebar = sidebar(
        width = 300,
        selectInput("outcome", "Wellbeing measure",
                    choices = outcome_choices, selected = "life_satisfaction"),
        radioButtons("sort_by", "Order countries by",
                     choices = c("Size of gap" = "gap",
                                 "Majority mean" = "majority",
                                 "Alphabetical" = "alpha"),
                     selected = "gap"),
        sliderInput("top_n", "Number of countries shown",
                    min = 10, max = length(countries),
                    value = min(25, length(countries)), step = 5),
        helpText("Countries are ranked by the size of the minority-majority",
                 "difference. Reduce the number shown for a more readable chart."),
        hr(),
        downloadButton("download_gaps", "Download country gaps (CSV)",
                       class = "btn-sm btn-outline-secondary")
      ),
      
      layout_columns(
        fill = FALSE,
        value_box("Countries", textOutput("vb_countries"), theme = "primary"),
        value_box("Respondents", textOutput("vb_n"), theme = "secondary"),
        value_box("Median gap", textOutput("vb_gap"), theme = "light")
      ),
      
      card(
        card_header("Where are the gaps largest?"),
        plotlyOutput("map", height = "460px"),
        card_footer(
          class = "text-muted small",
          "Blue: minorities report higher average wellbeing than the majority.",
          "Red: minorities report lower average wellbeing.",
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
        value_box("Majority group", textOutput("vb_majority"), theme = "primary"),
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
          plotlyOutput("country_means", height = "380px")
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
      h4("What this dashboard shows"),
      p("Weighted descriptive averages of three wellbeing measures for religious",
        "majority and minority respondents in each country, using the World Values",
        "Survey (Wave 7, 2017-2022). It is an exploratory tool: everything shown is",
        "a group mean or a raw difference between two group means."),
      
      h4("How majority and minority are defined"),
      p("Religious composition is estimated from the survey itself. Within each",
        "country, the weighted share of respondents in each religious group is",
        "calculated, and the group holding more than 50% of the sample is treated",
        "as the religious majority. All other respondents are classified as",
        "religious minorities. Countries with no group above 50%, and countries",
        "where minorities make up less than 1% of the sample, are excluded."),
      
      h4("Weighting"),
      p("All means use the survey's sampling weights. Standard errors use Kish's",
        "effective sample size so that they reflect the weighting rather than the",
        "raw number of rows."),
      
      h4("Caveats"),
      tags$ul(
        tags$li("Differences are descriptive and are not adjusted for age, sex, or",
                "any other characteristic. They should not be read causally."),
        tags$li("Religious minorities are more likely to leave the wellbeing items",
                "blank, so observed differences are likely conservative."),
        tags$li("Defining majority status from sample shares rather than national",
                "religious demography means the country set here differs from",
                "studies using external demographic sources."),
        tags$li("Minority groups are pooled together within each country and are",
                "not directly comparable across countries.")
      ),
      
      h4("Item non-response by group"),
      DTOutput("missing_table"),
      
      h4("Source and code", class = "mt-4"),
      p("Data: World Values Survey Wave 7 (2017-2022), available from",
        a("worldvaluessurvey.org", href = "https://www.worldvaluessurvey.org",
          target = "_blank"), ".",
        "Microdata are not redistributed here; this app reads pre-aggregated",
        "country-level tables produced by the preparation script in the",
        "repository.")
    )
  )
)


