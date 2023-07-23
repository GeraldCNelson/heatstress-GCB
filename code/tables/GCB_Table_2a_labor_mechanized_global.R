this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
  setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {oldwd <- getwd()
setwd('/Users/gcn/Google Drive/My Drive/pwc')
}

library(terra)
library(flextable)
library(officer)
library(data.table)
set_flextable_defaults(font.family = "Times New Roman")
path <- "compute_pwc/output"

# mechanization by country
# mech_labor_ratio is the horsepower per worker in 2020. It ranges from 3.18e-05 for South Sudan to 120 in Canada. Most countries have less than 10 hp per worker.
m <- as.data.table(read.csv("data-raw/machines/ERSmach_land_labor.csv"))
#max(m$mech_labor_ratio, na.rm = TRUE)
m <- m[year > 2019,] # get just 2020 data
hpmax <- 70
m[, adj := 1 - (.8 * (mech_labor_ratio) / hpmax)]
m[adj < 0, adj := 0] # deals with Canada and Luxembourg having more hp than hpmax so no adjustment needed
w <- geodata::world(path = "data-raw/gadm") |> crop(ext(-180, 180, -60, 90))
w_m <- merge(w, m, by.x = "GID_0", by.y = "ISO3", all.x=TRUE)

# pwc data by pixel
ff <- list.files(path, pattern = "ensemble_pwc_wbgt_out_season_mean.*.tif$", full = TRUE)
r <- rast(ff)
names(r) <- gsub(".tif", "", substr(basename(ff), 35, nchar(ff)))

#labor_ERS.tif created in 10_FAO_ERS_employment.R
aglab <- rast("data-raw/labor_ERS.tif") |> aggregate(6, sum, na.rm = TRUE) |> crop(r)
cutoffVals <- c(50, 60, 70, 80, 90)

# labor affected by r <= val
rm(comb)
for (val in cutoffVals) {
  x <- (r <= val) * aglab # number of stressed workers in pixels where PWC value is <= cutoff val
  wm_rast <- rasterize(x = w_m, y = x, field = "adj")
  x_mech <- wm_rast * x
  g <- global(x_mech, sum, na.rm=T) /1000
  tot <- global(aglab, sum) /1000
  tot_mech_adj <- global(x, sum, na.rm=T) /1000
  g <- rbind(g, tot)
  if (!exists("comb")) {
    comb <- g
  } else {
    comb <- cbind(comb, g)
  }
}

library(stringr)
temp <- c(names(x), "aglabor")
temp <- str_replace(temp, "historical_1991_2010", "Historical, 1991-2010") |>
str_replace("ssp126_2041_2060", "SSP1-2.6, 2041-2060") |>
str_replace("ssp126_2081_2100", "SSP1-2.6, 2081-2100") |>
str_replace("ssp585_2041_2060", "SSP5-8.5, 2041-2060") |>
str_replace("ssp585_2081_2100", "SSP5-8.5, 2081-2100") |>
str_replace("aglabor", "Total ag. labor") #|>
# str_replace("aglabor1", "Total ag. labor") |>
# str_replace("aglabor2", "Total ag. labor")
comb$thermalenv <- temp
names(comb) <- c(paste0("X", cutoffVals), "thermal_env")
colorder <- c("thermal_env", paste0("X", cutoffVals))
comb <- comb[, colorder]
write.csv(comb, paste0("tables/", "stressedLaborCts.csv"), row.names = F)
rm(comb)

# create word table -----
t <- as.data.table(read.csv(paste0("tables/", "stressedLaborCts.csv")))
t[,2:6] <- round(t[,2:6], 0)

cheadername <- names(t)
cnewname <- c("PWC percentile", cutoffVals) # space needed in the name for the first column
cvalues <- setNames(cnewname, cheadername)

t_flex <- flextable(t) |> 
  set_header_labels(values = cvalues) |>
  add_header_row(colwidths = c(1,5),
                 values = c("Thermal environment scenario & period", "PWC cutoff"), top = TRUE) |> 
  
  theme_vanilla() |> 
  color(part = "footer", color = "#666666") |>
  align(align = "center", part = "header") |>
  add_footer_row(values = "Source: Labor data and mechanization data from USDA/ERS, PWC values from own calculations.", colwidths = c(6), top = FALSE)

t_flex
save_as_docx(t_flex, values = NULL, path = "tables/stressedLaborCts_global_mechadj.docx")



