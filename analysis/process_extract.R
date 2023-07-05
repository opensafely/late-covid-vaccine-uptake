# load libraries
library(tidyverse)
library(here)

# load design script
source(here("analysis", "design.R"))
source(here("analysis", "functions", "utility.R"))

# create output directory
dir_path <- here("output", "extract")

# load study definition extract
extract <- arrow::read_feather(file.path(dir_path, "input.feather"))

# don't execute if running on TPP
if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations")) {
  
  # load custom dummy data
  dummy_data <- arrow::read_feather(file.path(dir_path, "dummy_data.feather"))  
  
  # run checks
  source(here("analysis", "functions", "check_dummy_data.R"))
  check_dummy_data(studydef = extract, custom = dummy_data)
  
  # replace extract with custom dummy data
  extract <- dummy_data
  
  # clean up
  rm(dummy_data)
  
} 

# summarise extracted data
extract %>% my_skim(path = file.path(dir_path, "skim_extract.txt"))

# initial processing
data_processed <- extract %>%
  # because date types are not returned consistently by cohort extractor
  mutate(across(ends_with("_date"), ~ as.Date(.))) %>%
  # reorder so patient_id is first column
  select(patient_id, everything())

# TODO Elsie
# write in checks to make sure at risk group, JCVI groups and elig dates have 
# been derived correctly in study definition

# TODO
# As we add more variables we will need to add more processing steps to this script
  
# save the processed data
write_rds(
  data_processed, 
  file.path(dir_path, "data_processed.rds"),
  compress = "gz"
  )
