this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
  setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {
  setwd('/Users/gcn/Google Drive/My Drive/pwc')
}
library(terra)
library(readxl)
library(data.table)
path_machines <- "data-raw/machines/"
cleanup <- function(sheetname) {
  url <- "https://www.ers.usda.gov/webdocs/DataFiles/51270/AgTFPInternational2020_long.xlsx?v=8337"
  f = paste0("data-raw/machines/", basename(url))
  if (!file.exists(f)) {
    dir.create(dirname(f), FALSE, TRUE)
    download.file(url, f)
    unzip(f, exdir = "data-raw/machines")
  }
  temp <- as.data.table(read_xlsx(paste0(path_machines, "AgTFPInternational2020.xlsx"), sheet = sheetname, range = "B3:F182", na = "NA")) # names, etc
  temp <- cbind(temp, as.data.table(read_xlsx(paste0(path_machines, "AgTFPInternational2020.xlsx"), sheet = sheetname, range = "BT3:EA182", na = "NA"))) # quantity data
  oldNames <- as.character(1961:2020)
  newNames <- paste0("X", 1961:2020)
  setnames(temp, old = oldNames, new = newNames, skip_absent = T)
  temp[, (newNames) := lapply(.SD, as.numeric),
       .SDcols = newNames]
  temp_long <- melt(temp, id.vars = c("FAO", "ISO3", "Country/territory", "Region", "Sub-Region"), variable.name = "year",  value.name = paste0("ERSvalue_", tolower(sheetname)), variable.factor = FALSE)
  temp_long[, year := gsub("X","", year)]
}

ersdata_machines <- cleanup(sheetname = "Machinery") # units - Farm inventories of farm machinery, measured in thousands of metric horsepower (1000 CV) in tractors, combine-threshers, and milking machines
ersdata_labor <- cleanup(sheetname = "Labor") # units - Number of economically active adults (male & female) primarily employed in agriculture, 1000 persons
ersdata_land <- cleanup(sheetname = "Land") # units - Total cropland (including arable land and land in permanent crops), 1000 hectares

combined <- Reduce(merge, list(ersdata_machines, ersdata_land, ersdata_labor))
combined <- combined[!is.na(ISO3)] 
combined <- combined[!is.na(ERSvalue_labor)][!is.na(ERSvalue_land)][!is.na(ERSvalue_machinery)]
combined[,mech_land_ratio := ERSvalue_machinery/ERSvalue_land][,mech_labor_ratio := ERSvalue_machinery/ERSvalue_labor]
write.csv(combined, "data-raw/machines/ERSmach_land_labor.csv", row.names = FALSE)

#units
#labor - 1000 persons economically active in agriculture, 15+ yrs, male & female
#machinery - Metric horsepower (1000 CV) of farm machinery in use (includes tractors, harvester-threshers, milking machines, water pumps)
#land- 1000 hectares of rainfed-cropland-equivalents (rainfed cropland, irrigated cropland and pasturement pasture, weighted by relative quality - see Land Weights)

#Land Weights - available at "data-raw/machines/AgTFPInternational2020.xlsx", sheet = 'Land weights')
# Region	Rainfed Cropland	Permanent Pasture	Irrigated Cropland	
# Western & Sahel Africa	1.0000	0.0155	4.1322	
# Central Africa	1.0000	0.0155	2.1692	
# Eastern & Horn Africa	1.0000	0.0155	2.0661	
# Southern & SACU Africa	1.0000	0.0155	1.7422	
# SSA	1.0000	0.0155	2.3339	
# Central America	1.0000	0.0298	1.6051	
# Caribbean 	1.0000	0.0298	1.6260	
# South America	1.0000	0.0298	1.9342	
# LAC	1.0000	0.0298	1.7949	
# NE Asia, LDC & DC	1.0000	0.0566	1.5408	
# Southeast Asia	1.0000	0.0566	1.6340	
# South Asia	1.0000	0.0566	2.7778	
# ASIA	1.0000	0.0566	1.9349	
# Western Asia	1.0000	0.0239	2.6247	
# Central Asia	1.0000	0.0239	1.9048	
# Northern Africa	1.0000	0.0239	7.8261	
# CWANA	1.0000	0.0239	5.1382	
# Eastern & Central Europe	1.0000	0.0942	1.5699	
# Northern Europe	1.0000	0.0942	1.0010	
# Southern Europe	1.0000	0.0942	1.9724	
# Western Europe	1.0000	0.0942	1.2788	
# North America	1.0000	0.0942	2.1882	
# Oceania	1.0000	0.0942	2.8571	
# DC	1.0000	0.0942	2.0622	
# 
# DC 	Developed countries			
# Transition	Transition economics of Eastern Europe and the former Soviet Union			
# SSA	Sub-Saharan Africa			
# ASIA	Asia, except West Asia			
# WANA	West Asia & North Africa			
# LAC	Latin American and the Caribbean			

