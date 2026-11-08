## Religious affiliation as a social determinant of subjective health and wellbeing: a multi-country investigation

Jasmine Lee, Jacques Wels, Kelly Rose-Clarke, Praveetha Patalay

This is an interactive dashboard to better visualise the results from our manuscript on differences in wellbeing and health outcomes between religious majority and minority groups, using the World Values Survey (Wave 7, 2017–2022).

# Live app: <https://jasminecylee.shinyapps.io/religious-min-maj-health-wellbeing/>

### What it does

- **Overall gap:** shows the overall minority–majority gap across 54 countries, maps the size and direction of the gap in each country, and shows each country's gap with its 95% confidence interval

- **Country profile:** allows you to search for a single country and see its religious composition, group means, and minority–majority gap

- **Sex differences:** shows the gap separately for men and women, overall and in each country

- **Country-level indicators:** shows how the gap varies with government restrictions on religion and social hostilities involving religion, as well as democracy, GDP per capita, and income inequality

Three measures are included: life satisfaction (1–10), happiness (1–4), and self-rated general health (1–5).

Gaps are adjusted for age and sex, and match the results reported in the associated manuscript.

### How majority and minority are defined

Religious groups are taken from the WVS religious denomination question. Majority and minority status is determined from national religious composition in the World Religion Database (2020). Within each country, the religious group holding more than 50% of the national population is treated as the religious majority. All other respondents are classified as religious minorities.

Countries are excluded where no group exceeds 50% of the national population, where the majority group is not present in the survey sample, or where religious minorities make up less than 1% of the sample.

### How the gaps are estimated

- **Country gaps:** within each country, a linear regression of each measure on religious minority status, adjusted for age and sex, using survey sampling weights and robust (HC2) standard errors.

- **Overall gap:** country gaps pooled in a random-effects meta-analysis.

- **Sex differences:** the same models run separately for men and women (adjusted for age). Whether the gap differs between women and men was tested with a minority status × sex interaction in each country, pooled across countries (90% CI, α = 0.10).

- **Country-level indicators:** multilevel models with individuals nested within countries, including random slopes for minority status and adjusted for age and sex, with an interaction between minority status and each country-level indicator. Government restrictions and social hostilities are also grouped into Pew Research Center's four categories.

### Repository structure

```         
├── app.R                          # Shiny dashboard
├── prepare_dashboard_data.Rmd     # builds aggregated tables from the main analysis outputs
├── data/
  │   ├── dashboard_data.rds       # aggregated country-level tables 
  │   └── country_gaps.csv         # country-level gaps
└── README.md
```

### Reproducing

The World Values Survey microdata are not redistributed in this repository, in line with the WVS terms of use.

To rebuild the aggregated data:

1.  Download the WVS Wave 7 cross-national file from worldvaluessurvey.org and register for access.

2.  Run the main analysis script, which saves the respondent-level analytic sample (`data_analytic.rds`) and the model results (`dashboard_model_outputs.rds`).

3.  Place both files in the project root, or point the `readRDS()` calls in the preparation script at their location.

4.  Knit `prepare_dashboard_data.Rmd`, which writes `data/dashboard_data.rds` and `data/country_gaps.csv`.

5.  Run the app: `shiny::runApp()`

### Notes and caveats

- Gaps are adjusted for age and sex only and should not be interpreted causally.

- Religious minorities are more likely to leave the outcome items blank, so observed differences are likely conservative. Item non-response rates by group are reported in the app.

- Minority groups are pooled within each country and are not directly comparable across countries.

- Respondents reporting no denomination are treated as a group in their own right, and in some countries they form the majority.

- Majority status is defined from national religious demography, so a group's share of the survey sample may differ from its share of the national population.

- Country gaps and descriptive means use survey sampling weights; multilevel models are unweighted and adjusted for age and sex.Data source

## Data sources

- World Values Survey Wave 7 (2017–2022). Haerpfer, C., Inglehart, R., Moreno, A., et al. (eds.). Madrid & Vienna: JD Systems Institute & WVSA Secretariat.

- National religious composition: World Religion Database (2020).

- Government Restrictions Index and Social Hostilities Index: Pew Research Center.

- Democracy: Polity.

- GDP per capita and Gini index: World Bank.

### Licence

Code released under the MIT Licence. The World Values Survey data are subject to the WVS terms of use and are not redistributed here.
