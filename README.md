
## R code and data to generate results for the Global Change Biology paper 
# "Global reductions in manual agricultural work capacity due to climate change"
Author: Gerald C. Nelson

## Introduction

This page describes the code and data needed to reproduce the results in the Global Change Biology paper, "Global reductions in manual agricultural work capacity due to climate change", available at the Zenodo site  ([![DOI](https://zenodo.org/badge/664373839.svg)](https://zenodo.org/doi/10.5281/zenodo.10429708)).

The _Directory structure_ section describes the directories needed (which should automatically be created when the zenodo files are downloaded) and what is contained in them.The _Order of operations_ section describes the order in which the R code files need to be run to generate the results.


## Directory structure

The directory structure for the code is described below. 

### Code
- **code** — Contains all R code needed to generate the results
  - *data* — Code to import data from the ISIMP project and process them
  - *plots* — Code to generate graphics used in the paper
  - *tables* — Code to generate tables used in the paper and the supplementary material
  - *other* — Experimental code to investigate the impacts of using hourly data instead of daily data 

### Other directories
  
- **data-raw** — Downloaded climate files from the ISIMIP project and other data imported from open sources. 

The [ISIMIP project](https://www.isimip.org) prepares daily bias-corrected 1/2 degree resolution data from five earth system models (ESMs) - GFDL-ESM4, UKESM1-0-LL, MPI-ESM1-2-HR, MRI-ESM2-0, and IPSL-CM6A-LR). The paper uses the ISIMIP3b data from 
[https://doi.org/10.48364/ISIMIP.842396.1](https://doi.org/10.48364/ISIMIP.842396.1). The data sets used are collectively about 2 terabytes. It can be useful to store them on an external drive and then use a symlink from the external drive to the `data-raw` directory  ([Mac directions](https://www.google.com/search?client=safari&rls=en&q=create+a+mac+symlink&ie=UTF-8&oe=UTF-8), [PC directions](https://www.google.com/search?client=safari&rls=en&q=create+a+pc+symlink&ie=UTF-8&oe=UTF-8)) to access them.


- **data** — processed data files
- **graphics** — graphics included in the paper
- **tables** — tables included in the paper

## Order of operations

The R code in the _R/code/data_ directory contains the following R files. These need to be run in the order listed below.
  
-   `1a_get_weather.R` - create a set of `txt` files in the `data-raw/ISIMIP/filelists/` directory with ISIMIP climate data file names to be used in `1b_get_weather.R`. Installed needed packages that are not already installed.
-   `1b_get_weather.R` - download a set of climate data files from the ISIMIP server based on the `.txt` files created in `1a_get_weather.R`. Each file is about 2.5 GB. For each of the three scenarios plus the recent past data files, the combined data sets require 285 GB. You will need at last terabyte of space for all the data. The download process can take a long time. 
-   `2a_daytemp.R` - calculate the average temperature in daylight hours using the `tasmin` and `tasmax` data files
-   `2b_fix_radiation.R` - converts the `rsds` data file to average solar radiation during daylight hours.
-   `3_wbgt.R` - calculate `wbgt` values for each combination of climate scenario and time period. The code includes a switch to calculate `wbgt` with solar radiation values or without to simulate complete shade. The default is `nosun <- FALSE`. Change to `TRUE` to create the `wbgt` values with solar radiation set to zero.
-   `4_pwc.R` - calculate PWC values for each combination of climate scenario and time period.
-   `5_agg_time.R` - aggregate daily PWC values over one of the 20 year periods - 1991-2010, 2041-2060, and 2081-2100, for individual models
-   `6_agg_models.R` - aggregate the results of `5_agg_time.R` across all models to get a `spatraster` with 365 layers for each scenario.
-   `7_get_crops.R` - sum area of the 172 crops in the `geodata` library from the [Monfreda, et al.](https://doi.org/10.1029/2007GB002947) data, and generated weighted crop calendar data based on the Sacks, et al, 2010 crop calendars in the `geodata` library
-   `8_summarize.R` - Aggregate to daily means of annual, growing season and hottest periods. Set `nosun <- TRUE` to calculate the impact of eliminating the radiation effect in PWC values. 
-   `10_FAO_ERS_employment.R` - create rasterized versions of the country-specific labor data from either ERS or FAO. ERS version used in the paper.

The _R/code/plots_ directory contains the following R files that produce figures in the GCB paper. These can be run in any order.

  - `GCB_Figure_1_cumul.R` - create _Figure 1. Cumulative distribution of early 21st century cropland Physical Work Capacity (PWC) for recent \past (1991-2010) and potential future thermal conditions_ and _Table S2. Physical Work Capacity (PWC) in the tropics (23S – 23N latitude), 1991-2010 and potential future thermal conditions (2041-2060 and 2081-2100), for three emission scenarios (SSP1-2.6, SSP3-7.0 and SSP5-8.5_
  - `GCB_Figure_2_latitude.R`- create _Figure 2. Physical Work Capacity (PWC) by latitude for global cropland for recent past (1991-2010) and potential future thermal conditions_ 
  - `GCB_Figure_3_global.R` - create _Figure 3. Average PWCs during the crop growing season and the hottest period_
  - `GCB_Figure_4_regions.R` - create _Figure 4. Average PWCs during the growing season for three countries_
  - `GCB_Figure_5_global_noSun.R` - create _Figure 5. Impact of eliminating radiation effect in PWC values_
  - `GCB_Figure_6_mech_needs.R` - create _Figure 6. The additional HP per hectare to make at least 1 HP per cropped hectare available_
  - `GCB_Figure_S1_aggregation_methods.R` - not used in GCB paper. Produces global figures using SSP1-2.6 and SSP5-8.5 data for recent past, mid-century, and end-century for annual, growing season, and hottest 90 days periods.
 
The _R/code/tables_ directory contains the following R files that produce the tables in the GCB paper. These can be run in any order.

  - `GCB_table_1.R` - create _Table 1. Physical Work Capacity (PWC) for 1991-2010 and potential future thermal conditions_
  - `GCB_Table_2_labor_global_share.R` - _create Table 2. Share of early century agricultural workers during the crop growing season with mean growing season PWC at or below a cutoff value of PWC by period and emission scenario_
  - `GCB_Table_3_countries.R` - create _Table 3. Summary of PWC results for selected countries_ 
  - `GCB_Table_4_labor_regions.R` - create _Table 4. Early century agricultural labor experiencing growing season thermal environments for selected countries_
  - `GCB_table_5_delta_NoSun.R` - create _Table 5. Change in the PWC ratio from elimination of the radiation effect_
  - `GCB_SM_Table_1_countries_all.R` - create _Table S1, Physical Work Capacity (PWC) for 1991-2010 and potential future thermal conditions (2041-2060 and 2081-2100) for three emission scenarios (SSP1-2.6, SSP3-7.0 and SSP5-8.5_
  - `GCB_SM_Table_3_countries_all_other.R` -  create _Table S3. Summary data used in adaptation analysis for all countries (See Table 3 in main text for details)_

## Data availability
All data used in this paper are downloaded in the code from open source data sites or with the R `geodata` package.

The main sources are 

- Climate data from the ISIMIP project [https://www.isimip.org] that are daily bias-corrected and 1/2 degree resolution from five earth system models (ESMs - GFDL-ESM4, UKESM1-0-LL, MPI-ESM1-2-HR, MRI-ESM2-0, and IPSL-CM6A-LR). This paper uses the ISIMIP3b data from 
[https://doi.org/10.48364/ISIMIP.842396.1](https://doi.org/10.48364/ISIMIP.842396.1).
- Area of the 172 crops in the `geodata` library described in [Monfreda, et al.](https://doi.org/10.1029/2007GB002947) data and an area -weighted crop calendar data based on the Sacks, et al, 2010 crop calendars in the `geodata` library.
- Country-level data on agricultural labor and machinery, downloaded from the USDA/ERS website [Fuglie, Jelliffe, and Morgan](https://www.ers.usda.gov/webdocs/DataFiles/51270/AgTFPInternational2020_long.xlsx?v=8337).

Identify code/data issues in the Issues section of this repository. Questions/Comments to [nelson.gerald.c@gmail.com](mailto:nelson.gerald.c@gmail.com)

