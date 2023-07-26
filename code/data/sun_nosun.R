# create a raster of the ratio between end century SSP5-8.5 thermal environments with and without solar radiation
library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (this == "MacBook-Pro-M1X.local") terraOptions(verbose = TRUE, memfrac = 0.8)


path_base <- "data-raw/ISIMIP/pwc_agg2/"
path_ns <- "data-raw/ISIMIP/pwc_agg2_ns/"
pwc_ns_585_2081 <- rast(paste0(path_ns, "pwc_ns_ssp585_2081_2100.tif"))
pwc_reg_585_2081 <- rast(paste0(path_base, "pwc_ssp585_2081_2100.tif"))
d_ratio <- 100*(pwc_ns_585_2081 - pwc_reg_585_2081)/pwc_reg_585_2081

crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm = TRUE) |> round()

wrld <- geodata::world(path = "data-raw")
crops <- mask(crps > 100, wrld)

d_ratio_cropped <- mask(d_ratio, crops)
              
