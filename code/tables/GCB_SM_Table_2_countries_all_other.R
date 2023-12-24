library(terra)
terraOptions(verbose = TRUE)
this <- system("hostname", TRUE)
if (grepl("Mac", this, fixed = TRUE)) terraOptions(verbose = TRUE, memfrac = 0.8)

path <- "data/agg/pwc_agg3"

library(data.table)
library(flextable)
library(officer)
library(stringr)
set_flextable_defaults(font.family = "Times New Roman", font.color = "#333333", border.color = "#999999", padding = 4)

# Farm machinery is measured in units of 1000 horsepower. This is divided by cropland (1000 hectares) to give the average machinery use per hectare of agricultural land.
## Source of the data is the first data set at https://www.ers.usda.gov/data-products/international-agricultural-productivity/. This has both machinery, land and agricultural labor individually.
temp <- as.data.table(read.csv("data-raw/machines/ERSmach_land_labor.csv")) # created in ERS_mach_land_labor.R, machinery, land and labor
temp <- temp[year > 2017, ]
temp <- temp[, labor_3yr := mean(ERSvalue_labor), by = "ISO3"][
  , cropland_3yr := mean(ERSvalue_cropland),
  by = "ISO3"
][
  , machinery_3yr := mean(ERSvalue_machinery),
  by = "ISO3"
]
temp <- unique(temp[, c("ISO3", "Country.territory", "labor_3yr", "cropland_3yr", "machinery_3yr")])

temp[, machinery_per_cropland := machinery_3yr / cropland_3yr][, machinery_per_capita := machinery_3yr / labor_3yr]
colsToRound <- c("labor_3yr", "land_3yr", "machinery_3yr")
temp[, (colsToRound) := lapply(.SD, round, digits = 0), .SDcols = colsToRound]

temp[, labor_3yr := labor_3yr] # 000 persons
temp[, cropland_3yr := cropland_3yr] # 000 ha
temp[, machinery_3yr := machinery_3yr] # 000 units (CV) horsepower

write.csv(temp, "tables/SM_table2_countries_all_other.csv", row.names = FALSE)

# directions - https://stackoverflow.com/questions/71661066/is-there-a-function-in-flextable-to-group-a-few-rows-in-a-table-together-under-a

d <- temp
setnames(d, old = names(d), new = c("ISO3", "Name", "Labor", "Cropland", "Machinery", "Machinery per cropland", "Machinery per capita"))

t_flex <- flextable(d) |>
  colformat_double(i = (1:176), j = (3:5), digits = 0) |>
  colformat_double(i = (1:176), j = (6:7), digits = 2) |>
  theme_vanilla() |>
  color(part = "footer", color = "#666666") |>
  align(align = "center", part = "header")

t_flex

save_as_docx(t_flex, values = NULL, path = "tables/SM_table2_countries_all_other.docx")
