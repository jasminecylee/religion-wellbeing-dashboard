## Health and wellbeing of religious minorities and majorities across countries

An interactive dashboard of descriptive differences in wellbeing and health between religious majority and minority groups, using the World Values Survey (Wave 7, 2017–2022).

*Live app**: <https://jasminecylee.shinyapps.io/religious-min-maj-health-wellbeing/>

### What it does

- Maps the size and direction of the minority–majority difference in outcome across 53 countries

- Ranks countries by the size of the difference, showing both group means side by side

- Allows you to search for a single country and see its religious composition and group means

Three measures are included: life satisfaction (1–10), happiness (1–4), and self-rated general health (1–5).

This is an exploratory tool. Everything shown is a weighted group mean or a raw difference between two group means; no modelled estimates are presented. The dashboard will be updated once the associated manuscript is published.

### How majority and minority are defined

Religious composition is estimated from the survey sample itself, rather than from external religious demography. Within each country, the weighted share of respondents in each religious group is calculated, and the group holding more than 50% of the sample is treated as the religious majority. All other respondents are classified as religious minorities.

Countries are excluded where no group exceeds 50% of the sample, or where religious minorities make up less than 1% of the sample.

### Repository structure

```         
├── app.R                          # Shiny dashboard}
├── prepare_dashboard_data.Rmd     # derives majority/minority status, builds aggregated tables
├── data/
  │   ├── dashboard_data.rds       # aggregated country-level tables (committed)
  │   └── country_gaps.csv         # country-level differences
└── README.md
```

### Reproducing

The World Values Survey microdata are not redistributed in this repository, in line with the WVS terms of use.

To rebuild the aggregated data:

1.  Download the WVS Wave 7 cross-national file from worldvaluessurvey.org and register for access.

2.  Place the cleaned respondent-level file as data.rds in the project root, or point the readRDS() call in the preparation script at its location.

3.  Knit prepare_dashboard_data.Rmd, which writes data/dashboard_data.rds.

4.  Run the app: r shiny::runApp()

### Notes and caveats 

- All figures are **descriptive**. Differences are unadjusted group means and **should not be interpreted causally**.

- Religious minorities are more likely to leave the happiness item blank, so observed differences are likely conservative. Item non-response rates by group are reported in the app.

- Minority groups are pooled within each country and are not directly comparable across countries.

- Groups are taken from the WVS religious denomination question. Respondents reporting no denomination are treated as a group in their own right, and in some countries they form the majority.

- Survey sampling weights are applied throughout

### Data source

World Values Survey Wave 7 (2017–2022). Haerpfer, C., Inglehart, R., Moreno, A., et al. (eds.). Madrid & Vienna: JD Systems Institute & WVSA Secretariat.

### Licence

Code released under the MIT Licence. The World Values Survey data are subject to the WVS terms of use and are not redistributed here.
