
# this <- system('hostname', TRUE)
# if (this == "LAPTOP-IVSPBGCA") {
#   setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
# } else {
#   setwd('/Users/gcn/Google Drive/My Drive/pwc')
# }
 path <- "data/agg/pwc_agg3"

library(terra)
library(data.table)
library(flextable)
library(officer)
library(stringr)
set_flextable_defaults(font.family = "Times New Roman", font.color = "#333333", border.color = "#999999", padding = 4)

crps <- rast("data-raw/crops/total_crop_area.tif") |> 
  aggregate(6, sum, na.rm=TRUE) |> crop(c(-180, 180, -60, 67)) |>  round()

w <- geodata::world(path="data-raw", version="3.6")

ff <- list.files(path, pattern = ".*_mean.tif$", full=TRUE)
s <- sds(ff[c(1,3,2)])
z <- lapply(s, \(r) zonal(r, w, mean, w=crps, na.rm=TRUE))

zz <- do.call(cbind, z)
names(zz) <- gsub("mean_", "", gsub("pwc_", "", paste0(rep(names(s), each=5), "_", names(zz))))
zz <- cbind(values(w), zz) # annual, growing season and hot window for all countries
#zz[,-c(1:2)] <- round(zz[,-c(1:2)], 0)

zz[, 3:ncol(zz)] <- zz[, 3:ncol(zz)]/100 # convert to ratio
#
#Farm machinery is measured in units of 1000 horsepower. This is divided by cropland (1000 hectares) to give the average machinery use per hectare of agricultural land.
## Source of the data is the first data set at https://www.ers.usda.gov/data-products/international-agricultural-productivity/. This has both machinery, land and agricultural labor individually. 
temp <- as.data.table(read.csv("data-raw/machines/ERSmach_land_labor.csv")) # created in ERS_mach_land_labor.R, machinery, land and labor
temp <- temp[year >2017,]
temp <- temp [, labor_3yr := mean(ERSvalue_labor), by = "ISO3"][
  , land_3yr := mean(ERSvalue_land), by = "ISO3"][
    , machinery_3yr := mean(ERSvalue_machinery), by = "ISO3"]
temp <- unique(temp[, c("ISO3", "Country.territory", "labor_3yr", "land_3yr", "machinery_3yr"  )])

temp[, machinery_per_ag_land := machinery_3yr/land_3yr][, machinery_per_capita := machinery_3yr/labor_3yr]
colsToRound <- c("labor_3yr", "land_3yr", "machinery_3yr")
temp[, (colsToRound) := lapply(.SD, round, digits = 0), .SDcols = colsToRound]

temp[, labor_3yr := labor_3yr] # 000 persons
temp[, land_3yr := land_3yr] # 000 ha
temp[, machinery_3yr := machinery_3yr] # 000 units (CV) horsepower

x <- merge(zz, temp, by.x="GID_0", by.y="ISO3", all.x=TRUE)
write.csv(x, "tables/big_table.csv", row.names=FALSE)
ctrs <- c("Brazil", "China", "France", "Nigeria", "Pakistan", "India", "United States")
d <- x[x$Country.territory %in% ctrs,-1]
d$Country.territory <- NULL
nms <- d[,1]
d <- t(d[,-1]) # adds enough places after decimal so all numbers are the same
colnames(d) <- nms
d <- d[, ctrs]
d[6:15, ] <- d[c(11:15,6:10), ]	
d <- d[-grep("ssp126", rownames(d)), ] # remove ssp126
d <- d[-grep("annual", rownames(d)), ] # remove annual rows
d <- data.frame(ssp=rownames(d), d)
rownames(d) <- NULL
write.csv(d, "tables/subset_big_table.csv", row.names=FALSE)


# directions - https://stackoverflow.com/questions/71661066/is-there-a-function-in-flextable-to-group-a-few-rows-in-a-table-together-under-a
d <- read.csv("tables/subset_big_table.csv") # makes row names a separate column
d[-1,-1] <- round(d[-1,-1], 2)

d['type'] = c("PWC, hottest period", "PWC, hottest period", "PWC, hottest period",
              "PWC, growing season", "PWC, growing season", "PWC, growing season", 
              "Other", "Other", "Other", "Other", "Other")
names(d) <- str_replace(names(d), "ssp", "Variable") |> str_replace("United.States", "United States")
d$Variable =   str_replace_all(d$Variable, "_", " ")  |> 
  str_replace_all(" 3yr", "")  |> 
  str_replace_all("hot90 ", "")  |> 
  str_replace("season ", " ") |> 
  str_to_title()  |>
  str_replace("Ssp585", "SSP5-8.5") |>
  str_replace("Land", "Cropland")

d <- as_grouped_data(d, groups = c("type"), columns = NULL)

t_flex <- as_flextable(d, hide_grouplabel = TRUE)  |>
  colformat_double(i = (2:8), j = (2:8), digits=2) |> 
  colformat_double(i = (9:12), j = (2:8), digits=0) |> 
  colformat_double(i = (13:14), j = (2:8), digits = 2) |>
  set_header_labels(what = "") |> 
  color(part = "footer", color = "#800000") |>
  bold( bold = TRUE, part="header") |> 
  align(i = ~ !is.na(type), align = "center") |> 
  bold(i = ~ !is.na(type)) |>
  footnote(i = 10:14, j = 1,
           value = as_paragraph(
             c("000 ag. workers",
               "000 hectares",
               "000 horsepower (CV)",
               "horsepower (CV) per hectare",
               "horsepower (CV) per ag. worker")
             #              "Source: USDA/ERS")
           ),
           ref_symbols = c("a", "b", "c", "d", "e"),
           part = "body", inline = TRUE) 

t_flex

save_as_docx(t_flex, values = NULL, path = "tables/table3_countries.docx")
