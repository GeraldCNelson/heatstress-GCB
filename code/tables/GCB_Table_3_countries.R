# GCB paper, table 3, data for selected countries

library(terra)
library(data.table)
library(flextable)
library(officer)
library(stringr)
set_flextable_defaults(font.family = "Times New Roman", font.color = "#333333", border.color = "#999999", padding = 4)

path <- "data/agg/pwc_agg3"

crps <- rast("data-raw/crops/total_crop_area.tif") |>
  aggregate(6, sum, na.rm = TRUE) |>
  crop(c(-180, 180, -60, 67)) |>
  round()

w <- geodata::world(path = "data-raw", version = "3.6")

ff <- list.files(path, pattern = ".*_mean.tif$", full = TRUE)
s <- sds(ff[c(1, 3, 2)]) # annual, hot 90, season means
z <- lapply(s, \(r) zonal(r, w, mean, w = crps, na.rm = TRUE)) # get country means for 3 periods, in a list

zz <- do.call(cbind, z) # combine into 1 data frame
names(zz) <- gsub("mean_", "", gsub("pwc_", "", paste0(rep(names(s), each = 7), "_", names(zz)))) # 5 for two scenarios, 7 for 3 scenarios
zz <- cbind(values(w), zz) # annual, growing season and hot window for all countries
zz[, 3:ncol(zz)] <- zz[, 3:ncol(zz)] / 100 # convert PWC percents to ratio
#
# Farm machinery is measured in units of 1000 horsepower. This is divided by cropland (1000 hectares) to give the average machinery use per hectare of agricultural land.
## Source of the data is the first data set at https://www.ers.usda.gov/data-products/international-agricultural-productivity/. This has both machinery, land and agricultural labor by country
temp <- as.data.table(read.csv("data-raw/machines/ERSmach_land_labor.csv")) # created in 10_ERS_mach_land_labor.R, machinery, land and labor
temp <- temp[year > 2017, ] # keep years 2017 to 2020
temp <- temp[, labor_3yr := mean(ERSvalue_labor), by = "ISO3"][
  , cropland_3yr := mean(ERSvalue_cropland),
  by = "ISO3"
][
  , machinery_3yr := mean(ERSvalue_machinery),
  by = "ISO3"
]
temp <- unique(temp[, c("ISO3", "Country.territory", "labor_3yr", "cropland_3yr", "machinery_3yr")])

temp[, machinery_per_cropland := machinery_3yr / cropland_3yr][, machinery_per_agworker := machinery_3yr / labor_3yr]
colsToRound <- c("labor_3yr", "cropland_3yr", "machinery_3yr")
temp[, (colsToRound) := lapply(.SD, round, digits = 0), .SDcols = colsToRound]
ratioColsToRound <- c("machinery_per_cropland", "machinery_per_agworker")
temp[, (ratioColsToRound) := lapply(.SD, round, digits = 3), .SDcols = ratioColsToRound]

x <- merge(zz, temp, by.y = c("ISO3", "Country.territory"), by.x = c("GID_0", "NAME_0"), all.x = TRUE)
write.csv(x, "tables/big_table.csv", row.names = FALSE)

ctrs <- c("Brazil", "China", "France", "Nigeria", "Pakistan", "India", "United States")
d <- x[x$NAME_0 %in% ctrs, -1]
d[, -1] <- apply(d[, -1], 2, round, 2)
nms <- d[, 1] # should be same as ctrs

colNamesToKeep <- c(
  "NAME_0", "season_historical_1991-2010",
  "season_ssp370_2041-2060", "season_ssp370_2081-2100",
  "season_ssp585_2041-2060", "season_ssp585_2081-2100",
  "hot90_historical_1991-2010", "hot90_ssp370_2041-2060", "hot90_ssp370_2081-2100",
  "hot90_ssp585_2041-2060", "hot90_ssp585_2081-2100",
  "labor_3yr", "cropland_3yr", "machinery_3yr", "machinery_per_cropland", "machinery_per_agworker"
)

d <- d[, colNamesToKeep]

d <- t(d[, -1])
colnames(d) <- nms
d <- data.frame(ssp = rownames(d), d)
rownames(d) <- NULL
write.csv(d, "tables/subset_big_table.csv", row.names = FALSE)


# directions - https://stackoverflow.com/questions/71661066/is-there-a-function-in-flextable-to-group-a-few-rows-in-a-table-together-under-a
d <- read.csv("tables/subset_big_table.csv") # makes row names a separate column
d$ssp <- gsub("historical", "recent_past", d$ssp)

d["type"] <- c(
  "PWC, growing season", "PWC, growing season", "PWC, growing season", "PWC, growing season", "PWC, growing season",
  "PWC, hottest period", "PWC, hottest period", "PWC, hottest period", "PWC, hottest period", "PWC, hottest period",
  "Other", "Other", "Other", "Other", "Other"
)
names(d) <- str_replace(names(d), "ssp", "Variable") |> str_replace("United.States", "United States")
d$Variable <- str_replace_all(d$Variable, "_", " ") |>
  str_replace_all(" 3yr", "") |>
  str_replace_all("hot90 ", "") |>
  str_replace("season ", " ") |>
  str_to_title() |>
  str_replace("Ssp585", "SSP5-8.5") |>
  str_replace("Ssp370", "SSP3-7.0") |>
  str_replace("Land", "Cropland")

d <- as_grouped_data(d, groups = c("type"), columns = NULL)

t_flex <- as_flextable(d, hide_grouplabel = TRUE) |>
  colformat_double(i = (2:7), j = (2:8), digits = 2) |>
  colformat_double(i = (8:12), j = (2:8), digits = 2) |>
  colformat_double(i = (13:16), j = (2:8), digits = 0) |>
  colformat_double(i = (17:18), j = (2:8), digits = 2) |>
  set_header_labels(what = "") |>
  color(part = "footer", color = "#800000") |>
  bold(bold = TRUE, part = "header") |>
  align(i = ~ !is.na(type), align = "center") |>
  bold(i = ~ !is.na(type)) |>
  footnote(
    i = 10:14, j = 1,
    value = as_paragraph(
      c(
        "000 ag. workers",
        "000 hectares",
        "000 horsepower (CV)",
        "horsepower (CV) per hectare",
        "horsepower (CV) per ag. worker"
      )
      #              "Source: USDA/ERS")
    ),
    ref_symbols = c("a", "b", "c", "d", "e"),
    part = "body", inline = TRUE
  )

t_flex
outf <- "table3_countries.docx"
save_as_docx(t_flex, values = NULL, path = paste0("tables/", outf))
