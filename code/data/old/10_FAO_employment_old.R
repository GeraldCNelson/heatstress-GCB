
this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
	setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {
# now if you can set this to the Google driver folder...
	setwd('/Users/gcn/Google Drive/My Drive/pwc')
}


###
#!!!  need dev-geodata and dev-terra from github for the below
###

library(terra)
library(geodata)




FAO_employment <- function() {
#employment ------
	outf <- "data-raw/employment/clean_employment.rds"
	if (file.exists(outf)) return(readRDS(outf))
	url = "https://fenixservices.fao.org/faostat/static/bulkdownloads/Employment_Indicators_Agriculture_E_All_Data_(Normalized).zip"
	f = paste0("data-raw/employment/", basename(url))
	if (!file.exists(f)) {
		dir.create(dirname(f), FALSE, TRUE)
		download.file(url, f)
		unzip(f, exdir = "data-raw/employment")
	}
	fc <- gsub("zip$", "csv", f)
	d <- read.csv(fc, encoding = "latin1")
	
#RH: I would use a more recent year & *perhaps* match with FAO crop area, not with Monfreda
# but even when matching with Monfreda, which is consisent with the rest of the analysis, 
# it makes more sense to use current numbers; here using the last three years available: 2018-2020
	d <- d[d$Sex == "Total" & d$Year > 2017, ] 
	d <- d[d$Indicator == "Employment in agriculture, forestry and fishing - ILO modelled estimates", ] 
# number of people employed in Ag by country
	x <- d[, c("Area", "Value")]
	x$persons = x$Value * 1000
	x$Value <- NULL
	# average over years
	x <- aggregate(x[, "persons", drop=FALSE], x[, "Area", drop=FALSE], mean, na.rm=TRUE)
	
# match FAO names with ISO codes
	cc <- na.omit(geodata::country_codes()[, c("NAME_FAO", "ISO3")])
	# there is no Sudan, but we have 
	cc$NAME_FAO[cc$ISO3 == "SDN"] <- "Sudan (former)"
	# probably need to subtract South Sudan from this number. 

	m <- merge(cc, x, by=1, all.x=TRUE)
	m$persons[m$ISO3 == "SDN"] <- m$persons[m$ISO3 == "SDN"] - m$persons[m$ISO3 == "SSD"]
	# French Guyana is largish country with no FAO data as it is part of France
	# assume (based on population size) that it is half that of Suriname 
	m$persons[m$ISO3 == "GUF"] <- m$persons[m$ISO3 == "SUR"] / 2
	m$persons[m$ISO3 == "FRA"] <- m$persons[m$ISO3 == "FRA"] - m$persons[m$ISO3 == "GUF"]
	saveRDS(m, outf)
	m
}

get_labor <- function() {
	outf <- "data-raw/labor.tif"
#	if (file.exists(outf)) return(rast(outf))
	
	emp <- FAO_employment()

	w <- geodata::world(path="data-raw/gadm")
	w <- merge(w, emp, by.x="GID_0", by.y="ISO3", all.x=TRUE)

	# created with "crop_data.R"
	crps <- rast("data-raw/crops/total_crop_area.tif")
	w$crparea <- extract(crps, w, "sum", na.rm=TRUE, ID=FALSE)
	w$dens <- w$persons / w$crparea
	w$dens[!is.finite(w$dens)] <- NA
	w$dens[w$dens > 15] <- NA # Djibouti and Hong Kong, huge outliers
	# a few very small countries
	w$dens[is.na(w$dens)] <- median(w$dens, na.rm=TRUE)
	w$dens[w$GID_0 %in% c("ATA", "GRL")] <- NA

	#plot(w, "dens", breaks=c(0,0.1,.5,1,2,6))

	labor <- rasterize(w, crps, "dens")
	# just to make sure we do not loose any grid cells on the coast line
	# I do not think this is needed, but can't hurt
	labor <- focal(labor, w=5, fun=mean, na.policy="only")
	labor <- subst(labor, NA, median(w$dens, na.rm=TRUE))
	labor <- labor * crps
	writeRaster(labor, outf, overwrite=TRUE, names="aglabor")
}

lab <- get_labor()
#plot(lab)
#plot(lab>0)