# Compute average solar radiation during the day (removing Antarctica)

library(terra)
library(meteor)
path_intermediate <- "data-raw/ISIMIP/ISIMIPncfiles/intermediate/"
dir.create(path_intermediate, FALSE, FALSE)
regions <- c("global", "tropical", "S20N35")

years <- c("1991_2000", "2001_2010", "2041_2050", "2051_2060", "2081_2090", "2091_2100")
ssps <- c("historical", "ssp126", "ssp585")
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")
e <- ext(-180, 180, -60, 90)

#test data
ssps <- "ssp585"
years <- c("2041_2050", "2051_2060", "2081_2090", "2091_2100")
# -----

radfun <- function(y, s, m) {
 # browser()
	print(paste(y, m, s)); flush.console()
	if ((m == "") || (s == "")) {
		ff <- list.files(pattern = paste0("_rsds_global_.*.", y, ".nc$"), recursive = TRUE, full.names = TRUE) 
	} else {
		ff <- list.files(pattern = paste0(m, ".*", s, ".*_rsds_global_.*.", y, ".nc$"), recursive = TRUE, full.names = TRUE)
	}

	if (length(ff) == 0) return(paste("no files"))
	print(ff)
	
	print("photoperiod")
	outf <- file.path(path_intermediate, gsub("nc$", "tif", basename(ff[length(ff)])))
	if (file.exists(outf)) return ("done")

	x <- rast(ff[1])
	window(x) <- e
	r <- rast(x[[1:(4*365.25)]])
	pp <- photoperiod(r)

	for (f in ff) {
		outf <- file.path(path_intermediate, gsub("nc$", "tif", basename(f)))
		print(basename(outf)); flush.console()
		if (file.exists(outf)) next
		print("outf exists")
		x <- rast(f)
		window(x) <- e
		x <- (x * 24) / pp
		writeRaster(x, outf)
	}
	tmpFiles(remove = TRUE)
}

	for (y in years) {
		radfun(y, "", "")
	}


