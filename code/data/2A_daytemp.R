# Compute mean temperature during the day (removing Antarctica)

library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (this == "MacBook-Pro-M1X.local") terraOptions(verbose = TRUE, memfrac = 0.8)

library(meteor)

e <- ext(-180, 180, -60, 90)
path <- paste0("data-raw/ISIMIP/ISIMIPncfiles")
path_intermediate <- paste0("data-raw/ISIMIP/ISIMIPncfiles/intermediate")
dir.create(path_intermediate, FALSE, FALSE)

years <- c("1991_2000", "2001_2010", "2041_2050", "2051_2060", "2081_2090", "2091_2100")
ssps <- c("historical", "ssp126", "ssp585")
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")

x <- expand.grid(years[1:2], ssps[1], models) # do historical
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models)) # add other periods

#test data-----
ssps <- "ssp585"
years <- c("2041_2050", "2051_2060", "2081_2090", "2091_2100") # needs to be pairs of 10 year combos
x <- expand.grid(years[1:2], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))
# end test data-------

tasdayfun <- function(y, s, m) {
  print(paste(y, s, m)); flush.console()
	fn <- list.files(path, pattern = paste0(m, ".*", s, ".*_tasmin_global_.*.", y, ".nc$"), recursive = TRUE, full = TRUE)	
	
	if (length(fn) == 0) return(paste("no files"))
	fx <- gsub("tasmin", "tasmax", fn) #get the tasmax file names by replacing tasmin with tasmax
	print(fx)

	outf <- gsub("nc$", "tif", basename(fn))
	outf <- gsub("tasmin", "tasday", outf)
	outf <- file.path(path_intermediate, outf)
	print(paste0("outf: ", outf))
	if (file.exists(outf)) return("done")

	rn <- rast(fn)
	rx <- rast(fx)
	window(rn) <- e
	window(rx) <- e
	lat <- init(rx[[1]], "y")
	doy <- fromDate(time(rn, "days"), "doy")

	readStart(rn)
	readStart(rx)
	readStart(lat)
	
	out <- rast(rn) # create empty raster with rn dimensions
	print(paste0("out: ", outf))
	b <- writeStart(out, outf, overwrite=TRUE)
	for (i in 1:b$n) {
	  system.time(	vn <- readValues(rn, b$row[i], b$nrows[i], mat=TRUE)) # 9 sec
		vx <- readValues(rx, b$row[i], b$nrows[i], mat=TRUE) # 9 sec
		vlat <- readValues(lat, b$row[i], b$nrows[i])
		for (j in 1:nrow(vn)) {
		  system.time(vn[j,] <- meteor::dayTemp(vn[j,], vx[j,], doy, vlat[j])) # conversion to dayTemp done in the meteor package
		}
		writeValues(out, vn, b$row[i], b$nrows[i])
	}
#	browser()
	out <- writeStop(out)
	readStop(rn)
	readStop(rx)
	readStop(lat)
	out
}

for (i in 1:nrow(x)) {
  y = x[i,1]; s = x[i,2]; m = x[i,3]
  system.time(tasdayfun(y, s, m))
}

