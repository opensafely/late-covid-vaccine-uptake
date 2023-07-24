# read data_eligible
#data_eligible <- read_rds(here("output", "extract", "data_eligible.rds"))

# TODO
# - create variable called covid_vax_disease_1_time which is the days between elig_date and covid_vax_disease_1_date
# - do the same for death_date and dereg_date (i.e. time since elig_date)
# - check that there are no negative values for death_time and dereg_time (there shouldn't be, because we've excluded people who died or deregistered before elig_date)
# - plot the distribution of covid_vax_disease_1_time across different eligibility dates 
#   (I'd recommend using ggplot2::facet_wrap() to create a separate panel per jcvi_group, and ggplot2::geom_freqpoly() with colour=elig_date to stratify by elig_date within jcvi_group)
# - count how many patients there are in the following subgroups:
#   - imd_Q5 x ethnicity
#   - imd_Q5 x ethnicity x sex
#   - imd_Q5 x ethnicity x region
#   - imd_Q5 x ethnicity x jcvi_group

# Load libraries
library(arrow)
library(dplyr)
library(tidyr)
library(lubridate)
library(purrr)
library(gtsummary)
library(ggplot2)
library(viridis)
library(here)



# create output directory
outdir <- here::here("output", "exploratory")
fs::dir_create(outdir)

# source metadata and functions
source(here::here("analysis", "design.R"))
source(here::here("analysis", "functions", "utility.R"))

# Import the data 
#data_eligible <- readRDS(here::here("output", "extract", "data_eligible.rds"))
data_eligible <- readRDS("~/late-covid-vaccine-uptake/output/extract/data_eligible.rds")

# Sumarry of the data
summary(data_eligible)

# Check data types 
str(data_eligible)


#########
#########
### TODO
#########
#########

# Create covid_vax_disease_1_time which is the days between elig_date and covid_vax_disease_1_date
data_eligible <- data_eligible %>%
  mutate(covid_vax_disease_1_time = as.numeric(difftime(covid_vax_disease_1_date, elig_date, units = "days")))

# Death_date and dereg_date (i.e. time since elig_date)
data_eligible <- data_eligible %>%
  mutate(death_time = as.numeric(difftime(death_date, elig_date, units = "days")),
         dereg_time = as.numeric(difftime(dereg_date, elig_date, units = "days")))


# Check that there are no negative values for death_time and dereg_time
sum(data_eligible$death_time < 0, na.rm = TRUE) # should be 0
sum(data_eligible$dereg_time < 0, na.rm = TRUE) # should be 0



# Plot the distribution of covid_vax_disease_1_time across different eligibility dates
ggplot(data_eligible, aes(x = covid_vax_disease_1_time, color = elig_date)) +
  
  # first, derive a variable that corresponds to the rank of elig_date within jcvi_group
  # this will make it easier to plot  with a nice colour scheme
  # in the plot we don't need to know what the eligibility date is, 
  # we just want to make sure we can distinguish between them
data_elig_date_rank <- data_eligible %>%
  distinct(jcvi_group, elig_date) %>%
  arrange(jcvi_group, elig_date) %>%
  group_by(jcvi_group) %>%
  mutate(elig_date_rank = factor(rank(elig_date))) %>%
  ungroup()

# now create the plot
data_eligible %>%
  left_join(data_elig_date_rank, by = join_by(elig_date, jcvi_group)) %>%
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
# We don't usually release plots from opensafely, as often we want to have the 
# freedom to tweak the appearance locally. Therefore, we usually create datasets
# that are safe to release, that can be used to replicate the plot locally.
# In this case, we want a dataset that has a column corresponding to the number of
# individuals vaccinated on each day, grouped by jcvi_group and elig_date. 
# We then need to use roundmid_any() (see analysis/functions/utility.R) to apply
# rounding so that the counts are safe to release. 
# Please let me know if you have any questions about this task!
# Note: I've applied roundmid_any() in line 145 below, so see this as an example.

###Count how many patients there are in the imd subgroups by ethnicity


# imd_Q5 x ethnicity

data_eligible %>%
data_imd_eth <- data_eligible %>%
  group_by(imd_Q5, ethnicity) %>%
  summarise(n = n(), .groups = "drop")

# imd_Q5 x ethnicity x sex

data_eligible %>%
data_imd_eth_sex <- data_eligible %>%
  group_by(imd_Q5, ethnicity, sex) %>%
  summarise(n = n(), .groups = "drop")

# imd_Q5 x ethnicity x region

data_eligible %>%
data_imd_eth_reg <- data_eligible %>%
  group_by(imd_Q5, ethnicity, region) %>%
  summarise(n = n(), .groups = "drop")

# imd_Q5 x ethnicity x jcvi_group

data_eligible %>%
  group_by(imd_Q5, ethnicity, jcvi_group) %>%
  summarise(n = n(), .groups = "drop")


### alternative try
# imd_Q5 x ethnicity
table1 <- data_eligible %>%
  tbl_cross(row = imd_Q5, col = ethnicity, sex)
table1
# imd_Q5 x ethnicity x sex
table2 <- data_eligible %>%
  tbl_cross(row = imd_Q5, col = list(ethnicity, sex))
table2

# imd_Q5 x ethnicity x region
table3 <- data_eligible %>%
  tbl_cross(row = imd_Q5, col = list(ethnicity, region))
table3

data_imd_eth_jcvi <- data_eligible %>%
  group_by(imd_Q5, ethnicity, jcvi_group) %>%
  summarise(n = n(), .groups = "drop")

# bind these together and save as csv file so we can release from opensafely
data_counts <- bind_rows(
  data_imd_eth %>% mutate(variable = NA_character_, level = NA_character_),
  data_imd_eth_sex %>% mutate(variable = "sex") %>% rename(level = sex),
  data_imd_eth_reg %>% mutate(variable = "region") %>% rename(level = region),
  data_imd_eth_jcvi %>% mutate(variable = "jcvi_group") %>% rename(level = jcvi_group)
) %>%
  # we round the counts using midpoint rounding to reduce risk of secondary disclosure
  # threshold is defined in design.R
  mutate(across(n, ~roundmid_any(.x, to = threshold)))

# save to .csv file for release
data_counts %>%
  readr::write_csv(file.path(outdir, "group_counts.csv"))

# tbl_cross() will be useful when we've extracted the results from opensafely
# and want to summarise them for a paper, but for now we'll save all results
# as .csv files.
# ### alternative try
# # imd_Q5 x ethnicity
# table1 <- data_eligible %>%
#   filter(sex=="M") %>%
#   tbl_cross(row = imd_Q5, col = ethnicity)
# table1
# # imd_Q5 x ethnicity x sex
# table2 <- data_eligible %>%
#   tbl_cross(row = imd_Q5, col = list(ethnicity, sex))
# table2
# 
# 
# # imd_Q5 x ethnicity x region
# table3 <- data_eligible %>%
#   tbl_cross(row = imd_Q5, col = list(ethnicity, region))
# table3
