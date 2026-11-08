# PRE-PROCESSING FILE
# This script combines data from both World Values Survey Wave 7 (2017-2022) and World Religion Database 2020 demographics.

## ** Note to self: At the moment we already have religious restriction indices and government hostilities values within the wrd dataset. If necessary, I will pre-process Pew Research religion dataset to extract the indices for each country's data collection years. (Double check whether there is discrepancy)



#--------------------------- LOAD LIBRARIES AND DATA ---------------------------
# Load necessary libraries
library(dplyr)
library(tidyverse)
library(countrycode)
library(gt)
library(officer)
library(flextable)
library(tidyr)

# World Values Survey round 7 data
data <- read.csv("WVS_Cross-National_Wave_7_spss_v6_0.csv")

# World Religion Database (WRD)
wrd <- read.csv("WRD_religion_demographics.csv") 

# Pew religious restrictions index
pew <- read.csv("Pew_ReligiousRestrictions_2007to2022.csv")
pew %>% colnames()

# Select variables of interest - include variables potentially related to minorities specifically
pew <- pew %>% select(Ctry_EditorialName, Question_Year, GRI, SHI, GRI_Q_11, GRI_Q_11_Unaffiliated, GRI_Q_11_Christianity, GRI_Q_11_Islam, GRI_Q_11_Buddhism, GRI_Q_11_Hinduism, GRI_Q_11_Judaism, GRI_Q_11_Other_Religions, GRI_Q_11_Folk_Religions, GRI_Q_12, GRI_Q_15, GRI_Q_17, GRI_Q_19, GRI_Q_20_1, GRI_Q_20_2, GRI_Q_20_3, SHI_Q_1_Harass_Unaffiliated, SHI_Q_1_Harass_Christianity, SHI_Q_1_Harass_Islam, SHI_Q_1_Harass_Buddhism, SHI_Q_1_Harass_Hinduism, SHI_Q_1_Harass_Judaism, SHI_Q_1_Harass_Other_Religions, SHI_Q_1_Harass_Folk_Religions, SHI_Q_7, SHI_Q_8, SHI_Q_10) %>% 
  rename(
    country = Ctry_EditorialName,
    year = Question_Year,
  ) %>%
  rename_with(~ sub("^GRI", "gri", .x), starts_with("GRI")) %>%
  rename_with(~ sub("^SHI", "shi", .x), starts_with("SHI"))
## We also have gri and shi from WRD, but the original dataset is Pew and more accurate

# Polity democracy indices (only up to 2018) 
polity <- read.csv("Polity_Democracy.csv")
polity <- polity %>% select(scode, country, year, polity)
polity <- polity %>%
  mutate(
    polity = ifelse(polity %in% c(-77, -66, -88), NA, polity) # Remove missing values
  )
# World Bank Catalog: GDP per capita & Gini index - constant 2021 international $

## GDP per capita 
readLines("GDP_PPP_constant2021_WorldBank.csv", n = 10) # Includes metadata rows 
gdp <- read_csv("GDP_PPP_constant2021_WorldBank.csv", skip = 4)
gdp <- gdp %>%
  select(`Country Name`, `Country Code`, `2016`, `2017`, `2018`,`2019`,`2020`,`2021`, `2022`) %>%
  rename(
    country = `Country Name`,
    iso3c = `Country Code`, 
    gdp_2016 = `2016`,
    gdp_2017 = `2017`,
    gdp_2018 = `2018`,
    gdp_2019 = `2019`,
    gdp_2020 = `2020`,
    gdp_2021 = `2021`,
    gdp_2022 = `2022`
  )

## Gini index
readLines("Gini_WorldBank.csv", n = 10) # Includes metadata rows 
gini <- read_csv("Gini_WorldBank.csv", skip = 4)
gini <- gini %>% 
  select(`Country Name`, `Country Code`, `2016`, `2017`, `2018`,`2019`,`2020`,`2021`, `2022`) %>%
  rename(
    country = `Country Name`,
    iso3c = `Country Code`, 
    gini_2016 = `2016`,
    gini_2017 = `2017`,
    gini_2018 = `2018`,
    gini_2019 = `2019`,
    gini_2020 = `2020`,
    gini_2021 = `2021`,
    gini_2022 = `2022`
  )
# We have gdp per capita (PPP constant 2021 international %) and gini from years 2017-2022, in case we decide to match the year of macropredictors to data collection year

# Check data structure
# data %>% view()
# wrd %>% view()
# gdp %>% view()
# gini %>% view()

data %>% colnames()
wrd %>% colnames()
gdp %>% colnames()
gini %>% colnames()


#-------------------------- RENAME & SELECT VARIABLES --------------------------

## ---- Rename key variables ----
data <- data %>% rename( 
  country_code = B_COUNTRY_ALPHA,   # Country code: B_COUNTRY_ALPHA
  respondent_id = S007,             # Respondent number: S007
  survey_year = A_YEAR,             # Survey year: A_YEAR
  survey_weight = W_WEIGHT,         # Survey weights
  age = Q262,                       # Age: Q262
  sex = Q260,                       # Sex: Q260
  religion = Q289,                  # Religion: Q289
  religion_detailed = Q289CS9,      # Detailed religion: Q289CS9
  life_satisfaction = Q49,          # Life satisfaction: Q49
  happiness = Q46,                  # Happiness: Q46
  health = Q47,                     # Subjective health: Q47 (extra info)
  gender_inequality = GII,          # Gender inequality index (GII) (UNDP, 2018)
  human_development = hdi          # Human development index (HDI) (UNDP, 2018)
)

## ---- Correct religion variable ----

# Uzebkistan codes are miscoded for religion - detailed religion codes starting with 5 e.g. 50101000 refer to Islam but are mis-coded as Catholic
data <- data %>% 
  mutate(
    detailed_major = case_when(
      religion_detailed >= 100000000 ~ 0L, # no denomination codes
      religion_detailed > 0 ~ as.integer(religion_detailed %/% 10000000),
      .default = NA_integer_
    ),
    religion = if_else(country_code == "UZB" & !is.na(detailed_major),
                       detailed_major, religion)
  )

## ---- Recode outcome variables ----

# In life satisfaction, 1 is completely dissatisfied, and 10 is completely satisfied.
# However for happiness, 1 is coded as very happy, and 4 not at all happy which is confusing
# Same for health, 1 is very good, 5 is very poor
data <- data %>% 
  mutate(
    happiness = case_when(
      happiness == 1 ~ 4,
      happiness == 2 ~ 3,
      happiness == 3 ~ 2,
      happiness == 4 ~ 1,
      .default = NA_real_
    ),
    health = case_when(
      health == 1 ~ 5,
      health == 2 ~ 4,
      health == 3 ~ 3,
      health == 4 ~ 2,
      health == 5 ~ 1,
      .default = NA_real_
    ),
    life_satisfaction = if_else(
      life_satisfaction %in% 1:10, life_satisfaction, NA_real_
    )
  )
# Now all flipped! Happiness: 1 not at all happy, 4 is very happy. Health: 1 very poor, 5 very good. Life satisfaciton between 1-10. Negative codes removed
# This makes it easier to interpret the results later on (higher values = better outcomes)


## ---- Rename religion  variables ----

# Recode variable levels
data <- data %>% 
  mutate(
    religion = case_when (
      religion == 0 ~ "No_Denomination",
      religion == 1 ~ "Catholic",
      religion == 2 ~ "Protestant",
      religion == 3 ~ "Orthodox",
      religion == 4 ~ "Jew",
      religion == 5 ~ "Muslim",
      religion == 6 ~ "Hindu",
      religion == 7 ~ "Buddhist",
      religion == 8 ~ "Other_Christian",
      religion == 9 ~ "Other",
      .default = NA_character_
    )
  )

data$religion %>% table(useNA = "ifany") 
## Across all countries, highest number of no denomination (22971), followed by Muslim (25184) and Catholic (18779)

# Group Christian denominations together
data <- data %>% 
  mutate(
    religion_broad = case_when(
      religion %in% c("Catholic", "Protestant", "Orthodox", "Other_Christian") ~ "Christian",
      .default = religion
    )
  )

data$religion_broad %>% table(useNA = "ifany") 
## When Christians grouped together, aross all countries, highest number is Christians (36704), followed by Muslims (25184) and no denomination (22971)

# Now, we have two religion variables: 'religion' which includes all major religions as coded in WVS, and "religion_broad" which groups all Christian denominations together


## ---- Combine Northern Ireland and the UK ----
# In WVS, Northern Ireland has separate data collected. However, in all country indicators NIR would be part of the UK, so for this analysis we will combine them

data <- data %>% 
  mutate(
    country_code = case_when(
      country_code == "NIR" ~ "GBR",
      .default = country_code
    )
  )

# Select relevant data
data <- data %>% select(
  country_code, respondent_id, survey_year, survey_weight, age, sex, religion, religion_broad, religion_detailed, life_satisfaction, happiness, health, gender_inequality, human_development
)
data %>% colnames()



#--------------------------- COMBINE DATASETS ----------------------------------

## ---- Standardise country names ----

# Country codes are different between data and wrd, so before combining we need to rename data$country_code first 
unique(data$country_code) # ISO codes e.g. MMR, ZWE

data <- data %>% 
  mutate(
    country = countrycode(
      country_code,
      origin = "iso3c",
      destination = "country.name"
    )
  )
data$country %>% table() 

wrd <- wrd %>% rename(
  country = country_name # Country numeric code
)
wrd$country %>% table()

# Remove any leading or trailing whitespace from country names in both datasets
data <- data %>%
  mutate(country = stringr::str_squish(country))
wrd <- wrd %>%
  mutate(country = stringr::str_squish(country))

# Rename Viet Nam to Vietnam, Myanmar to Myanmar (Burma), Macao to Macao SAR China so wrd and mean 
wrd <- wrd %>%
  mutate(
    country = case_when(
      country == "Viet Nam" ~ "Vietnam",
      country == "Myanmar" ~ "Myanmar (Burma)",
      country == "Macao" ~ "Macao SAR China",
      country == "Hong Kong" ~ "Hong Kong SAR China", 
      .default = country
    )
  )
# Double check names
# wrd$country %>% table()


## ---- Combine wrd and data ----

data <- data %>% left_join(wrd, by = "country")
data %>% colnames()

## ---- Combine data with democracy ----
polity$country %>% unique()

# Filter to 2015 onwards, don't need all the prevous years 
polity <- polity %>% filter(year > 2015)

# Pivot wider 
polity <- polity %>% pivot_wider(names_from = year, values_from = polity, names_prefix = "democracy_")

# Need to match country code with datato combine the data 
polity <- polity %>% rename(country_code = scode)
polity <- polity %>% filter(country_code != "KOS") %>% mutate(
  country_code = countrycode(country_code, origin = "p4c", destination = "iso3c")
) # Kosovo doesn't match well so can remove 
polity <- polity %>% select(-country)

# Combine datasets
data <- data %>% left_join(polity, by = "country_code")

data %>% colnames()
data <- data %>% select(country, everything()) # Reorder to have country first


## ---- Combine data with gdp and gini ----

# Rename iso3c to country code
data$country_code %>% unique()

gdp <- gdp %>% rename(country_code = iso3c)
gini <- gini %>% rename(country_code = iso3c)

data <- data %>% left_join(gdp %>% select(-country), by = "country_code")
data <- data %>% left_join(gini %>% select(-country), by = "country_code")


## ---- Combine pew data ----
# For Pew, filter to 2016 onwards only 
pew %>% head()
pew <- pew %>% filter(year > 2015)

# Rename countries 
pew <- pew %>% mutate(
  country = case_when(
    country == "Czech Republic" ~ "Czechia",
    country == "Myanmar" ~ "Myanmar (Burma)",
    country == "Macao" ~ "Macao SAR China",
    country == "Hong Kong" ~ "Hong Kong SAR China", 
    .default = country
  )
)

# Pivot wider 
pew <- pew %>% pivot_wider(names_from = year, values_from = -c(country, year), names_sep = "_")
                           
# Puerto Rico missing 

# Combine data
data <- data %>% left_join(pew, by = "country")
# data %>% view()




#--------------------------- MATCH MACRO-PREDICTOR TO YEAR BEFORE DATA COLLECTION ------------------
# For each country, we want to match the macro-predictor data (shi, gri, gdp, gini, democracy) 

data$survey_year %>% unique() # 2017-2023 

# Each country was surveyed in a different year, we want the macro-predictor to be from the year of data collection. 
# If missing, try the year before, up to 5 years before (for gini/democracy only)


## ---- Convert to long data ----
# Clean country strings (prevents join mismatches) 
data <- data %>%
  mutate(country = str_squish(country))

# Convert 
macro_long <- data %>%
  select(country, matches("^(gdp|gini|democracy|gri|shi).*_20\\d{2}$")) %>%
  distinct() %>%
  pivot_longer(
    cols = -country,
    names_to = c("var", "year"),
    names_pattern = "^(.*)_(20\\d{2})$",
    values_to = "value"
  ) %>%
  mutate(year = as.numeric(year)) %>%
  pivot_wider(
    names_from = var,
    values_from = value
  ) %>%
  mutate(country = str_squish(country)) %>%
  distinct(country, year, .keep_all = TRUE)


## ---- Function to match ----
# COUNTRY x SURVEY_YEAR level, then join to individuals

match_country_year <- function(key, macro_long, offsets = c(0, -1), vars) {
  stopifnot(all(c("country","year") %in% names(macro_long)))
  stopifnot(all(vars %in% names(macro_long)))
  
  candidates <- tidyr::crossing(key, offset_used = offsets) %>%
    mutate(year = survey_year + offset_used) %>%
    left_join(
      macro_long %>% distinct(country, year, .keep_all = TRUE),
      by = c("country", "year")
    ) %>%
    arrange(country, survey_year, offset_used) # 0, -1, -2...
  
  candidates %>%
    group_by(country, survey_year) %>%
    summarise(
      across(
        all_of(vars),
        ~ dplyr::first(na.omit(.x)),
        .names = "{.col}_matched"
      ),
      across(
        all_of(vars),
        ~ dplyr::first(offset_used[!is.na(.x)]),
        .names = "{.col}_offset_used"
      ),
      .groups = "drop"
    )
}

# Build country-year key
key <- data %>% distinct(country, survey_year)


## ---- Match: year-of OR year-before ----
macro_vars <- names(macro_long) %>%
  .[grepl("^(gdp|gini|democracy|gri|shi)", .)]

matched_all <- match_country_year(
  key = key,
  macro_long = macro_long,
  offsets = c(0, -1), # year of survey or year before
  vars = macro_vars
)

# Join back to individual-level data (override any previous matched cols)
data <- data %>%
  select(-matches("^(gdp|gini|democracy|gri|shi).*_(matched|offset_used)(\\.|$)")) %>%
  left_join(matched_all, by = c("country", "survey_year"))

# Check created columns
names(data)[grepl("_(matched|offset_used)$", names(data))]

# Check how many matched year of vs year before
offset_cols <- names(data)[grepl("_(offset_used)$", names(data))]

lapply(data[offset_cols], table, useNA = "ifany")
# Still a lot missing for gini and democracy

### ---- Verify values are identical within country and year ----
data %>%
  group_by(country, survey_year) %>%
  summarise(
    n_gdp = n_distinct(gdp_matched),
    n_gri = n_distinct(gri_matched),
    n_shi = n_distinct(shi_matched),
    n_gini = n_distinct(gini_matched),
    n_dem = n_distinct(democracy_matched),
    .groups = "drop"
  ) %>%
  filter(n_gdp > 1 | n_gri > 1 | n_shi > 1 | n_gini > 1 | n_dem > 1) %>%
  arrange(country, survey_year)
# 0 rows - no mismatches!

### ---- Check number of countries missing for each indicator ----
matched_cols <- names(data)[grepl("_matched$", names(data))]

data %>%
  distinct(country, across(all_of(matched_cols))) %>%
  summarise(
    across(
      all_of(matched_cols),
      ~ sum(is.na(.)),
      .names = "n_missing_{.col}"
    )
  )
# GRI: 1 
# SHI: 1 
# GDP: 2
# Gini: 22
# Democracy: 31
# All individual GRI and SHi variables: 1


## ---- Match again for gini and democracy only (wider window up to 5 years back) ----
macro_long_gd <- macro_long %>%
  select(country, year, gini, democracy) %>%
  distinct(country, year, .keep_all = TRUE)

matched_gd <- match_country_year(
  key = key,
  macro_long = macro_long_gd,
  offsets = 0:-5, # from year of collection to up to 5 years back 
  vars = c("gini", "democracy")
)

# After matching again, check missingness at country-year level
matched_gd %>%
  summarise(
    n_country_year = n(),
    missing_gini = sum(is.na(gini_matched)),
    missing_dem = sum(is.na(democracy_matched))
  )
# Gini: 18 (matched 4 extra)
# Democracy: 6 (matched 25 extra)

# Check how far back you went (offsets used)
matched_gd %>% count(gini_offset_used, sort = TRUE) # For 7 countries had to go 5 years back 
matched_gd %>% count(democracy_offset_used, sort = TRUE) # For 11 countries had to go 5 years back

# Override gini/democracy matched in individual-level data with the wider-window versions
data <- data %>%
  select(-matches("^(gini|democracy)_(matched|offset_used)(\\.|$)")) %>%
  left_join(matched_gd, by = c("country", "survey_year"))



## ---- Check missingness ----
data %>% colnames()
data$gri_matched %>% summary()

### ---- Check how many countries are missing on which indicator (based on MATCHED vars) ----
countries_indicator_missing <- data %>%
  distinct(country, gdp_matched, gini_matched, democracy_matched, gri_matched, shi_matched) %>%
  summarise(
    gini_missing_countries = sum(is.na(gini_matched)),
    democracy_missing_countries = sum(is.na(democracy_matched)),
    shi_missing_countries = sum(is.na(shi_matched)),
    gri_missing_countries = sum(is.na(gri_matched)),
    gdp_missing_countries = sum(is.na(gdp_matched))
  )

countries_indicator_missing
# Overall, missingless levels:
# GRI: 1
# SHI: 1 
# GDP: 2
# Gini: 18
# Democracy: 6


data %>% colnames()

# Remove intermediary variables, keeping only final matched variables
data <- data %>%
  select(
    -matches("^(democracy|gdp|gini|gri|shi)_20"),
    -matches("_offset_used$")
  )


## Now, we have matched variables for all macro-predictors - either from the year of data collection, or up to 5 years before if missing.

## For GRI and SHI, we also have specific items for each year that may be selected as individual questions regarding minorities specifically.




#--------------------------- CLEAN & CHECK RELIGION VARIABLES ------------------

## ---- Standardise religion categories ----

# WVS religions: Christian, Muslim, Hindu, Buddhist, Jew, No_Denomination, Other
# WRD variables need to be regrouped: christian_pct, muslim_pct, hindu_pct, buddhist_pct, jew_pct, agnostic_pct & atheist_pct (No_Denomination), all others (Other)

# For those who put 'other' religion in WVS, there are detailed categorisations of the church in religion_detailed
data %>% 
  filter(religion_broad == "Other") %>%
  select(religion_detailed) %>%
  distinct() %>%
  arrange(religion_detailed)

# 90000000: Other
# 90101000: Taoism
# 90102000: Confucianists
# 90103000: Yiguandao
# 90104000: Xuanyuan jiao
# 90105000: Cihui Tang
# 90200000: Ethnic religions, excluding some in separate categories; nfd
# 90201040: Igbo
# 90201115: Wicca-Pagan Witchcraft
# 90202020: Shinto, Animism
# 90202110: Korean shamanism or Sinism
# 90202120: Mandaeism
# 90205040: The Satanic Temple
# 90300000: African traditional religions Ethnic, nfd
# 90400000: Sikhism
# 90500000: Spiritism
# 90700000: Jainism
# 90800000: Neo-paganism

# Religions overlapping between religion_detailed and WRD demographics (other than broad religions): daoist, confucianist, ethnic_religionist, jain, shintoist, sikh, spiritist

# religion_detailed is only used when individuals are not affiliated to religion_broad religions


## ---- Create new religion_wrd variable including smaller religions ----

data <- data %>%
  mutate(
    religion_wrd = case_when(
      religion_broad == "Christian" ~ "Christian",
      religion_broad == "Muslim" ~ "Muslim",
      religion_broad == "Hindu" ~ "Hindu",
      religion_broad == "Buddhist" ~ "Buddhist",
      religion_broad == "Jew" ~ "Jew",
      religion_broad == "No_Denomination" ~ "No_Denomination",

      # Handle "Other" via detailed religion
      religion_detailed == 90101000 ~ "Daoist",
      religion_detailed == 90102000 ~ "Confucianist",
      religion_detailed == 90200000 ~ "Ethnic_religionist",
      religion_detailed == 90202020 ~ "Shintoist",
      religion_detailed == 90400000 ~ "Sikh",
      religion_detailed == 90500000 ~ "Spiritist",
      religion_detailed == 90700000 ~ "Jain",
      religion_detailed %in% c(90103000, 90104000, 90105000) ~ "Chinese_folk_religionist",
      religion_detailed %in% c(90201040, 90201115, 90202110, 90202120, 90205040, 90300000, 90800000, 90000000) ~ "Other",
      
      # All remaining Other religions
      religion_broad == "Other" ~ "Other",
      
      .default = NA_character_
    )
  )


## ---- Checking WRD demographics categories ----

data %>% colnames()
# For WRD demographics, need to create no_denomination and other categories correspondingly

# Combine atheist and agnostic into no denomination for WRD demographics, other religions include those not already mapped
data <- data %>%
  mutate(
    no_denomination_pct = atheist_pct + agnostic_pct, 
    
    other_religion_pct =  new_religionist_pct +
      bahai_pct +
      zoroastrian_pct)




#-------------------------- MISSINGNESS --------------------------

data %>%
  summarise(
    n_total = n(),
    
    # Missing on key variables
    miss_religion  = sum(is.na(religion)), # religion is a character 
    pct_religion   = round(mean(is.na(religion)) * 100, 2),
    
    miss_age       = sum(age < 0),
    pct_age        = round(mean(age < 0) * 100, 2),
    
    miss_sex       = sum(sex < 0),
    pct_sex        = round(mean(sex < 0) * 100, 2),
    
    # Missing on each outcome
    miss_ls        = sum(life_satisfaction < 0),
    pct_ls         = round(mean(life_satisfaction < 0) * 100, 2),
    
    miss_happy     = sum(is.na(happiness)),
    pct_happy      = round(mean(is.na(happiness)) * 100, 2),
    
    miss_health    = sum(is.na(health)),
    pct_health     = round(mean(is.na(health)) * 100, 2),
  )
# Very low missingness - religion 1.4%, age 0.53%, sex 0.1%, life satisfaction - 0.53%, happiness 1.4%, health 0.27%
# Only 0.08% missing on all three outcomes 


## ---- Remove non-responses ----
# For each of the variables, make sure all non-responses are removed (i.e. negative values: -1 don't know, -2 no answer, -4 not asked, -5 other missing)

# Keep only those who have complete data for exposure (religion - need to classify majority/minority) and confounders (age and sex)
data <- data %>%
  filter(!is.na(religion), age >= 0, sex >= 0)

# Remove -9999 i.e. NA
data <- data %>%
  mutate(
    gender_inequality = na_if(gender_inequality, -9999),
    human_development = na_if(human_development, -9999)
  )


## ---- Sample size ----

data %>% nrow() # Sample size: 95,346

data$country %>% n_distinct() 
# Country sample size: 65 
# After combining Northern Ireland with Great Britain


# Sample size per country
country_sample_sizes <- data %>%
  group_by(country) %>%
  summarise(sample_size = n()) %>% 
  arrange(desc(sample_size))
country_sample_sizes %>% print(n=65) # Ranging from 812 (Macao) and 958 (New Zealand) to Indonesia (3200) and 4018 (Canada)



## ---- Country characteristics ----

# Check age summary for each country
country_age_summary <- data %>%
  group_by(country) %>%
  filter(age >=0) %>%  # Remove negative values (non-response)
  summarise(
    min_age = min(age, na.rm = TRUE),
    max_age = max(age, na.rm = TRUE),
    mean_age = mean(age, na.rm = TRUE),
    median_age = median(age, na.rm = TRUE)
  )
country_age_summary %>% print(n=65)
## Ages range from 18 to 103, median generally around 35-45


# Check sex split for each country
country_sex_split <- data %>%
  filter(sex %in% c(1, 2)) %>%       
  group_by(country, sex) %>%
  summarise(count = n(), .groups = "drop_last") %>%
  mutate(pct = count / sum(count) * 100) %>%
  ungroup() %>%
  select(country, sex, pct) %>%        
  pivot_wider(
    names_from = sex,
    values_from = pct,
    values_fill = 0
  ) %>%
  rename(
    Male = `1`,
    Female = `2`
  )
country_sex_split %>% print(n=65)
## Most countries are roughly evenly split, except Armenia (69% female), Kyrgyzstan (62% female), Puerto Rico (61% female), Romania (60%), Russia (60%), Ukraine (62%), and Uruguay (69% female)



#--------------------------- SAVE PRE-PROCESSED DATA ---------------------------

# Double check data 
# data %>% view()

# Save in R
saveRDS(data, "data.rds")

# Save as CSV
write.csv(data, "data.csv", row.names = FALSE, na = "")
