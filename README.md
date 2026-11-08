# Religious affiliation as a social determinant of subjective health and wellbeing: a multi-country investigation

Jasmine Lee, Jacques Wels, Kelly Rose-Clarke, Praveetha Patalay

Analysis code and interactive dashboard for our study of differences in life satisfaction, happiness, and self-rated health between religious majority and minority groups across countries, using the World Values Survey (Wave 7, 2017–2022).

**Interactive dashboard:** <https://jasminecylee.shinyapps.io/religious-min-maj-health-wellbeing/>

The dashboard was built for easy exploration of the results, including a profile for each country.

## Overview

The study compares adults from religious minority and majority groups in 54 countries on three outcomes: life satisfaction (1–10), happiness (1–4), and self-rated general health (1–5). It estimates the minority–majority gap in each country, pools these into an overall gap, examines whether the gap differs between men and women, and tests whether it varies with country-level government restrictions of religion, social hostilities aginast religion, democracy, GDP per capita, and Gini index (income inequality).

## Repository structure

```         
├── analysis/
│   ├── Pre-processing.R                                    # cleans WVS data and merges country-level data
│   ├── Main analyses.Rmd                                   # main analyses, figures, and outputs for the dashboard
│   ├── Sensitivity analysis - Excluding no denomination.rmd  # repeats analyses excluding the no-denomination group
│   ├── Sensitivity analysis - Largest group.Rmd            # repeats analyses with the largest group as majority
│   └── Sensitivity analysis - Meta-regressions.Rmd         # country-level meta-regressions
├── app.R                                                   # Shiny dashboard
├── prepare_dashboard_data.Rmd                              # builds aggregated tables for the dashboard
└── README.md
```

## How majority and minority are defined

Religious groups are taken from the World Values Survey religious denomination question. Majority and minority status is determined from national religious composition in the World Religion Database (2020). Within each country, the religious group holding more than 50% of the national population is treated as the religious majority. All other respondents are classified as religious minorities. Respondents reporting no denomination are treated as a group in their own right.

Countries are excluded where no group exceeds 50% of the national population, where the majority group is not present in the survey sample, or where religious minorities make up less than 1% of the sample.

## Analyses

**Main analyses** (`Main analyses.Rmd`)

- **Country gaps:** within each country, a linear regression of each measure on religious minority status, adjusted for age and sex, using survey sampling weights and robust (HC2) standard errors.
- **Overall gap:** country gaps pooled in a random-effects meta-analysis.
- **Sex differences:** the same models run separately for men and women (adjusted for age). Whether the gap differs between women and men was tested with a minority status × sex interaction in each country, pooled across countries (90% CI, α = 0.10).
- **Country-level indicators:** multilevel models with individuals nested within countries, including random slopes for minority status and adjusted for age and sex, with an interaction between minority status and each country-level indicator. Government restrictions and social hostilities are also grouped into Pew Research Center's four categories.
- **Minority group size:** whether the gap varies with the size of each minority group's share of the national population.

**Sensitivity analyses**

- Excluding respondents reporting no religious denomination.
- Defining the majority as the largest religious group, rather than a group holding more than 50%.
- Random-effects meta-regressions of country gaps on country-level indicators, with country as the unit of analysis.

## Data

No data are included in this repository. The World Values Survey microdata are not redistributed, in line with the WVS terms of use. Aggregated outputs are also not included because they contain figures from the World Religion Database, which is available by subscription.

To reproduce the analyses you will need:

- World Values Survey Wave 7 cross-national file (free, registration required at [worldvaluessurvey.org](https://www.worldvaluessurvey.org))
- World Religion Database (2020) national religious composition (subscription required)
- Pew Research Center Government Restrictions Index and Social Hostilities Index (publicly available)
- Polity democracy scores (publicly available)
- World Bank GDP per capita and Gini index (publicly available)

## Reproducing

Place the data files in the same folder as the scripts, then:

1.  Run `analysis/Pre-processing.R` to build the cleaned dataset (`data.rds`).
2.  Knit `analysis/Main analyses.Rmd`. This runs the main analyses and saves `data_analytic.rds` and `dashboard_model_outputs.rds` for the dashboard.
3.  Knit the sensitivity analysis scripts.
4.  Knit `prepare_dashboard_data.Rmd`, which writes `data/dashboard_data.rds` and `data/country_gaps.csv`.
5.  Run the app: `shiny::runApp()`

The results can be explored without any of these steps in the [live app](https://jasminecylee.shinyapps.io/religious-min-maj-health-wellbeing/).

## Dashboard

The dashboard has four pages:

- **Overall gap:** the overall minority–majority gap, a map of the gap in each country, and each country's gap with its 95% confidence interval
- **Country profile:** a single country's religious composition, group means, and minority–majority gap
- **Sex differences:** the gap for men and women separately, overall and in each country
- **Country-level indicators:** how the gap varies with government restrictions, social hostilities, democracy, GDP per capita, and income inequality

## Notes and caveats

- Gaps are adjusted for age and sex only and should not be interpreted causally.
- Religious minorities are more likely to leave the outcome items blank, so observed differences are likely conservative.
- Minority groups are pooled within each country and are not directly comparable across countries.
- Majority status is defined from national religious demography, so a group's share of the survey sample may differ from its share of the national population.
- Country gaps and descriptive means use survey sampling weights; multilevel models are unweighted and adjusted for age and sex.

## Data sources

- World Values Survey Wave 7 (2017–2022). Haerpfer, C., Inglehart, R., Moreno, A., et al. (eds.). Madrid & Vienna: JD Systems Institute & WVSA Secretariat.
- National religious composition: World Religion Database (2020).
- Government Restrictions Index and Social Hostilities Index: Pew Research Center.
- Democracy: Polity.
- GDP per capita and Gini index: World Bank.

## Contact

Jasmine Lee, Centre for Longitudinal Studies, University College London: [jasmine.lee.22\@ucl.ac.uk](mailto:jasmine.lee.22@ucl.ac.uk){.email}

## Licence

Code released under the MIT Licence. The World Values Survey and World Religion Database data are subject to their respective terms of use and are not redistributed here.
