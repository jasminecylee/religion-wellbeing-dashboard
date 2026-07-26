# Religious majority/minority wellbeing across countries

An interactive dashboard of descriptive wellbeing differences between religious
majority and minority respondents, using the World Values Survey (Wave 7,
2017–2022).

**Live app:** https://jasminecylee.shinyapps.io/religious-min-maj-health-wellbeing/

## What it does

- Maps the size of the minority–majority health and wellbeing difference across countries
- Shows majority and minority group averages side by side, with the difference
  between them
- Lets you search for a single country and see its religious composition and
  group averages

Three measures are included: life satisfaction (1–10), happiness (1–4), and
self-rated general health (1–5).

## How majority and minority are defined

Religious composition is estimated from the World Values Survey sample itself. 
Within each country, the weighted share of respondents in each religious group 
is calculated, and the group holding more than 50% of the sample is treated as 
the religious majority; all other respondents are classified as religious minorities.

Countries are excluded where no group exceeds 50% of the sample, or where
religious minorities make up less than 1% of the sample.

## Repository structure

```
├── prepare_dashboard_data.Rmd   # derives majority/minority status, builds aggregated tables
├── app.R                           # Shiny dashboard
├── data/
│   ├── dashboard_data.rds          # aggregated country-level tables (committed)
│   └── country_gaps.csv            # country-level differences, for reuse
└── README.md
```

## Reproducing

The World Values Survey microdata are not redistributed in this repository.
To rebuild the aggregated data:

1. Download the WVS Wave 7 cross-national file from
   [worldvaluessurvey.org](https://www.worldvaluessurvey.org) and register for
   access.
2. Place the cleaned respondent-level file as `data.rds` in the project root.
3. Knit `01_prepare_dashboard_data.Rmd`, which writes `data/dashboard_data.rds`.
4. Run the app:

```r
shiny::runApp()
```

### Dependencies

```r
install.packages(c("shiny", "bslib", "dplyr", "tidyr", "ggplot2",
                   "plotly", "DT", "readr", "countrycode"))
```

## Notes and caveats

- All figures are **descriptive**. Differences are unadjusted group means and
  should not be interpreted causally.
- Religious minorities are more likely to leave the happiness item blank, so
  the observed differences are likely conservative. Item non-response rates by
  group are reported in the app.
- Minority groups are pooled within each country and are not directly
  comparable across countries.
- Survey sampling weights are applied throughout; standard errors use Kish's
  effective sample size.

## Data source

World Values Survey Wave 7 (2017–2022). Haerpfer, C., Inglehart, R., Moreno,
A., et al. (eds.). Madrid & Vienna: JD Systems Institute & WVSA Secretariat.

## Licence

Code released under the MIT Licence. The World Values Survey data are subject
to the WVS terms of use and are not redistributed here.
