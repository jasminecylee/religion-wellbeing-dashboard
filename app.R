# ------------------------------------------------------------------------------
# Religious majority/minority wellbeing across countries
# An interactive dashboard of results from the World Values Survey (2017-2022)
#
# Data prepared by prepare_dashboard_data.Rmd, which reads the outputs saved by
# the Main Analysis. Numbers shown here match the manuscript.
# ------------------------------------------------------------------------------

library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)

# ---- Data --------------------------------------------------------------------

dash <- readRDS("data/dashboard_data.rds")

PAL <- list(
  majority = "#04BFAF",   # teal
  minority = "#0B2A5B",   # navy
  link     = "#D8D2C6",   # warm grey
  low      = "#B5552F",   # muted rust: minorities score lower
  mid      = "#F6F1E7",   # warm cream midpoint
  high     = "#0B2A5B",   # navy
  men      = "#7A6F9B",   # muted purple
  women    = "#B5552F"    # rust
)

outcome_choices <- c(
  "Life satisfaction (1-10 scale)" = "life_satisfaction",
  "Happiness (1-4 scale)"          = "happiness",
  "Self-rated health (1-5 scale)"  = "health"
)

countries <- sort(unique(dash$gaps$country))

# Formatting helpers
fmt_ci <- function(est, lo, hi) sprintf("%+.2f (%+.2f to %+.2f)", est, lo, hi)
fmt_p  <- function(p) ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))

transparent_theme <- theme(
  plot.background  = element_rect(fill = "transparent", colour = NA),
  panel.background = element_rect(fill = "transparent", colour = NA)
)

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
  
  # -- Shared sidebar: the selected measure updates every page ------------------
  sidebar = sidebar(
    width = 290,
    selectInput("outcome", "Health/wellbeing measure",
                choices = outcome_choices, selected = "life_satisfaction"),
    helpText("The selected measure updates every page."),
    hr(style = "margin: 1rem 0;"),
    div(
      class = "small",
      style = "color: #5A5D63;",
      tags$p(tags$strong("Defining majority and minority groups"),
             style = "margin-bottom: 0.35rem; color: #1B1F24;"),
      tags$p(HTML("Within each country, the religious group holding <em>&gt;50%</em> of the national population, according to the World Religion Database (2020), is treated as the <em>'majority'</em>. All other respondents are grouped together as <em>'religious minorities'</em>."),
             style = "margin-bottom: 0.5rem;"),
      tags$p("Countries with no group above 50% are not included.",
             style = "margin-bottom: 0.9rem;"),
      tags$p(tags$strong("Understanding the figures"),
             style = "margin-bottom: 0.35rem; color: #1B1F24;"),
      tags$p("A negative gap means minorities report lower scores than the majority in that country, after adjusting for age and sex.",
             style = "margin-bottom: 0.5rem;"),
      tags$p("For more detail see 'Data & Methods'.")
    ),
    downloadButton("download_gaps", "Download country gaps (CSV)",
                   class = "btn-sm btn-outline-secondary")
  ),
  
  # -- Tab 1: overall gap and country gaps --------------------------------------
  nav_panel(
    "Overall gap",
    div(
      class = "pt-3",
      style = "max-width: 1400px;",
      tags$p("Interactive visualisations from the paper",
             style = "margin-bottom: 0.15rem; color: #5A5D63; font-size: 0.9rem;"),
      tags$h4("Religious affiliation as a social determinant of subjective health and wellbeing: a multi-country investigation",
              style = "font-weight: 600; margin-bottom: 0.5rem;")
    ),
    div(
      class = "pb-2",
      style = "max-width: 1400px; font-size: 1.00rem;",
      markdown(paste0(
        "This dashboard presents results comparing the life satisfaction, happiness, and general health of adults from religious minority and majority groups across ",
        dash$meta$n_countries,
        " countries in the World Values Survey (2017-2022). Gaps are adjusted for age and sex."))
    ),
    
    layout_columns(
      fill = FALSE,
      value_box("Overall gap (minority - majority)",
                textOutput("vb_pooled"), textOutput("vb_pooled_ci"),
                theme = value_box_theme(bg = "#0B2A5B", fg = "#FFFFFF"), max_height = "140px"),
      value_box("Between-country variation (I²)",
                textOutput("vb_i2"),
                theme = value_box_theme(bg = "#DDE3EC", fg = "#0B2A5B"), max_height = "140px"),
      value_box("Countries where minorities score lower on average",
                textOutput("vb_gap"), textOutput("vb_gap_detail"),
                theme = value_box_theme(bg = "#D6E8E5", fg = "#12403A"), max_height = "140px")
    ),
    
    card(
      card_header("Where are the gaps largest?"),
      plotlyOutput("map", height = "380px"),
      card_footer(
        class = "text-muted small",
        "Blue: minorities report higher scores than the majority.",
        "Red: minorities report lower scores than the majority.",
        "Grey: country not in the analytic sample."
      )
    ),
    
    card(
      card_header("Gap in each country"),
      uiOutput("forest_ui"),
      card_footer(
        class = "text-muted small",
        "Points show each country's gap with its 95% confidence interval.",
        "The diamond at the bottom shows the overall gap across countries (random-effects meta-analysis) and its 95% confidence interval; the teal line and band extend it across the countries for comparison."
      )
    )
  ),
  
  # -- Tab 2: country profile ---------------------------------------------------
  nav_panel(
    "Country profile",
    div(
      class = "pt-3",
      style = "max-width: 360px;",
      selectizeInput(
        "country", "Search for a country",
        choices  = countries,
        selected = countries[1],
        options  = list(placeholder = "Start typing a country name...")
      )
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
        plotlyOutput("composition", height = "380px"),
        card_footer(
          class = "text-muted small",
          "Bars show the weighted share of World Values Survey respondents in each group.",
          "Majority status follows the World Religion Database."
        )
      ),
      card(
        card_header("Wellbeing by religious status"),
        plotlyOutput("country_means", height = "460px"),
        card_footer(
          class = "text-muted small",
          "Points show weighted group means. Horizontal bars show 95% confidence intervals around each mean, indicating how precisely each is estimated.",
          "The intervals describe each group separately and should not be used to judge whether the two groups differ; see the adjusted gap in the table below."
        )
      )
    ),
    
    card(
      card_header("Group averages and differences"),
      DTOutput("country_table"),
      card_footer(
        class = "text-muted small",
        "Adjusted gap: minority minus majority, adjusted for age and sex (95% CI).",
        "Unadjusted difference: minority mean minus majority mean."
      )
    )
  ),
  
  # -- Tab 3: sex differences ---------------------------------------------------
  nav_panel(
    "Sex differences",
    div(
      class = "pt-3 pb-2",
      style = "max-width: 1400px; font-size: 1.00rem;",
      markdown("The minority–majority gap estimated separately for men and women, adjusted for age.")
    ),
    
    layout_columns(
      fill = FALSE,
      value_box("Overall gap: men",
                textOutput("vb_men"), textOutput("vb_men_ci"),
                theme = value_box_theme(bg = "#E6E3EE", fg = "#3D3557"), max_height = "140px"),
      value_box("Overall gap: women",
                textOutput("vb_women"), textOutput("vb_women_ci"),
                theme = value_box_theme(bg = "#F3E2DA", fg = "#6B2E16"), max_height = "140px"),
      value_box("Difference (women - men)",
                textOutput("vb_sexdiff"), textOutput("vb_sexdiff_ci"),
                theme = value_box_theme(bg = "#0B2A5B", fg = "#FFFFFF"), max_height = "140px")
    ),
    
    card(
      card_header("Gap in each country, by sex"),
      uiOutput("sex_ui"),
      card_footer(
        class = "text-muted small",
        "Points show each country's gap for men and women with 95% confidence intervals.",
        "Countries are ordered by their overall gap."
      )
    )
  ),
  
  # -- Tab 4: moderation --------------------------------------------------------
  nav_panel(
    "Country-level indicators",
    div(
      class = "pt-3 pb-2",
      style = "max-width: 1400px; font-size: 1.00rem;",
      markdown("How does the minority–majority gap vary with country-level religious restrictions and hostilities, democracy, GDP, and income inequality?")
    ),
    
    card(
      card_header("Gap by level of government restrictions and social hostilities"),
      plotlyOutput("mod_plot", height = "480px"),
      card_footer(
        class = "text-muted small",
        "Small points: each country's gap (hover to see the country).",
        "Teal diamonds: the gap within each category from multilevel models, with 95% confidence intervals adjusted for multiple comparisons across categories.",
        "Categories follow Pew Research Center thresholds; n is the number of countries in each category."
      )
    ),
    
    card(
      card_header(
        class = "d-flex justify-content-between align-items-center flex-wrap gap-2",
        "Gap by other country-level indicators",
        selectInput("cont_ind", NULL,
                    choices = c("Democracy index (Polity)"    = "democracy_matched",
                                "GDP per capita (World Bank)" = "gdp_matched",
                                "Gini index (World Bank)"     = "gini_matched"),
                    selected = "democracy_matched", width = "280px")
      ),
      plotlyOutput("cont_plot", height = "420px"),
      card_footer(
        class = "text-muted small",
        "Each point is one country's gap plotted against the selected indicator (hover to see the country)."
      )
    )
  ),
  
  # -- Tab 5: data and methods --------------------------------------------------
  nav_panel(
    "Data & methods",
    div(
      class = "container-sm py-3",
      style = "max-width: 820px;",
      
      markdown("
#### What this dashboard shows

Results comparing ***three health and wellbeing measures (life satisfaction, 
happiness, general health) for religious majority and minority respondents in each country, 
using the World Values Survey (Wave 7, 2017-2022)***. These are the results reported in the 
associated manuscript.

#### How majority and minority religions are defined

Religious groups are taken from the World Values Survey's religious denomination question. 
Respondents reporting no denomination are considered a category within religious affiliation.

Majority and minority status is determined based on national religious composition from the 
World Religion Database (2020). Within each country, the religious group holding **more than 50%** 
of the national population is treated as the religious majority. All other respondents are 
classified as religious minorities.

Countries with no group above 50%, countries where the majority group is not present in the 
survey sample, and countries where minorities make up less than 1% of the sample, are excluded.

#### How the gaps are estimated

- **Country gaps:** within each country, a linear regression of the measure on religious 
  minority status, adjusted for age and sex, using the survey's sampling weights and robust 
  (HC2) standard errors.
- **Overall gap:** country gaps pooled in a random-effects meta-analysis. I² describes how much 
  of the variation between countries is beyond chance; the prediction interval gives the range 
  in which the gap for a country would be expected to fall.
- **Sex differences:** the same models run separately for men and women (adjusted for age). 
  Whether the gap differs between women and men was tested with a minority status × sex 
  interaction in each country, pooled across countries (90% CI, α = 0.10).
- **Moderation:** multilevel models with individuals nested within countries, including random 
  slopes for minority status and adjusted for age and sex, with an interaction between 
  minority status and each country-level indicator, one at a time. Government restrictions and 
  social hostilities were also grouped into Pew Research Center's four categories. Interaction 
  terms are judged at α = 0.10 (90% CI); gaps within each category use 95% CIs adjusted for 
  multiple comparisons.

Country gaps and descriptive means use the survey's sampling weights; multilevel models are 
unweighted and adjusted for age and sex.

#### Important points

- Differences are adjusted for age and sex only. **No causal conclusions can be drawn.**
- Religious minorities are more likely to not respond to the outcome items, so
  observed differences are likely conservative.
- Majority status is defined from national religious demography, so a group's share of the 
  survey sample may differ from its share of the national population.
- Minority groups are pooled together within each country and are not directly
  comparable across countries.
- Estimates for categories containing few countries are imprecise; the number of countries 
  is shown on the moderation plot.

#### Item non-response by group
      "),
      
      tableOutput("missing_table"),
      
      markdown("
      
#### Source and code

Data: World Values Survey Wave 7 (2017-2022), accessed from
[worldvaluessurvey.org](https://www.worldvaluessurvey.org). National religious composition: 
World Religion Database (2020). Government Restrictions and Social Hostilities Indices: Pew 
Research Center. Democracy: Polity. GDP per capita and Gini index: World Bank.

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
      target = "_blank",
      class = "btn btn-sm btn-outline-primary",
      style = "margin: 0.4rem 0; padding: 0.2rem 0.7rem; font-size: 0.85rem;"
    )
  )
)

# ---- Server ------------------------------------------------------------------

server <- function(input, output, session) {
  
  outcome_name <- reactive(names(outcome_choices)[outcome_choices == input$outcome])
  
  # -- Reactive slices ---------------------------------------------------------
  
  gaps_out   <- reactive(dash$gaps   %>% filter(outcome == input$outcome))
  pooled_out <- reactive(dash$pooled %>% filter(outcome == input$outcome))
  
  # ==========================================================================
  # Tab 1: overall gap
  # ==========================================================================
  
  output$vb_pooled <- renderText(sprintf("%+.2f", pooled_out()$estimate))
  output$vb_pooled_ci <- renderText({
    pl <- pooled_out()
    sprintf("95%% CI %+.2f to %+.2f", pl$ci_lb, pl$ci_ub)
  })
  
  output$vb_i2 <- renderText(sprintf("%.0f%%", pooled_out()$I2))
  
  output$vb_gap <- renderText({
    g <- gaps_out()$gap
    sprintf("%d of %d", sum(g < 0, na.rm = TRUE), sum(!is.na(g)))
  })
  output$vb_gap_detail <- renderText({
    sprintf("%d with 95%% CI below zero", sum(gaps_out()$gap_upper < 0, na.rm = TRUE))
  })
  
  # -- Map ---------------------------------------------------------------------
  
  output$map <- renderPlotly({
    df  <- gaps_out() %>% filter(!is.na(iso3c))
    lim <- as.numeric(quantile(abs(df$gap), 0.95, na.rm = TRUE))
    
    df <- df %>%
      mutate(hover = paste0(
        "<b>", country, "</b><br>",
        "Majority: ", majority_religion, "<br>",
        "Gap: ", fmt_ci(gap, gap_lower, gap_upper)
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
          projection     = list(type = "robinson"),
          showframe      = FALSE,
          showcoastlines = FALSE,
          showland       = TRUE,
          landcolor      = "#EDEFF2",
          bgcolor        = "rgba(0,0,0,0)"
        ),
        margin        = list(l = 0, r = 0, t = 10, b = 0),
        paper_bgcolor = "rgba(0,0,0,0)"
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # -- Country gaps (forest plot) ----------------------------------------------
  
  output$forest_ui <- renderUI({
    plotlyOutput("forest", height = paste0(18 * nrow(gaps_out()) + 140, "px"))
  })
  
  output$forest <- renderPlotly({
    pl <- pooled_out()
    
    # Overall diamond sits at y = 1; countries start at y = 3 (row 2 left blank)
    df <- gaps_out() %>%
      arrange(gap) %>%
      mutate(y = row_number() + 2)
    n <- nrow(df)
    
    diamond <- tibble(x = c(pl$ci_lb, pl$estimate, pl$ci_ub, pl$estimate),
                      y = c(1, 1.4, 1, 0.6))
    overall <- tibble(x = pl$estimate, y = 1,
                      text = paste0("<b>Overall</b><br>",
                                    "Gap: ", fmt_ci(pl$estimate, pl$ci_lb, pl$ci_ub), "<br>",
                                    "Prediction interval: ", sprintf("%+.2f to %+.2f", pl$pi_lb, pl$pi_ub), "<br>",
                                    "I² = ", sprintf("%.0f%%", pl$I2), ", ", pl$k, " countries"))
    
    p <- ggplot() +
      annotate("rect", xmin = pl$ci_lb, xmax = pl$ci_ub, ymin = 2.5, ymax = n + 2.5,
               fill = PAL$majority, alpha = 0.12) +
      geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
      annotate("segment", x = pl$estimate, xend = pl$estimate, y = 1.4, yend = n + 2.5,
               colour = PAL$majority, linewidth = 0.7) +
      geom_hline(yintercept = 2, colour = "grey80") +
      geom_segment(data = df, aes(x = gap_lower, xend = gap_upper, y = y, yend = y),
                   colour = PAL$minority, alpha = 0.45, linewidth = 0.8) +
      geom_point(data = df,
                 aes(x = gap, y = y,
                     text = paste0("<b>", country, "</b><br>",
                                   "Gap: ", fmt_ci(gap, gap_lower, gap_upper))),
                 colour = PAL$minority, size = 2.2) +
      geom_polygon(data = diamond, aes(x = x, y = y),
                   fill = PAL$majority, colour = PAL$majority) +
      geom_point(data = overall, aes(x = x, y = y, text = text),
                 colour = PAL$majority, size = 6, alpha = 0.01) +   # invisible hover target
      scale_y_continuous(breaks = c(1, df$y),
                         labels = c("<b>Overall</b>", df$country),
                         expand = expansion(add = 0.6)) +
      labs(x = paste("Minority - majority gap in", tolower(outcome_name())), y = NULL) +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank(),
            panel.grid.major.y = element_line(colour = "#F2F3F5"),
            axis.text.y = element_text(size = 10)) +
      transparent_theme
    
    ggplotly(p, tooltip = "text") %>% config(displayModeBar = FALSE)
  })
  
  output$download_gaps <- downloadHandler(
    filename = function() paste0("country_gaps_", input$outcome, ".csv"),
    content  = function(file) readr::write_csv(gaps_out(), file)
  )
  
  # ==========================================================================
  # Tab 2: country profile
  # ==========================================================================
  
  country_comp <- reactive({
    dash$composition %>%
      filter(country == input$country) %>%
      arrange(share)
  })
  
  country_gaps <- reactive(dash$gaps %>% filter(country == input$country))
  
  output$vb_majority <- renderText({
    g <- country_gaps()
    if (nrow(g) == 0) return("-")
    g$majority_religion[1]
  })
  
  output$vb_majority_pct <- renderText({
    g <- country_gaps()
    if (nrow(g) == 0) return("")
    sprintf("%.0f%% of the national population", g$majority_share[1])
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
                                      sprintf("%.1f%%", share), " of sample<br>",
                                      ifelse(is.na(wrd_share), "",
                                             paste0(sprintf("%.1f%%", wrd_share),
                                                    " of national population<br>")),
                                      "n = ", format(n, big.mark = ",")))) +
      geom_col(width = 0.68) +
      scale_fill_manual(values = c(Majority = PAL$majority, Minority = PAL$minority),
                        name = NULL) +
      labs(x = "% of weighted sample", y = NULL) +
      theme_minimal(base_size = 12) +
      theme(panel.grid.major.y = element_blank(),
            panel.grid.minor   = element_blank(),
            legend.position    = "top") +
      transparent_theme
    
    ggplotly(p, tooltip = "text") %>%
      layout(legend = list(orientation = "h", x = 0, y = 1.14,
                           xanchor = "left", yanchor = "bottom"),
             margin = list(t = 60)) %>%
      config(displayModeBar = FALSE)
  })
  
  output$country_means <- renderPlotly({
    df <- dash$means %>%
      filter(country == input$country) %>%
      mutate(
        measure = factor(outcome,
                         levels = c("life_satisfaction", "happiness", "health"),
                         labels = c("Life satisfaction (1-10)", "Happiness (1-4)", "Self-rated health (1-5)")),
        religion_status = factor(religion_status, levels = c("Minority", "Majority"))
      )
    
    p <- ggplot(df, aes(x = mean, y = religion_status, colour = religion_status)) +
      geom_segment(aes(x = lower, xend = upper, yend = religion_status), alpha = 0.55) +
      geom_point(aes(text = paste0("<b>", religion_status, "</b><br>",
                                   "Mean: ", sprintf("%.2f", mean),
                                   "<br>95% CI ", sprintf("%.2f", lower), " to ", sprintf("%.2f", upper),
                                   "<br>n = ", format(n, big.mark = ","))),
                 size = 3.6) +
      facet_wrap(~ measure, ncol = 1, scales = "free_x") +
      scale_colour_manual(values = c(Majority = PAL$majority, Minority = PAL$minority)) +
      labs(x = NULL, y = NULL) +
      theme_minimal(base_size = 12) +
      theme(panel.grid.major.y = element_blank(),
            panel.grid.minor   = element_blank(),
            strip.text         = element_text(hjust = 0, face = "bold", size = 10),
            legend.position    = "none") +
      transparent_theme
    
    ggplotly(p, tooltip = "text") %>%
      layout(margin = list(t = 30)) %>%
      config(displayModeBar = FALSE)
  })
  
  output$country_table <- renderDT({
    country_gaps() %>%
      mutate(measure = factor(outcome,
                              levels = c("life_satisfaction", "happiness", "health"),
                              labels = c("Life satisfaction (1-10)", "Happiness (1-4)", "Self-rated health (1-5)"))) %>%
      arrange(measure) %>%
      transmute(
        Measure = as.character(measure),
        `Majority mean` = sprintf("%.2f", mean_Majority),
        `Minority mean` = sprintf("%.2f", mean_Minority),
        `Adjusted gap (95% CI)` = fmt_ci(gap, gap_lower, gap_upper),
        `Unadjusted difference` = sprintf("%+.2f", gap_raw),
        `n (maj / min)` = sprintf("%s / %s",
                                  format(n_Majority, big.mark = ","),
                                  format(n_Minority, big.mark = ","))
      ) %>%
      datatable(rownames = FALSE, class = "compact stripe hover",
                options = list(dom = "t", ordering = FALSE, paging = FALSE,
                               columnDefs = list(list(className = "dt-right", targets = 1:5))))
  })
  
  # ==========================================================================
  # Tab 3: sex differences
  # ==========================================================================
  
  sex_pooled_out <- reactive(dash$sex_pooled %>% filter(outcome == input$outcome))
  sex_diff_out   <- reactive(dash$sex_diff   %>% filter(outcome == input$outcome))
  
  pooled_sex_text <- function(sx) {
    s <- sex_pooled_out() %>% filter(sex == sx)
    list(est = sprintf("%+.2f", s$estimate),
         ci  = sprintf("95%% CI %+.2f to %+.2f", s$ci_lb, s$ci_ub))
  }
  
  output$vb_men      <- renderText(pooled_sex_text("Men")$est)
  output$vb_men_ci   <- renderText(pooled_sex_text("Men")$ci)
  output$vb_women    <- renderText(pooled_sex_text("Women")$est)
  output$vb_women_ci <- renderText(pooled_sex_text("Women")$ci)
  
  output$vb_sexdiff <- renderText(sprintf("%+.2f", sex_diff_out()$estimate))
  output$vb_sexdiff_ci <- renderText({
    d <- sex_diff_out()
    sprintf("90%% CI %+.2f to %+.2f, p = %s", d$ci_lb, d$ci_ub, fmt_p(d$p))
  })
  
  output$sex_ui <- renderUI({
    plotlyOutput("sex_plot", height = paste0(22 * nrow(gaps_out()) + 120, "px"))
  })
  
  output$sex_plot <- renderPlotly({
    ord <- gaps_out() %>% arrange(gap) %>% pull(country)
    
    # Offset men and women vertically within each country row
    df <- dash$sex_country %>%
      filter(outcome == input$outcome, country %in% ord) %>%
      mutate(y = match(country, ord) + if_else(sex == "Women", 0.18, -0.18))
    
    p <- ggplot(df, aes(colour = sex)) +
      geom_vline(xintercept = 0, linetype = "dashed", colour = "grey55") +
      geom_segment(aes(x = gap_lower, xend = gap_upper, y = y, yend = y),
                   alpha = 0.45, linewidth = 0.7) +
      geom_point(aes(x = gap, y = y,
                     text = paste0("<b>", country, "</b> (", sex, ")<br>",
                                   "Gap: ", fmt_ci(gap, gap_lower, gap_upper))),
                 size = 2) +
      scale_y_continuous(breaks = seq_along(ord), labels = ord, expand = expansion(add = 0.6)) +
      scale_colour_manual(values = c(Men = PAL$men, Women = PAL$women), name = NULL) +
      labs(x = paste("Minority - majority gap in", tolower(outcome_name())), y = NULL) +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank(),
            panel.grid.major.y = element_line(colour = "#F2F3F5"),
            axis.text.y = element_text(size = 10),
            legend.position = "top") +
      transparent_theme
    
    ggplotly(p, tooltip = "text") %>%
      layout(legend = list(orientation = "h", x = 0, y = 1.02, yanchor = "bottom")) %>%
      config(displayModeBar = FALSE)
  })
  
  # ==========================================================================
  # Tab 4: moderation
  # ==========================================================================
  
  cats <- c("Low", "Moderate", "High", "Very High")
  index_labels <- c(GRI = "Government restrictions", SHI = "Social hostilities")
  
  output$mod_plot <- renderPlotly({
    # Each country's gap, placed in its GRI and SHI category
    set.seed(2026)   # same jitter every time
    pts <- bind_rows(
      gaps_out() %>% transmute(country, gap, gap_lower, gap_upper,
                               index = "GRI", category = as.character(gri_category), score = gri_matched),
      gaps_out() %>% transmute(country, gap, gap_lower, gap_upper,
                               index = "SHI", category = as.character(shi_category), score = shi_matched)
    ) %>%
      filter(!is.na(category)) %>%
      mutate(x = match(category, cats) + runif(n(), -0.2, 0.2),
             index_label = index_labels[index])
    
    # Model-estimated gap within each category
    est <- dash$simple_effects %>%
      filter(outcome == input$outcome) %>%
      left_join(dash$category_n, by = c("index", "category")) %>%
      mutate(x = match(category, cats), index_label = index_labels[index])
    
    label_y <- min(pts$gap, est$ci_lb, na.rm = TRUE) -
      0.06 * diff(range(c(pts$gap, est$ci_lb, est$ci_ub), na.rm = TRUE))
    
    p <- ggplot() +
      geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
      geom_point(data = pts,
                 aes(x = x, y = gap,
                     text = paste0("<b>", country, "</b><br>",
                                   index_label, ": ", category,
                                   " (score ", sprintf("%.1f", score), ")<br>",
                                   "Country gap: ", fmt_ci(gap, gap_lower, gap_upper))),
                 colour = PAL$minority, alpha = 0.4, size = 2.2) +
      geom_errorbar(data = est, aes(x = x, ymin = ci_lb, ymax = ci_ub),
                    width = 0.12, colour = PAL$majority, linewidth = 0.9) +
      geom_point(data = est,
                 aes(x = x, y = estimate,
                     text = paste0("<b>", index_label, ": ", category, "</b><br>",
                                   "Gap in this category: ", fmt_ci(estimate, ci_lb, ci_ub), "<br>",
                                   n_countries, " countries")),
                 colour = PAL$majority, shape = 18, size = 5) +
      geom_text(data = est, aes(x = x, y = label_y, label = paste0("n = ", n_countries)),
                size = 3, colour = "#6B6F76") +
      facet_wrap(~ index_label) +
      scale_x_continuous(breaks = 1:4, labels = cats) +
      labs(x = NULL, y = paste("Minority - majority gap in\n", tolower(outcome_name()))) +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank(),
            panel.grid.major.x = element_blank(),
            strip.text = element_text(face = "bold", size = 11)) +
      transparent_theme
    
    ggplotly(p, tooltip = "text") %>% config(displayModeBar = FALSE)
  })
  
  output$cont_plot <- renderPlotly({
    ind <- input$cont_ind
    ind_label <- c(democracy_matched = "Democracy index (Polity)",
                   gdp_matched       = "GDP per capita (log scale)",
                   gini_matched      = "Gini index")[ind]
    
    df <- gaps_out() %>%
      mutate(value = .data[[ind]]) %>%
      filter(!is.na(value))
    
    p <- ggplot(df, aes(x = value, y = gap)) +
      geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55") +
      geom_segment(aes(xend = value, y = gap_lower, yend = gap_upper),
                   colour = PAL$minority, alpha = 0.25) +
      geom_point(aes(text = paste0("<b>", country, "</b><br>",
                                   ind_label, ": ", format(round(value, 1), big.mark = ","), "<br>",
                                   "Gap: ", fmt_ci(gap, gap_lower, gap_upper))),
                 colour = PAL$minority, alpha = 0.6, size = 2.4) +
      labs(x = ind_label, y = paste("Minority - majority gap in\n", tolower(outcome_name()))) +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank()) +
      transparent_theme
    
    if (ind == "gdp_matched") p <- p + scale_x_log10(labels = scales::comma)
    
    ggplotly(p, tooltip = "text") %>% config(displayModeBar = FALSE)
  })
  
  # ==========================================================================
  # Tab 5: data & methods
  # ==========================================================================
  
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