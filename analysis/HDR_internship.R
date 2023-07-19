# Set the work directory 
setwd("C:/Users/Femi/Documents/late-covid-vaccine-uptake")

# Load libraries
library(arrow)
library(dplyr)
library(tidyr)
library(lubridate)
library(purrr)
library(gtsummary)
library(ggplot2)


# Import the data 
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
  geom_freqpoly(binwidth = 1) +
  facet_wrap(~jcvi_group) +
  theme_minimal() +
  labs(title = "Distribution of covid_vax_disease_1_time across different eligibility dates",
       x = "Days between eligibility and first vaccination",
       y = "Frequency",
       color = "Eligibility Date")


###Count how many patients there are in the imd subgroups by ethnicity


# imd_Q5 x ethnicity
data_eligible %>%
  group_by(imd_Q5, ethnicity) %>%
  summarise(n = n(), .groups = "drop")

# imd_Q5 x ethnicity x sex
data_eligible %>%
  group_by(imd_Q5, ethnicity, sex) %>%
  summarise(n = n(), .groups = "drop")

# imd_Q5 x ethnicity x region
data_eligible %>%
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


# imd_Q5 x ethnicity x jcvi_group
table4 <- data_eligible %>%
  tbl_cross(row = imd_Q5, col = list(ethnicity, jcvi_group))
table4

# Print the tables
table1
table2
table3
table4



