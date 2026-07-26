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
