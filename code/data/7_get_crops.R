
# this <- system('hostname', TRUE)
# if (this == "LAPTOP-IVSPBGCA") {
# 	setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
# } else {
# 	setwd('/Users/gcn/Google Drive/My Drive/pwc')
# }


library(terra)
library(geodata)

crop_area <- function() {
	outf <- "data-raw/crops/total_crop_area.tif"
	if (file.exists(outf)) return(rast(outf))	
	m <- geodata::crop_monfreda("all", "area_ha", path = "data-raw/crops")
	x <- sum(m, na.rm = TRUE)
	rm(m)
	p <- "data-raw/crops/monfreda/"
	file.rename(file.path(p, "pulsenes_HarvestedAreaHectares.tif"), file.path(p, "pulses_HarvestedAreaHectares.tif"))
	file.rename(file.path(p, "oats_HarvestedAreaHectares.tif"), file.path(p, "oat_HarvestedAreaHectares.tif"))

	writeRaster(x, outf)
}

if (!file.exists("data-raw/crops/total_crop_area.tif"))  crops <- crop_area() 

sacks_calendars <- function(variable) {
	path <- "data-raw/calendar-sacks"
	dir.create(path, FALSE, FALSE)
	outf <- file.path(path, paste0(variable, ".tif"))
	if (file.exists(outf)) return(rast(outf))		
	crops <- sacksCrops()
	x <- lapply(crops, \(i) crop_calendar_sacks(crop = i, path=path))
	nms <- names(x[[1]])
	if (!(variable %in% nms)) stop("variable not good")
	outff <- file.path(path, paste0(nms, ".tif"))
	for (i in 1:length(outff)) {
		y <- rast(lapply(x, \(r) subset(r, i)))
		names(y) <- crops
		writeRaster(y, outff[i], overwrite = TRUE)
	}
	rast(outf)
}

plant_s <- sacks_calendars("plant")
harv_s <- sacks_calendars("harvest")

sacks_aggregated <- function() {
	if (file.exists("data-raw/calendar-sacks/harv_agg.tif")) return()
	
	plant <- rast("data-raw/calendar-sacks/plant.tif")
	harv <- rast("data-raw/calendar-sacks/harvest.tif")
	n <- names(plant)
	i <- grep("(2nd season)", n)
	i <- c(i, grep("(spring)", n))
	harv <- harv[[-i]]
	plant <- plant[[-i]]
	pln <- sapply(strsplit(names(plant), " \\("), \(i)i[1])
	names(harv) <- names(plant) <- pln

	plant <- aggregate(plant, 6, fun=raster::modal, na.rm=TRUE)
	plant <- round(plant)
	writeRaster(plant, "data-raw/calendar-sacks/plant_agg.tif", overwrite=TRUE)
	
	harv <-  aggregate(harv, 6, fun=raster::modal, na.rm=TRUE)
	harv <- round(harv)
	writeRaster(harv, "data-raw/calendar-sacks/harv_agg.tif", overwrite=TRUE)
}

s <- sacks_aggregated()


mean_calendar <- function() {

	outf <- "data-raw/calendar-sacks/growing_season.tif"
#	if (file.exists(outf)) return (rast(outf)) 
	
	## I prefer these ones as we have matching crop area data 
	plant <- rast("data-raw/calendar-sacks/plant_agg.tif")
	harv <- rast("data-raw/calendar-sacks/harv_agg.tif")

	pln <- sapply(strsplit(names(plant), " \\("), \(i)i[1])
	
	# get the crops for which we have calendars
	ff <- list.files("data-raw/crops/monfreda", pattern=".tif", full=TRUE)
	crn <- sapply(strsplit(basename(ff), "_"), \(i)i[1])
	i <- which(crn %in% pln)
	crops <- rast(ff[i])
	names(crops) <- sapply(strsplit(names(crops), "_"), \(i)i[1])
	cat(names(crops))
#	crops <- crop(crops, c(-180,180,-60,90)) |> aggregate(6, sum, na.rm=TRUE) 
	
	crops <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
	  aggregate(6, sum, na.rm=TRUE) |> round()
	
	## fraction of each crop in a cell
	crops <- crops / sum(crops, na.rm=TRUE)

	ss <- NULL
	for (i in 1:nlyr(crops)) {
		# get the days that each crop is in the field
		x <- c(plant[[i]], harv[[i]])
		s <- rangeFill(x, 365, circular=TRUE)
		# multiply with crop area and sum over crops
		sc <- s * crops[[i]]
		if (is.null(ss)) {
			ss <- sc
		} else {
			ss <- ss + sc
		}
	}
	# normalize weights
	season_weights <- ss / sum(ss)

	writeRaster(season_weights, outf, overwrite=TRUE)
}

m <- mean_calendar()