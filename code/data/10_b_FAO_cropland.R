# these results are not used in the GCB heatstress paper but the code is included for comparison purposes
library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (grepl("Mac", this, fixed=TRUE)) terraOptions(verbose = TRUE, memfrac = 0.8)


library(terra)
library(geodata)

FAO_landuse <- function() {
	outf <- "data-raw/crops/fao_landuse.rds"
	if (file.exists(outf)) return(readRDS(outf))
	url = "https://fenixservices.fao.org/faostat/static/bulkdownloads/Inputs_LandUse_E_All_Data_(Normalized).zip"
	f = paste0("data-raw/crops/", basename(url))
	if (!file.exists(f)) {
		dir.create(dirname(f), FALSE, TRUE)
		download.file(url, f)
		unzip(f, exdir = "data-raw/crops")
	}
	fc <- gsub("zip$", "csv", f)
	d <- read.csv(fc, encoding = "latin1")
	
	d <- d[d$Item %in% c("Agricultural land", "Cropland", "Arable land"), ]  
	d <- d[d$Year >= 2018, ]  
	#unit = "1000 ha"

	a <- aggregate(d[, "Value", drop = FALSE], d[, c("Area", "Item")], mean, na.rm = TRUE)
	
# match FAO names with ISO codes
	cc <- na.omit(geodata::country_codes()[, c("NAME_FAO", "ISO3")])
	# there is no Sudan, but we have 
	#cc$NAME_FAO[cc$ISO3 == "SDN"] <- "Sudan (former)"
	# probably need to subtract South Sudan from this number. 

	m <- merge(a, cc, by = 1, all.x = TRUE)
	m <- m[!is.na(m$ISO3), -1]
	m <- reshape(m, direction="wide", idvar = "ISO3", timevar =" Item") 
	names(m) <- gsub("Value.", "", names(m))
	saveRDS(m, outf)
	m
}

FAO_landuse()
