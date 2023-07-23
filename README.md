[![DOI](https://zenodo.org/badge/xxxx.svg)](https://zenodo.org/badge/latestdoi/xxxxx)

# "Global reductions in manual agricultural work capacity due to climate change" - R code and selected data to calculate the PWC metric for heatstress facing agricultural workers in different potential climate futures

## Description of the data and file structure
The code and data needed to reproduce the results in Global Change Biology, "Global reductions in manual agricultural work capacity due to climate change (under review)" are available in the Dryad site (data, 79 GB) ([https://doi.org/10.5061/dryad.xxxxx](https://doi.org/10.5061/dryad.xxxxx)) and the Zenodo site (code and small data sets) ([https://doi.org/10.5281/zenodo.xxxxx](https://doi.org/10.5281/zenodo.xxxxx)).

To generate the results, the _Directory structure_ section below describes the directories needed (and should automatically be created when the zenodo files are downloaded) and what is contained in them.The _Order of operations_ section describes the order in which the R code files need to be run to generate the results.

## Directory structure - to be updated

The directory structure for the code is described below. The data from the dryad download xxxx. Of these, xxx. All of the climate data _xxx.tif_ files need to be moved to the _climdata_ directory (see below).

- code - R code
     - data - files to import data files from the ISIMP project and process them
     - plots - files to generate graphics used in the paper
     - tables - files to generate tables used in the paper and the supplementary material

- data-raw - where climate data files downloaded from the ISIMIP project are stored. The ISIMIP project [https://www.isimip.org] prepares daily bias-corrected 1/2 degree resolution from five earth system models (ESMs - GFDL-ESM4, UKESM1-0-LL, MPI-ESM1-2-HR, MRI-ESM2-0, and IPSL-CM6A-LR). The paper uses the ISIMIP3b data from 
[https://doi.org/10.48364/ISIMIP.842396.1](https://doi.org/10.48364/ISIMIP.842396.1). 

- data - processed data files
- graphics - graphics included in the paper
- tables - tables included in the paper
s
## Order of operations
The R code needs to be run in the following order
- the code/data directory contains the fillowing files which need to be run in the order lists
 - 1a_get_weather.R - create a set of csv files with ISIMIP climate data file names to be used in 1b_get_weather.R - runs quickly
- 1b_get_weather.R - download a set of climate data files from the ISIMIP server. Each file is about 2.5 gb. Speed of your internet connection determines how long this process takes. 
  - 2a_daytemp.R - calculate the average temperature in daylight hours using the tasmin and tasmax data files
  - 2b_fix_radiation.R - converts the rsds data file to average solar radiation during daylight hours
  - 3_wbgt.R - calculate wbgt values for each combination of climate scenario and time period
  - 4_pwc.R - calculate pwc values for each combination of climate scenario and time period
  - 5_agg_time.R - aggregate pwc values over one of the 20 year periods - 1991-2010, 2041-2060, and 2081-2100, for individual models
  - 6_agg_models.R - aggregate the results of 5_agg_time.R across all models to get a spatraster with 365 layers
  - 7_get_crops.R - 
  - 7a_SacksCropShare.R
  - 8_summarize.R
  - 10_a_ERS_mach_land_labor.R
  - 10_b_FAO_cropland.R
  - 10_c_FAO_ERS_employment.R
  - sun_nosun.R
- the code/plots directory contains the fillowing files that produce the figures in the GCB paper
  - GCB_Figure_1_cumul.R - create Figure 1. Cumulative distribution of early 21st century cropland Physical Work Capacity (PWC) for recent historical (1991-2010) and potential future thermal conditions 
  - GCB_Figure_2_latitude.R- create Figure 2. Physical Work Capacity (PWC) by latitude for global cropland for recent historical (1991-2010) and potential future thermal conditions 
  - GCB_Figure_3_global.R - create Figure 3. Average PWCs during the crop growing season and the hottest period
  - GCB_Figure_4_regions.R - create Figure 4. Average PWCs during the growing season for three countries
  - GCB_Figure_5_global_delta_noSun.R
  - GCB_Figure_5_global_noSun.R - create Figure 5. Impact of eliminating radiation effect in PWC values.
  - GCB_Figure_6_mech_needs.R - Figure 6. The additional HP per agricultural worker to make 60 HP available
  - GCB_Figure_S1_aggregation_methods.R
  - GCB_Figure_x_Brazil.R
  - GCB_figure1_cumPWC_3types.R
  
- the code/tables directory contains the fillowing files that produce the figures in the GCB paper

  - GCB_table_1.R - create Table 1. Physical Work Capacity (PWC) for 1991-2010 and potential future thermal conditions
  - GCB_table_1a_deltaNoSun.R
  - GCB_Table_2_labor_global_share.R - create Table 2. Share of early century agricultural workers during the crop growing season with mean growing season PWC at or below a cutoff value of PWC by period and emission scenario.
  - GCB_Table_2_labor_global.R
  - GCB_Table_2a_labor_mechanized_global.R
  - GCB_Table_3_countries.R - create Table 3. Summary of PWC results for selected countries 
  - GCB_Table_4_labor_regions.R - create Table 4. Early century agricultural labor experiencing growing season thermal environments for selected countries 
  - GCB_table_5_delta_NoSun.R - create Table 5. Change in the PWC ratio from elimination of the radiation effect
  - GCB_mech_needs.R
  - GCB_SM_Table_1_countries_all.R
  - GCB_SM_Table_2_countries_all_other.R.old
  - GCB_SM_Table_3_countries_all_other.R
  - GCB_table_x_cumul_3types.R



