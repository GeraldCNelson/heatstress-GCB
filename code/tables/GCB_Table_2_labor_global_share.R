# this <- system('hostname', TRUE)
# if (this == "LAPTOP-IVSPBGCA") {
#   setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
# } else {oldwd <- getwd()
# setwd('/Users/gcn/Google Drive/My Drive/pwc')
# }

library(terra)
library(flextable)
library(officer)
library(data.table)
library(stringr)
set_flextable_defaults(font.family = "Times New Roman")
path <- "compute_pwc/output"

# pwc data 
ff <- list.files(path, pattern = "ensemble_pwc_wbgt_out_season_mean.*.tif$", full=TRUE)
r <- rast(ff)
names(r) <- gsub(".tif", "", substr(basename(ff), 35, nchar(ff)))

aglab <- rast("data-raw/labor_ERS.tif") |> aggregate(6, sum, na.rm=TRUE) |> crop(r)
cutoffVals <- c(50, 60, 70, 80, 90)

# labor affected by r <= val
#comb <- data.frame(sum_stressed = numeric(7))
for (val in cutoffVals) {
  x <- (r <= val) * aglab
  g <- global(x, sum, na.rm=T) /1000
  tot <- global(aglab, sum) /1000
  g <- rbind(g, tot)
  if (!exists("comb")) {
    comb <- g
  } else {
    comb <- cbind(comb, g)
  }
}

comb$sum_stressed <- NULL
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
names(comb) <- c(paste0("X", cutoffVals), "thermal_env")
colorder <- c("thermal_env", paste0("X", cutoffVals))
comb <- comb[, colorder]
comb_percent <- comb
comb_percent[2:length(comb)] <- 100 * comb[2:length(comb)]/comb["aglabor","X90"]
#write.csv(comb, paste0("tables/", "stressedLaborCts.csv"), row.names = F)
write.csv(comb_percent, paste0("tables/", "stressedLaborPercent.csv"), row.names = F)
rm(comb_percent) # only really necessary during development

# create word table -----
t <- as.data.table(read.csv(paste0("tables/", "stressedLaborPercent.csv")))
t[,2:6] <- round(t[,2:6], 1)

cheadername <- names(t)
cnewname <- c(" ", paste0("≤ ", cutoffVals/100)) # space needed in the name for the first column
cvalues <- setNames(cnewname, cheadername)

t_flex <- flextable(t) |> 
  set_header_labels(values = cvalues) |>
  add_header_row(colwidths = c(1,5),
                 values = c("Emission scenario & period", "Workers (%)"), top = TRUE) |> 
  
  theme_vanilla() |> 
  color(part = "footer", color = "#666666") |>
  align(align = "center", part = "header") |>
  add_footer_row(values = "Source: Labor data from USDA/ERS, PWC values from own calculations.", colwidths = c(6), top = FALSE)

t_flex
save_as_docx(t_flex, values = NULL, path = "tables/table2_stressedLaborCts_percent.docx")



