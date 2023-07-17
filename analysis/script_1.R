library(tidyverse)
library(here)

# read data_eligible
data_eligible <- read_rds(here("output", "extract", "data_eligible.rds"))

# TODO
# - create variable called covid_vax_disease_1_time which is the days between elig_date and covid_vax_disease_1_date
# - do the same for death_date and dereg_date (i.e. time since elig_date)
# - check that there are no negative values for death_time and dereg_time (there shouldn't be, because we've excluded people who died or deregistered before elig_date)
# - for each unique value of elig_date, plot the distribution of covid_vax_disease_1_time (ggplot::facet_wrap() might be useful here)
# - count how many patients there are in the following subgroups:
#   - imd_Q5 x ethnicity
#   - imd_Q5 x ethnicity x sex
#   - imd_Q5 x ethnicity x region
#   - imd_Q5 x ethnicity x jcvi_group