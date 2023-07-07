# TODO Femi

# Complete the following two tasks, preparing datasets that are safe to be 
# released from the server.
# 1. Summarise the following variables in a table:
#    age_2, sex, *_group, region, death_date (range of dates, number of missing dates)
# 2. Summarise the distribution of dates of first dose by jcvi group (covid_vax_disease_1_date)

# The following resources might be useful for making sure outputs are safe:
# https://docs.opensafely.org/releasing-files/
# The roundmid_any function in the following file:
library(tidyverse)
library(here)

source(here::here("analysis", "functions", "utility.R"))

data_processed <- read_rds(here("output", "extract", "data_processed.rds"))
