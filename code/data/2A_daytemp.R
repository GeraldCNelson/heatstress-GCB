# Compute mean temperature during the day (removing Antarctica)

library(terra)
library(meteor)
e <- ext(-180, 180, -60, 90)
path_intermediate <- paste0("data-raw/ISIMIP/ISIMIPncfiles/intermediate/")
dir.create(path_intermediate, FALSE, FALSE)

years <- c("1991_2000", "2001_2010", "2041_2050", "2051_2060", "2081_2090", "2091_2100")
ssps <- c("historical", "ssp126", "ssp585")
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")

x <- expand.grid(years[1:6], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))

#test data
ssps <- "ssp585"
years <- c("2041_2050") #, "2051_2060", "2081_2090", "2091_2100")
x <- expand.grid(years[1:2], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))
#-------

tasfun <- function(y, s, m) {
browser()  
  path <- paste0("data-raw/ISIMIP/ISIMIPncfiles/")
  print(paste(y, s, m)); flush.console()
	fn <- list.files(path, pattern = paste0(m, ".*", s, ".*_tasmin_global_.*."), recursive = TRUE, full = TRUE)	
	if (length(fn) == 0) return(paste("no files"))
	fx <- gsub("tasmin", "tasmax", fn) #get the tasmax file names by substituting tasmax for tasmin
	print(fx)
	
	outf <- gsub("nc$", "tif", basename(fn))
	outf <- gsub("tasmin", "tasday", outf)
	outf <- file.path(path_intermediate, outf)
	print(outf)
	#if (file.exists(outf)) return ("done")

	rn <- rast(fn)
	rx <- rast(fx)
	window(rn) <- e
	window(rx) <- e
	lat <- init(rx[[1]], "y")
	doy <- fromDate(time(rn, "days"), "doy")

	readStart(rn)
	readStart(rx)
	readStart(lat)
	
	out <- rast(rn)
	print(paste0("out: ", outf))
	b <- writeStart(out, outf, overwrite=TRUE)
		
	for (i in 1:b$n) {
		vn <- readValues(rn, b$row[i], b$nrows[i], mat=TRUE)
		vx <- readValues(rx, b$row[i], b$nrows[i], mat=TRUE)
		vlat <- readValues(lat, b$row[i], b$nrows[i])
		for (j in 1:nrow(vn)) {
			vn[j,] <- meteor::dayTemp(vn[j,], vx[j,], doy, vlat[j]) # conversion to dayTemp done in meteor
		}
		writeValues(out, vn, b$row[i], b$nrows[i])
	}
	out <- writeStop(out)
	readStop(rn)
	readStop(rx)
	readStop(lat)
	out
}

for (i in 1:nrow(x)) {
	tasfun(y = x[i,1], s = x[i,2], m = x[i,3])	
}

