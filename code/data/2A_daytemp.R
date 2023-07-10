
# this <- system('hostname', TRUE)
# if (this == "LAPTOP-IVSPBGCA") {
# 	setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc/data-raw/ISIMIP/")
# } else if (this == "Jerry: fill in your value for 'this'") {
# 	setwd('/Users/gcn/Google Drive/My Drive/pwc/data-raw/ISIMIP/')
# } else {
# 	setwd("/share/spatial03/ISIMIP/")
# }

# Compute mean temperature during the day (removing Antarctica)

library(terra)
library(meteor)
dir.create("intermediate", FALSE, FALSE)

e <- ext(-180, 180, -60, 90)

tasfun <- function(y, s, m) {
	print(paste(y, m, s)); flush.console()
	fn <- list.files(pattern=paste0(m, ".*", s, ".*_tasmin_global_.*.", y, ".nc$"), recursive=TRUE, full=TRUE)	
	if (length(fn) == 0) return(paste("no files"))
	fx <- gsub("tasmin", "tasmax", fn)
	print(fx)
	
	outf <- gsub("nc$", "tif", basename(fn))
	outf <- gsub("tasmin", "tasday", outf)
	outf <- file.path("intermediate", outf)
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
	b <- writeStart(out, outf, overwrite=TRUE)
		
	for (i in 1:b$n) {
		vn <- readValues(rn, b$row[i], b$nrows[i], mat=TRUE)
		vx <- readValues(rx, b$row[i], b$nrows[i], mat=TRUE)
		vlat <- readValues(lat, b$row[i], b$nrows[i])
		for (j in 1:nrow(vn)) {
			vn[j,] <- meteor::dayTemp(vn[j,], vx[j,], doy, vlat[j])
		}
		writeValues(out, vn, b$row[i], b$nrows[i])
	}
	out <- writeStop(out)
	readStop(rn)
	readStop(rx)
	readStop(lat)
	out
}

years <- c("1991_2000", "2001_2010", "2041_2050", "2051_2060", "2081_2090", "2091_2100")
ssps <- c("historical", "ssp126", "ssp585")
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")

#test data
ssps <- "ssp370"
models = "ukesm"
years <- c("2001_2010", "2041_2050", "2051_2060", "2081_2090", "2091_2100")

x <- expand.grid(years[1:2], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))

i <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID"))
if (i <= nrow(x)) {
	tasfun(x[i,1], x[i,2], x[i,3])	
} else {
	i
}

#sbatch --array=1-50 -p bmh --time=180 --mem=32G --job-name=srad ~/farm/clusterR.sh ~/heatstress/v2/data/2A_daytemp.R

