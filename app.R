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
library(paletteer)

# ---- Data --------------------------------------------------------------------

dash <- readRDS("data/dashboard_data.rds")

PAL <- list(
  majority = "#04BFAF",   # original teal
  minority = "#0B2A5B",   # original navy
  link     = "#D8D2C6",   # warm grey (was cool #C9CED6)
  low      = "#B5552F",   # muted rust — minorities score lower
  mid      = "#F6F1E7",   # warm cream midpoint
  high     = "#0B2A5B"    # navy — matches minority
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
    bg = "#FBF8F3", fg = "#1B1F24",
    primary = PAL$minority,
    base_font = font_google("Inter"),
    heading_font = font_google("Inter")
  ),
  fillable = FALSE,
  
  # -- Tab 1: cross-country overview -------------------------------------------
  nav_panel(
    "Cross-country overview",
    div(
      class = "pt-3 pb-2 px-3 px-md-0",
      style = "max-width: 1400px; font-size: 1.00rem;",
      markdown("
               This dashboard is an exploratory tool presenting descriptive statistics comparing the life satisfaction, happiness, and general health of adults from religious minority and majority groups across 53 countries in the World Values Survey (2017-2022). Modelled results will be added once the associated manuscript is published.")
    ),
    layout_sidebar(
      sidebar = sidebar(
        width = 300,
        selectInput("outcome", "Health/wellbeing measure",
                    choices = outcome_choices, selected = "life_satisfaction"),
        helpText("Select a measure to update the map and summary figure."),
        hr(style = "margin: 1rem 0;"),
        div(
          class = "small",
          style = "color: #5A5D63;",
          tags$p(tags$strong("Defining majority and minority groups"),
                 style = "margin-bottom: 0.35rem; color: #1B1F24;"),
          tags$p("Within each country, the religious group holding more than 50% of the survey sample is treated as the majority. All other respondents are grouped together as religious minorities.",
                 style = "margin-bottom: 0.5rem;"),
          tags$p("Countries with no group above 50% are not included.",
                 style = "margin-bottom: 0.9rem;"),
          tags$p(tags$strong("Understanding the figures"),
                 style = "margin-bottom: 0.35rem; color: #1B1F24;"),
          tags$p("A negative difference means minorities report lower average scores than the majority in that country. Differences are unadjusted group means.",
                 style = "margin-bottom: 0.5rem;"),
          tags$p("For more detail see 'Data & Methods'."),
        ),
        downloadButton("download_gaps", "Download country gaps (CSV)",
                       class = "btn-sm btn-outline-secondary")
      ),
      
      layout_columns(
        fill = FALSE,
        value_box("Countries", textOutput("vb_countries"), theme = value_box_theme(bg = "#D6E8E5", fg = "#12403A"), max_height ="140px"),
        value_box("Respondents", textOutput("vb_n"), theme = value_box_theme(bg = "#DDE3EC", fg = "#0B2A5B"), max_height = "140px"),
        value_box("Countries where minorities score lower", textOutput("vb_gap"), textOutput("vb_gap_detail"), theme = value_box_theme(bg = "#0B2A5B", fg = "#FFFFFF"), max_height = "140px")
      ),
      
      card(
        card_header("Where are the gaps largest?"),
        plotlyOutput("map", height = "380px"),
        card_footer(
          class = "text-muted small",
          "Blue: minorities report higher average scores than the majority.",
          "Red: minorities report lower average scores than the majority.",
          "Grey: country not in the analytic sample."
        )
      ),
      
      card(
        card_header(
          class = "d-flex justify-content-between align-items-center flex-wrap gap-2",
          "Majority and minority mean within each country",
          div(
            class = "d-flex gap-2 align-items-center",
            selectInput("sort_by", NULL,
                        choices = c("Order by gap size" = "gap",
                                    "Order by majority mean" = "majority",
                                    "Order alphabetically" = "alpha"),
                        selected = "gap", width = "200px"),
            selectInput("top_n_sel", NULL,
                        choices = c("All countries" = length(countries), 
                                    "Top 25" = 25, "Top 15" = 15, "Top 10" = 10),
                        selected = length(countries), width = "160px")
          )
        ),
        uiOutput("dumbbell_ui"),
        card_footer(
          class = "text-muted small",
          "Each line links the weighted mean for the religious majority",
          "to the mean for religious minorities in the same country.",
          "The number on the right is the difference between them (minority minus majority)."
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
        gap = "0.75rem",
        value_box("Majority group",
                  textOutput("vb_majority"), textOutput("vb_majority_pct"),
                  theme = value_box_theme(bg = "#D6E8E5", fg = "#12403A"),
                  min_height = "100px", max_height = "140px"),
        value_box("Minority share of sample", textOutput("vb_minshare"),
                  theme = value_box_theme(bg = "#DDE3EC", fg = "#0B2A5B"),
                  min_height = "100px", max_height = "140px"),
        value_box("Respondents", textOutput("vb_country_n"),
                  theme = value_box_theme(bg = "#0B2A5B", fg = "#FFFFFF"),
                  min_height = "100px", max_height = "140px")
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
            "Points show weighted group means. Horizontal bars show 95% confidence intervals around each mean, indicating how precisely each is estimated.",
            "The intervals describe each group separately and should not be used to judge whether the two groups differ. This is purely descriptive."
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

Weighted descriptive averages of ***three health and wellbeing measures (life satisfaction, 
happiness, general health) for religious majority and minority respondents in each country, 
using the World Values Survey (Wave 7, 2017-2022)***. It is an *exploratory* tool: everything
shown is a group mean or a raw difference between two group means. The dashboard will be 
updated with analytical models once the associated manuscript is published.

#### How majority and minority religions are defined

Religious groups are taken from the World Values Survey's religious denomination question. 
Respondents reporting no denomination are considered a category within religious affiliation.

Majority and minority status is determined based on religious composition from the survey 
sample itself. Within each country, the weighted share of respondents in each religious group is calculated, and the
group holding **more than 50%** of the sample is treated as the religious majority.
All other respondents are classified as religious minorities.

Countries with no group above 50%, and countries where minorities make up less
than 1% of the sample, are excluded.

All means use the survey's sampling weights. 

#### Important points

- Differences are purely descriptive and are not adjusted for age, sex, or any other
  characteristic. **No causal conclusions can be drawn.**
- Religious minorities are more likely to not respond to the happiness item, so
  observed differences are likely conservative.
- Defining majority status from sample shares rather than national religious
  demography means majority/minority definitions may differ from studies using external
  demographic sources.
- Minority groups are pooled together within each country and are not directly
  comparable across countries.

#### Item non-response by group
      "),
      
      tableOutput("missing_table"),
      
      markdown("
      
#### Source and code

Data: World Values Survey Wave 7 (2017-2022), accessed from
[worldvaluessurvey.org](https://www.worldvaluessurvey.org).

The individual-level survey data are not shared here, in line with World Values
Survey terms of use. This dashboard reads country-level summary tables produced 
by the preparation script in the project [repository](https://github.com/jasminecylee/religion-wellbeing-dashboard),
where the full analysis code is available.
      ")
    )
  ),
  
  nav_spacer(),
  nav_item(
    tags$a(
      "View code on GitHub",
      href = "https://github.com/jasminecylee/religion-wellbeing-dashboard",
      target = "_blank"
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
    df <- gaps_out() %>% slice_min(gap, n = n_shown(), with_ties = FALSE)
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
  
  n_shown <- reactive({
    req(input$top_n_sel)
    as.numeric(input$top_n_sel)
  })
  
  # -- Value boxes -------------------------------------------------------------
  
  output$vb_countries <- renderText(format(dash$meta$n_countries, big.mark = ","))
  output$vb_n         <- renderText(format(dash$meta$n_respondents, big.mark = ","))
  output$vb_gap       <- renderText({
    g <- gaps_out()$gap
    sprintf("%d of %d", sum(g < 0, na.rm = TRUE), sum(!is.na(g)))
  })
  output$vb_gap_detail <- renderText({
    g <- gaps_out()$gap
    sprintf("median gap %+.2f (range %+.2f to %+.2f)",
            median(g, na.rm = TRUE), min(g, na.rm = TRUE), max(g, na.rm = TRUE))
  })
  
  # -- Map ---------------------------------------------------------------------
  
  output$map <- renderPlotly({
    df  <- gaps_out() %>% filter(!is.na(iso3c))
    lim <- as.numeric(quantile(abs(df$gap), 0.95, na.rm = TRUE))
    
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
      colorbar   = list(title = list(text = "Minority - majority"),
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
    plotlyOutput("dumbbell", height = paste0(max(320, 19 * n_shown() + 90), "px"))
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
        legend.position    = "top",
        plot.background  = element_rect(fill = "transparent", colour = NA),
        panel.background = element_rect(fill = "transparent", colour = NA),
      )
    
    ggplotly(p, tooltip = "text") %>%
      layout(autosize = TRUE, legend = list(orientation = "h", x = 0, y = 1.04)) %>%
      config(displayModeBar = FALSE, responsive = TRUE)
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
            legend.position    = "top",
            plot.background  = element_rect(fill = "transparent", colour = NA),
            panel.background = element_rect(fill = "transparent", colour = NA),)
    
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
    
    p <- ggplot(df, aes(x = mean, y = religion_status, colour = religion_status)) +
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
        legend.position    = "none",
        plot.background  = element_rect(fill = "transparent", colour = NA),
        panel.background = element_rect(fill = "transparent", colour = NA),
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
