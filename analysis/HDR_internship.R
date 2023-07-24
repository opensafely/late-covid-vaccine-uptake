# Load libraries
library(lubridate)
library(purrr)
library(gtsummary)
library(ggplot2)
library(viridis)
library(here)
library(fs)

# Create output directory
outdir <- here("output", "exploratory")
fs::dir_create(outdir)

# Source metadata and functions
source(here("analysis", "design.R"))
source(here("analysis", "functions", "utility.R"))

# Import the data 
data_eligible <- readRDS(here("output", "extract", "data_eligible.rds"))

# Summary of the data
summary(data_eligible)

# Create covid_vax_disease_1_time which is the days between elig_date and covid_vax_disease_1_date
data_eligible <- data_eligible %>%
  mutate(covid_vax_disease_1_time = as.integer(difftime(covid_vax_disease_1_date, elig_date, units = "days")))

# Death_date and dereg_date (i.e. time since elig_date)
data_eligible <- data_eligible %>%
  mutate(death_time = as.numeric(difftime(death_date, elig_date, units = "days")),
         dereg_time = as.numeric(difftime(dereg_date, elig_date, units = "days")))

# Check for negative times
sum(data_eligible$death_time < 0, na.rm = TRUE) # should be 0
sum(data_eligible$dereg_time < 0, na.rm = TRUE) # should be 0

# TODO Task 1
# replace any times > 182 days (26 weeks) with NA, as this is the end of follow-up
# (do this for covid_vax_disease_1_time, death_time, dereg_time)

# Derive a variable that corresponds to the rank of elig_date within jcvi_group
data_elig_date_rank <- data_eligible %>%
  distinct(jcvi_group, elig_date) %>%
  arrange(jcvi_group, elig_date) %>%
  group_by(jcvi_group) %>%
  mutate(elig_date_rank = factor(rank(elig_date))) %>%
  ungroup()

# Plot the distribution of covid_vax_disease_1_time across different eligibility dates
data_eligible %>%
  left_join(data_elig_date_rank, by = c("elig_date", "jcvi_group")) %>%
  ggplot(aes(x = covid_vax_disease_1_time, color = elig_date_rank)) +
  geom_freqpoly(binwidth = 1) +
  facet_wrap(~jcvi_group) +
  scale_color_viridis_d() +
  theme_minimal() +
  labs(title = "Distribution of covid_vax_disease_1_time across different eligibility dates",
       x = "Days between eligibility and first vaccination",
       y = "Frequency",
       color = "Eligibility Date")

# TODO Task 2
# Create a dataset that can be used to replicate the plot outside of opensafely.

# Count how many patients there are in the imd subgroups by ethnicity
data_imd_eth <- data_eligible %>%
  group_by(imd_Q5, ethnicity) %>%
  summarise(n = n(), .groups = "drop")

data_imd_eth_sex <- data_eligible %>%
  group_by(imd_Q5, ethnicity, sex) %>%
  summarise(n = n(), .groups = "drop")

data_imd_eth_reg <- data_eligible %>%
  group_by(imd_Q5, ethnicity, region) %>%
  summarise(n = n(), .groups = "drop")

data_imd_eth_jcvi <- data_eligible %>%
  group_by(imd_Q5, ethnicity, jcvi_group) %>%
  summarise(n = n(), .groups = "drop")

# Bind these together and save as csv file so we can release from opensafely
data_counts <- bind_rows(
  data_imd_eth %>% mutate(variable = NA_character_, level = NA_character_),
  data_imd_eth_sex %>% mutate(variable = "sex") %>% rename(level = sex),
  data_imd_eth_reg %>% mutate(variable = "region") %>% rename(level = region),
  data_imd_eth_jcvi %>% mutate(variable = "jcvi_group") %>% rename(level = jcvi_group)
) %>%
  # we round the counts using midpoint rounding to reduce risk of secondary disclosure
  # threshold is defined in design.R
  mutate(across(n, ~roundmid_any(.x, to = threshold)))

# Save to .csv file for release
readr::write_csv(data_counts, file.path(outdir, "group_counts.csv"))


# TODO Task 3

# Create a new dataset with counts of individuals vaccinated on each day, grouped by jcvi_group and elig_date
data_vax_counts <- data_eligible %>%
  group_by(jcvi_group, elig_date, covid_vax_disease_1_date) %>%
  summarise(n = n(), .groups = "drop") %>%
  mutate(n = roundmid_any(n, to = threshold))  # Apply rounding to the counts


head(data_vax_counts)

# Save to .csv file for release
readr::write_csv(data_counts, file.path(outdir, "data_vax_counts.csv"))



# Task 4 

# Create variable for the number of days between eligibility and vaccination
data_vax_counts$days_between <- as.integer(data_vax_counts$covid_vax_disease_1_date - data_vax_counts$elig_date)

# Derive a variable that corresponds to the rank of elig_date within jcvi_group for extracted dataset
data_count_date_rank <- data_vax_counts %>%
  distinct(jcvi_group, elig_date) %>%
  arrange(jcvi_group, elig_date) %>%
  group_by(jcvi_group) %>%
  mutate(elig_date_rank = factor(rank(elig_date))) %>%
  ungroup()

# Plot the distribution of covid_vax_disease_1_time across different eligibility dates for the extracted dataset 
data_vax_counts %>%
  left_join(data_count_date_rank, by = c("elig_date", "jcvi_group")) %>%
  ggplot(aes(x = days_between, y = n, color = elig_date_rank)) +
  geom_line() +
  facet_wrap(~jcvi_group) +
  scale_color_viridis_d() +
  theme_minimal() +
  labs(title = "Distribution of covid_vax_disease_1_date across different eligibility dates",
       x = "Days between eligibility and first vaccination",
       y = "Frequency",
       color = "Eligibility Date")











