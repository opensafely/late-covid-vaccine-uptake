library(tidyverse)
library(here)
library(gtsummary) # package for creating nice tables

source(here::here("analysis", "functions", "utility.R"))

data_processed <- read_rds(here("output", "extract", "data_processed.rds"))

# create a summary table of age_2 and sex
table1 <- data_processed %>%
  tbl_summary(
    # specify the columns to summarise
    include = c(age_2, sex)
  )

# print table1 in viewer
table1

# see raw data for table1
table1$meta_data %>%
  select(var_label, df_stats) %>%
  unnest(df_stats)

# you can see here that the function gtsummary::tbl_summary() automatically 
# detects the type of column, and calculates the relevant statistics

# TODO
# try adding more columns to the summary table
