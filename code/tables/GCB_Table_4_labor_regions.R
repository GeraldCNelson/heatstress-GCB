this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
  setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {oldwd <- getwd()
setwd('/Users/gcn/Google Drive/My Drive/pwc')
}


path <- "compute_pwc/output"

library(terra)
library(geodata)
library(flextable)
library(officer)
library(data.table)
set_flextable_defaults(font.family = "Times New Roman")

wrld <- geodata::world(path = "data-raw")
country_Brazil <- gadm(country = "BRA", level = 0, path = "data-raw/gadm/", resolution = 2) 
country_India <- gadm(country = "IND", level = 1, path = "data-raw/gadm/", resolution = 2)
country_Nigeria <- gadm(country = "NGA", level = 1, path = "data-raw/gadm/", resolution = 2)

regionChoices <- c("country_Brazil", "country_India", "country_Nigeria")
#test data
regionChoice <- "country_Brazil"
# pwc data 
ff <- list.files(path, pattern = "ensemble_pwc_wbgt_out_season_mean.*.tif$", full=TRUE)

r <- rast(ff)/100 # convert percent to ratio
names(r) <- gsub(".tif", "", substr(basename(ff), 35, nchar(ff)))

# ag labor data 
aglab <- rast("data-raw/labor_ERS.tif") |> aggregate(6, sum, na.rm=TRUE) |> crop(r)
cutoffVals <- c(0.50, 0.60, 0.70, 0.80, 0.90)

for (regionChoice in regionChoices) {
  regionName <- gsub("country_", "", regionChoice)
  rc <- get(regionChoice)
  aglab_region <- crop(aglab, rc)
  r_region <- crop(r, rc)
  if (exists("tt")) rm(tt)
  # labor affected by r <= val
  for (val in cutoffVals) {
    x <- (r_region <= val) * aglab_region
    g <- global(x, sum, na.rm = T) / 1000
    tot <- global(aglab_region, sum) / 1000
    g <- rbind(g, tot)
    if (!exists("tt")) {
      tt <- g
    } else {
      tt <- cbind(tt, g)
    }
  }
  tt$regionName <- regionName
  
  if (!exists("comb")) {
   # browser()
    comb <- tt
  } else {comb <- rbind(comb, tt)
  }
}

temp <- rownames(comb) |>
str_replace("historical_1991_2010", "Historical, 1991-2010") |>
str_replace("ssp126_2041_2060", "SSP1-2.6, 2041-2060") |>
str_replace("ssp126_2081_2100", "SSP1-2.6, 2081-2100") |>
str_replace("ssp585_2041_2060", "SSP5-8.5, 2041-2060") |>
str_replace("ssp585_2081_2100", "SSP5-8.5, 2081-2100") |>
str_replace("aglabor", "Total ag. labor") |>
str_replace("aglabor1", "Total ag. labor") |>
str_replace("aglabor2", "Total ag. labor")

comb$thermalenv <- temp
names(comb) <- c(paste0("X", cutoffVals), "regionName", "thermal_env")
colorder <- c("thermal_env", "regionName", paste0("X", cutoffVals))

comb <- comb[, colorder]
write.csv(comb, paste0("tables/", "stressedLaborCts_regions", ".csv"), row.names = F)

# create word table -----
 comb <- read.csv(paste0("tables/", "stressedLaborCts_regions", ".csv"))
 names(comb) <- c("PWC percentile",  "regionName",  cutoffVals)
 
 comb[,3:7] <- round(comb[,3:7], 0)
 comb <- as_grouped_data(comb, groups = c("regionName"), columns = NULL)
 t_flex <- as_flextable(comb, hide_grouplabel = TRUE)  |>
   set_header_labels(what = "") |> 
   add_header_row(colwidths = c(1,5), values = c("Emission scenario & period", "Workers (000)"), top = TRUE) |> 
   color(part = "footer", color = "#800000") |>
   bold( bold = TRUE, part = "header") |> 
   align(i = ~ !is.na(regionName), align = "center") |> 
   align(align = "center", part = "header") |>
   bold(i = ~ !is.na(regionName)) |>
   add_footer_row(values = "Source: Labor data from USDA/ERS, PWC values from own calculations.", colwidths = c(6), top = FALSE)
 t_flex
  save_as_docx(t_flex, values = NULL, path = paste0("tables/", "table4_stressedLaborCts_regions", ".docx"))
  
  
  
  
