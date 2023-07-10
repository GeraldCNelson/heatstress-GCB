this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
  setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {
  setwd('/Users/gcn/Google Drive/My Drive/pwc')
}
library(terra)
library(readxl)
library(data.table)
ersdata_machines <- as.data.table(read_xlsx("data-raw/machines/AgTFPInternational2020.xlsx", sheet = "Machinery", skip = 2))
ersdata_machines[, c("Order", "Inc I", "Inc II", "Notes I", "Notes II") := NULL]

indexColsToRemove <- c("1961...11", "1962...12", "1963...13", "1964...14", "1965...15", "1966...16", "1967...17", "1968...18", "1969...19", "1970...20", "1971...21", "1972...22", "1973...23", "1974...24", "1975...25", "1976...26", "1977...27", "1978...28", "1979...29", "1980...30", "1981...31", "1982...32", "1983...33", "1984...34", "1985...35", "1986...36", "1987...37", "1988...38", "1989...39", "1990...40", "1991...41", "1992...42", "1993...43", "1994...44", "1995...45", "1996...46", "1997...47", "1998...48", "1999...49", "2000...50", "2001...51", "2002...52", "2003...53", "2004...54", "2005...55", "2006...56", "2007...57", "2008...58", "2009...59", "2010...60", "2011...61", "2012...62", "2013...63", "2014...64", "2015...65", "2016...66", "2017...67", "2018...68", "2019...69", "2020...70", "...71")
ersdata_machines[, (indexColsToRemove) := NULL]
colsToRename <- c("1961...72","1962...73","1963...74","1964...75","1965...76","1966...77","1967...78","1968...79","1969...80","1970...81","1971...82","1972...83","1973...84","1974...85","1975...86","1976...87","1977...88","1978...89","1979...90","1980...91","1981...92","1982...93","1983...94","1984...95","1985...96","1986...97","1987...98","1988...99","1989...100","1990...101","1991...102","1992...103","1993...104","1994...105","1995...106","1996...107","1997...108","1998...109","1999...110","2000...111","2001...112","2002...113","2003...114","2004...115","2005...116","2006...117","2007...118","2008...119","2009...120","2010...121","2011...122","2012...123","2013...124","2014...125","2015...126","2016...127","2017...128","2018...129","2019...130","2020...131")
newNames <- paste0("X", 1961:2020)
setnames(ersdata_machines, old = colsToRename, new = newNames)

ersdata_labor <- as.data.table(read_xlsx("data-raw/machines/AgTFPInternational2020.xlsx", sheet = "Labor", skip = 2))
ersdata_labor[, c("Order", "Inc I", "Inc II", "Notes I", "Notes II") := NULL]
ersdata_labor[, (indexColsToRemove) := NULL]
newNames <- paste0("X", 1961:2020)
setnames(ersdata_labor, old = colsToRename, new = newNames)

ersdata_land <- as.data.table(read_xlsx("data-raw/machines/AgTFPInternational2020.xlsx", sheet = "Land", skip = 2))
ersdata_land[, c("Order", "Inc I", "Inc II", "Notes I", "Notes II") := NULL]
ersdata_land[, (indexColsToRemove) := NULL]
newNames <- paste0("X", 1961:2020)
setnames(ersdata_land, old = colsToRename, new = newNames)

mach_land_ratio = ersdata_machines[,  .SD, .SDcols = newNames] / ersdata_land[,  .SD, .SDcols = newNames]
mach_land_ratio <- cbind(ersdata_land[, c("FAO", "ISO3", "Country/territory", "Region", "Sub-Region")], mach_land_ratio)
mach_land_ratio_long <- melt(mach_land_ratio, id.vars = c("FAO", "ISO3", "Country/territory", "Region", "Sub-Region"), variable.name = "year",  value.name = "value_ERS", variable.factor = FALSE)
mach_land_ratio_long <- mach_land_ratio_long[order(`Country/territory`, year)]
mach_land_ratio_long[, year := gsub("X", "", year)][, year := as.integer(year)]
ourworlddata <- read.csv("data-raw/machines/machinery-per-agricultural-land.csv")

combined <- merge(mach_land_ratio_long, ourworlddata, by.x = c("ISO3", "year"), by.y = c("Code", "Year"))
combined[, compareRatio := value_ERS/machinery_per_ag_land]

test <- combined[compareRatio < .9,]
write.csv(test, "tables/compareRLratios.csv")
