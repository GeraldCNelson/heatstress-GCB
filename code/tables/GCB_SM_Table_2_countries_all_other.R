library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (grepl("Mac", this, fixed = TRUE)) terraOptions(verbose = TRUE, memfrac = 0.8)

path <- "data/agg/pwc_agg3"

library(data.table)
library(flextable)
library(officer)
library(stringr)
set_flextable_defaults(font.family = "Times New Roman", font.color = "#333333", border.color = "#999999", padding = 4)

#Farm machinery is measured in units of 1000 horsepower. This is divided by cropland (1000 hectares) to give the average machinery use per hectare of agricultural land.
## Source of the data is the first data set at https://www.ers.usda.gov/data-products/international-agricultural-productivity/. This has both machinery, land and agricultural labor individually. 
temp <- as.data.table(read.csv("data-raw/machines/ERSmach_land_labor.csv")) # created in ERS_mach_land_labor.R, machinery, land and labor
temp <- temp[year >2017,]
temp <- temp [, labor_3yr := mean(ERSvalue_labor), by = "ISO3"][
  , cropland_3yr := mean(ERSvalue_cropland), by = "ISO3"][
    , machinery_3yr := mean(ERSvalue_machinery), by = "ISO3"]
temp <- unique(temp[, c("ISO3", "Country.territory", "labor_3yr", "cropland_3yr", "machinery_3yr"  )])

temp[, machinery_per_cropland := machinery_3yr/cropland_3yr][, machinery_per_capita := machinery_3yr/labor_3yr]
colsToRound <- c("labor_3yr", "land_3yr", "machinery_3yr")
temp[, (colsToRound) := lapply(.SD, round, digits = 0), .SDcols = colsToRound]

temp[, labor_3yr := labor_3yr] # 000 persons
temp[, cropland_3yr := cropland_3yr] # 000 ha
temp[, machinery_3yr := machinery_3yr] # 000 units (CV) horsepower

# x <- merge(zz, temp, by.x = "GID_0", by.y = "ISO3", all.x=TRUE)
#write.csv(x, "tables/table .csv", row.names = FALSE)
#ctrs <- c("Brazil", "China", "France", "Nigeria", "Pakistan", "India", "United States")
# d <- x[x$Country.territory %in% ctrs,-1]
# d$Country.territory <- NULL
# nms <- d[,1]
# d <- t(d[,-1]) # adds enough places after decimal so all numbers are the same
# colnames(d) <- nms
# d <- d[, ctrs]
# d[6:15, ] <- d[c(11:15,6:10), ]	
# d <- d[-grep("ssp126", rownames(d)), ] # remove ssp126
# d <- d[-grep("annual", rownames(d)), ] # remove annual rows
# d <- data.frame(ssp=rownames(d), d)
# rownames(d) <- NULL
write.csv(temp, "tables/SM_table2_countries_all_other.csv", row.names = FALSE)

# directions - https://stackoverflow.com/questions/71661066/is-there-a-function-in-flextable-to-group-a-few-rows-in-a-table-together-under-a

d <- temp
setnames(d, old = names(d), new = c("ISO3","Name", "Labor", "Cropland", "Machinery", "Machinery per cropland", "Machinery per capita"))

t_flex <- flextable(d) |>
  colformat_double(i = (1:176), j = (3:5), digits=0) |> 
  colformat_double(i = (1:176), j = (6:7), digits=2) |> 
  
  theme_vanilla() |> 
  color(part = "footer", color = "#666666") |>
  align(align = "center", part = "header") 

t_flex

save_as_docx(t_flex, values = NULL, path = "tables/SM_table2_countries_all_other.docx")

