[![DOI](https://zenodo.org/badge/xxxx.svg)](https://zenodo.org/badge/latestdoi/xxxxx)

# "Global reductions in manual agricultural work capacity due to climate change" - R code and selected data to calculate the PWC metric for heat stress facing agricultural workers in potential climate futures

## Description of the data and file structure
The code and data needed to reproduce the results in Global Change Biology, "Global reductions in manual agricultural work capacity due to climate change (under review)" are available in the Zenodo site (code to download the climate data and prepare the results in the GCB paper and small data sets) ([https://doi.org/10.5281/zenodo.xxxxx](https://doi.org/10.5281/zenodo.xxxxx)).

The _Directory structure_ section below describes the directories needed (and should automatically be created when the zenodo files are downloaded) and what is contained in them.The _Order of operations_ section describes the order in which the R code files need to be run to generate the results.

## Directory structure - to be updated

The directory structure for the code is described below. The data from the dryad download xxxx. Of these, xxx. All of the climate data _xxx.tif_ files need to be moved to the _climdata_ directory (see below).

- code - R code
     - data - files to import data files from the ISIMP project and process them
     - plots - files to generate graphics used in the paper
     - tables - files to generate tables used in the paper and the supplementary material

- data-raw - where climate data files downloaded from the ISIMIP project are stored. The ISIMIP project [https://www.isimip.org] prepares daily bias-corrected 1/2 degree resolution from five earth system models (ESMs - GFDL-ESM4, UKESM1-0-LL, MPI-ESM1-2-HR, MRI-ESM2-0, and IPSL-CM6A-LR). The paper uses the ISIMIP3b data from 
[https://doi.org/10.48364/ISIMIP.842396.1](https://doi.org/10.48364/ISIMIP.842396.1). These data sets are collectively about 2 gb. It can be useful to store them on an external drive and then use a simlink to access them.

- data - processed data files
- graphics - graphics included in the paper
- tables - tables included in the paper

## Order of operations
The R code in the _code/data_ directory contains the following files which need to be run in the order listed below.
  
-   `1a_get_weather.R` - create a set of csv files with ISIMIP climate data file names to be used in `1b_get_weather.R`.
-   `1b_get_weather.R` - download a set of climate data files from the ISIMIP server based on the .csv files created in `1a_get_weather.R`. Each file is about 2.5 gb. For each of the three scenarios plus the recent past data files, the combined data sets are 285 GB. You will need at last terrabyte of space for all the data. The download process can take a long time. 
-   `2a_daytemp.R` - calculate the average temperature in daylight hours using the `tasmin` and `tasmax` data files
-   `2b_fix_radiation.R` - converts the rsds data file to average solar radiation during daylight hours
-   `3_wbgt.R` - calculate wbgt values for each combination of climate scenario and time period. The code includes a switch to calculate wbgt with solar radiation values or with these set to zero to simulate complete shade. The default is `nosun <- FALSE`. Change to `TRUE` if you want the no sun `wbgt` values
-   `4_pwc.R` - calculate pwc values for each combination of climate scenario and time period
-   `5_agg_time.R` - aggregate daily `pwc` values over one of the 20 year periods - 1991-2010, 2041-2060, and 2081-2100, for individual models
-   `6_agg_models.R` - aggregate the results of `5_agg_time.R` across all models to get a `spatraster` with 365 layers for each scenario.
-   `7_get_crops.R` - sum area of the 172 crops in the `geodata` library from the Mondfreda, et al. data, and generated weighted crop calendar data based on the Sacks, et al, 2010 crop calendars in the `geodata` library
-   `8_summarize.R` - Aggregation to daily means of annual, growing season and hottest periods. Also includes impact of eliminating radiation effect in PWC values. 
-   `10_a_ERS_mach_land_labor.R`
-   `10_b_FAO_cropland.R` - not used in the GCB heatstress paper but the code is included for comparison purposes
-   `10_c_FAO_ERS_employment.R` - creates rasterized versions of the country specific labor data from either ERS or FAO. ERS version used in the paper
-   `sun_nosun.R` - create a raster of the ratio between end-century SSP5-8.5 thermal environment with and without solar radiation

- the code/plots directory contains the fillowing files that produce the figures in the GCB paper
  - `GCB_Figure_1_cumul.R` - _create Figure 1. Cumulative distribution of early 21st century cropland Physical Work Capacity (PWC) for recent past (1991-2010) and potential future thermal conditions_ and `SM_table_2_tropical.docx`
  - `GCB_Figure_2_latitude.R`- _create Figure 2. `Physical Work Capacity (PWC)` by latitude for global cropland for recent past (1991-2010) and potential future thermal conditions_ 
  - `GCB_Figure_3_global.R` - _create Figure 3. Average PWCs during the crop growing season and the hottest period_
  - `GCB_Figure_4_regions.R` - _create Figure 4. Average PWCs during the growing season for three countries_
  - `GCB_Figure_5_global_delta_noSun.R` - _not used in the paper_
  - `GCB_Figure_5_a_global_noSun.R` - _create Figure 5. Impact of eliminating radiation effect in PWC values._
  - `GCB_Figure_6_mech_needs.R` - _create Figure 6. The additional HP per agricultural worker to make 60 HP available_
  - `GCB_Figure_S1_aggregation_methods.R` _not used in GCB paper. Produces global figures using SSP1-2.6 and SSP5-8.5 data for recent past, mid-century, and end-century for annual, growing season, and hottest 90 days periods._
 
- the code/tables directory contains the following files that produce the tables in the GCB paper
  - `GCB_table_1.R` - _create Table 1. Physical Work Capacity (PWC) for 1991-2010 and potential future thermal conditions_
  - `GCB_Table_2_labor_global_share.R` - _create Table 2. Share of early century agricultural workers during the crop growing season with mean growing season PWC at or below a cutoff value of PWC by period and emission scenario._
  - `GCB_Table_3_countries.R` - _create Table 3. Summary of PWC results for selected countries_ 
  - `GCB_Table_4_labor_regions.R` - _create Table 4. Early century agricultural labor experiencing growing season thermal environments for selected countries_ 
  - `GCB_table_5_delta_NoSun.R` - _create Table 5. Change in the PWC ratio from elimination of the radiation effect_
  - `GCB_mech_needs.R`
  - `GCB_SM_Table_1_countries_all.R` - _create Supplementary Materials Table 1, Physical Work Capacity (PWC) for 1991-2010 and potential future thermal conditions for all countries_
  - `GCB_SM_Table_3_countries_all_other.R`



