from cohortextractor import (
    StudyDefinition, 
    patients, 
    filter_codes_by_category
)

# Import codelists.py script
from codelists import *

import pandas as pd

from functions import *

# import the variables for deriving JCVI groups
from elig_definition import (
    elig_variables, 
    study_parameters
)

# set seed so that dummy data can be reproduced
import numpy as np
np.random.seed(study_parameters["seed"])

# regions
regions = pd.read_csv(
    filepath_or_buffer='./analysis/lib/regions.csv',
    dtype=str
)
ratio_regions = { regions['region'][i] : float(regions['ratio'][i]) for i in regions.index }

study=StudyDefinition(

    default_expectations = {
        "date": {"earliest": "2020-01-01", "latest": "2021-12-31"},
        "rate": "uniform",
        "incidence": 0.9,
    },

    ##########################
    ### ELIGIBILITY GROUPS ###
    ##########################
    # population = patients.all(),
    **elig_variables, 

    # ##################
    # ### POPULATION ###
    # ##################

    population = patients.satisfying(
        """
        has_follow_up = 1
        AND NOT died_before
        AND age_2 >= 18
        AND age_2 < 120
        """,
        has_follow_up = patients.registered_with_one_practice_between(
            start_date = "2020-03-01",
            end_date = "2021-12-17", # 26 weeks after 18-year-olds became eligible for 1st dose
        ),
        died_before = patients.died_from_any_cause(
            on_or_before = "elig_date - 1 day",
            returning = "binary_flag",
            return_expectations = {"incidence": 0.01},
        ),
    ),

    ######################
    ### COVID VACCINES ###
    ######################

    # first 2 covid vaccine dates
    **vaccination_date_X(
        name = "covid_vax_disease",
        index_date = "1900-01-01", # set implausibly early to catch errors
        n = 2,
        target_disease_matches="SARS-2 CORONAVIRUS"
    ),

    # #############################
    # ### DEMOGRAPHIC VARIABLES ###
    # #############################

    # STATIC
    # patient sex
    sex = patients.sex(
        return_expectations = {
        "rate": "universal",
        "category": {"ratios": {"M": 0.49, "F": 0.51}},
        "incidence": 0.99,
        }
    ),

    # 1 DEC 2021
    # region - NHS England 9 regions
    region = patients.registered_practice_as_of(
        "elig_date - 1 day",
        returning = "nuts1_region_name",
        return_expectations = {
            "rate": "universal",
            "category": {
                "ratios": ratio_regions,
            },
            "incidence": 0.99
        },
    ),

    # ELIGIBILITY DATE
    # pregnancy
    **pregnancy(name = "preg_elig_group", index_date = "elig_date", type = "column"),
    # extract first pregnancy code after elig date
    # preg_after_elig_date
    # extract first delivery code after elig date
    # preg_del_after_elig_date

    # ethnicity (6 categories)
    ethnicity = patients.categorised_as(
        {
        "Unknown": "DEFAULT",
        "White": "eth6='1'",
        "Mixed": "eth6='2'",
        "Asian or Asian British": "eth6='3'",
        "Black or Black British": "eth6='4'",
        "Other": "eth6='5'",
        },
        eth6 = patients.with_these_clinical_events(
            ethnicity_codes_6,
            returning = "category",
            on_or_before = "elig_date - 1 day",
            find_last_match_in_period = True,
            include_date_of_match = False,
            return_expectations = {
                "incidence": 0.75,
                "category": {
                "ratios": { "1": 0.30, "2": 0.20, "3": 0.20, "4": 0.20, "5": 0.05, "6": 0.05, },
                },
            },
        ),
        return_expectations = {
            "rate": "universal",
            "category": {
            "ratios": {
                "White": 0.30,
                "Mixed": 0.20,
                "Asian or Asian British": 0.20,
                "Black or Black British": 0.20,
                "Other": 0.05,
                "Unknown": 0.05,
                },
            },
        },
    ),

    # patients in long-stay nursing and residential care
    # any time after start_date (indicator for before start_date in elig_definition)
    longres_date = patients.with_these_clinical_events(
        longres_primis,
        returning = "date",
        date_format = "YYYY-MM-DD",
        on_or_after = study_parameters["start_date"],
        find_first_match_in_period = True,
        return_expectations = { "incidence": 0.01},
    ),

    # any death
    death_date=patients.died_from_any_cause(
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations = { "incidence": 0.01},
    ),

    ##########################
    ### CLINICAL VARIABLES ###
    ##########################

    # new shielding flag after ref_cev date
    # new nonshielding flag after ref_cev date
    # new diagnoses of at-risk group conditions after ref_ar date

)
