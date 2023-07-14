[![DOI](https://zenodo.org/badge/xxxx.svg)](https://zenodo.org/badge/latestdoi/xxxxx)

# "Global reductions in manual agricultural work capacity due to climate change" - R code and selected data to calculate the PWC metric for heatstress facing agricultural workers in different potential climate futures

## Description of the data and file structure
The code and data needed to reproduce the results in Global Change Biology, "Global reductions in manual agricultural work capacity due to climate change (under review)" are available in the Dryad site (data, 79 GB) ([https://doi.org/10.5061/dryad.xxxxx](https://doi.org/10.5061/dryad.xxxxx)) and the Zenodo site (code and small data sets) ([https://doi.org/10.5281/zenodo.xxxxx](https://doi.org/10.5281/zenodo.xxxxx)).

To generate the results, the _Directory structure_ section below describes the directories needed (and should automatically be created when the zenodo files are downloaded) and what is contained in them.The _Order of operations_ section describes the order in which the R code files need to be run to generate the results.

## Directory structure - to be updated

The directory structure for the code is described below. The data from the dryad download xxxx. Of these, xxx. All of the climate data _xxx.tif_ files need to be moved to the _climdata_ directory (see below).

- code - R code
     - data - R code to import and process data files
     - plots - R code to generate graphics used in the paper
     - tables - R code to generate tables used in the paper and the supplementary material

- data-raw - climate data files. The ISIMIP project [https://www.isimip.org] prepares daily bias-corrected 1/2 degree resolution from five earth system models (ESMs - GFDL-ESM4, UKESM1-0-LL, MPI-ESM1-2-HR, MRI-ESM2-0, and IPSL-CM6A-LR). The paper uses the ISIMIP3b data from 
[https://doi.org/10.48364/ISIMIP.842396.1](https://doi.org/10.48364/ISIMIP.842396.1). 

- data - processed data files
- graphics - graphics included in the paper
- tables - tables included in the paper

## Order of operations


