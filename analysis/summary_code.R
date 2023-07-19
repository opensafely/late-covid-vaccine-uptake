### Loading the required libraries
library(dplyr)
library(tidyr)
library(lubridate)
library(purrr)
library(gtsummary)


### Load the data
data_processed <- readRDS("~/late-covid-vaccine-uptake/output/extract/data_processed.rds")

### Check the summary stat for the dataset
summary(data_processed)
### Checking the data types in each column
str(data_processed)

### Summary of the objectives 
# create a summary table of age_2 and sex
table1 <- data_processed %>%
  tbl_summary(
    # specify the columns to summarise
    include = c(age_2, sex, region, death_date, cev_group, asthma_group, resp_group, cns_group, diab_group, sevment_group, chd_group, ckd_group, cld_group, immuno_group, spln_group, learndis_group, sevobese_group, atrisk_group, longres_group, preg_cev_group, preg_ar_group) #*_group, region, death_date
  )

# print table1 in viewer
table1


### Summary of the dristribution of first dose by JCVI grouping 
table2 <- data_processed %>%
  tbl_summary(
    # specify the columns to summarise
    include = c(covid_vax_disease_1_date),
    # group the data by jcvi groups 
    by = jcvi_group
  )

# print table1 in viewer
table2



### Going by the unique count of jcvi group we will create a grouping 
grouped_data <- data_processed %>%
  mutate(jcvi_group = ifelse(jcvi_group %in% c('06', '12', '10', '11', '05', '09'), as.character(jcvi_group), 'Other')) %>%
  group_by(jcvi_group)

grouped_counts <- grouped_data %>%
  summarise(count = n(), .groups = "drop")


### Table 3
### Summary of the dristribution of first dose by JCVI grouping 
table3 <- grouped_data %>%
  tbl_summary(
    # specify the columns to summarise
    include = c(covid_vax_disease_1_date),
    # group the data by jcvi groups 
    by = jcvi_group
  )

# print table1 in viewer
table3


###create age groupings for the data 
# Create age groups
data_processed <- data_processed %>%
  mutate(age_group = case_when(
    age_2 >= 18 & age_2 < 40 ~ "18-39",
    age_2 >= 40 & age_2 < 70 ~ "40-69",
    age_2 >= 70 & age_2 < 90 ~ "70-89",
    age_2 >= 90 ~ "90+"
  ))

# Group the data by age_group
grouped_data_age <- data_processed %>%
  group_by(age_group)


### table 4
### Summary of the dristribution of first dose by JCVI grouping 
# create a summary table of age_2 and sex
table4 <- data_processed %>%
  tbl_summary(
    # specify the columns to summarise
    include = c(sex, region, death_date, cev_group, asthma_group, resp_group, cns_group, diab_group, sevment_group, chd_group, ckd_group, cld_group, immuno_group, spln_group, learndis_group, sevobese_group, atrisk_group, longres_group, preg_cev_group, preg_ar_group),
    # group the data by age_groups 
    by = age_group
  )

# print table1 in viewer
table4

#########
########

# table 5 trying out uptake by ethnicity
### Summary of the dristribution of first dose by JCVI grouping 
table5 <- data %>%
  tbl_summary(
    # specify the columns to summarise
    include = c(status, age_group, region, sex),
    # group the data by jcvi groups 
    by = ethnicity
  )

# print table1 in viewer
table5


#######
#######
### testing survival analysis 
library(survival)



# Create a column indicating whether patient has been vaccinated within 12 weeks of eligibility
data <- data_processed %>%
  mutate(status = ifelse(covid_vax_disease_1_date - elig_date <= 84, 1, 0)) # 84 days = 12 weeks

# Compute the time to event or censoring
# We will use the dates of eligibility and covid vaccination.
# Note that we will convert the date to numeric
# We will also handle the cases where covid_vax_disease_1_date is NA using the max date as censoring date.

max_date <- max(na.omit(c(data$elig_date, data$covid_vax_disease_1_date)))

data <- data %>%
  mutate(
    time_to_event = ifelse(
      is.na(covid_vax_disease_1_date),
      as.numeric(max_date - elig_date),
      as.numeric(covid_vax_disease_1_date - elig_date)
    )
  )

# Now we can create the survival object for Kaplan-Meier analysis
surv_object <- Surv(time = data$time_to_event, event = data$status)

# survival estimates across various age groups 
kaplan_meier_fit <- survfit(surv_object ~ sex, data = data)

# Print survival estimates
print(kaplan_meier_fit)

# Kaplan-Meier curve with age groups
plot(kaplan_meier_fit, col=c(1:3), xlab = "Time", ylab = "Survival Probability", main = "Kaplan-Meier Curve by Age Groups")
legend("topright", legend = levels(data$jcvi_group), col = 1:3, lty = 1)


