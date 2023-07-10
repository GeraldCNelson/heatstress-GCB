# Compute average solar radiation during the day (removing Antarctica)

this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
	setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc/data-raw/ISIMIP/")
} else {
#  setwd('/Users/gcn/Google Drive/My Drive/pwc/data-raw/ISIMIP/')
setwd("/Volumes/ExtremeSSD2/ISIMIP/ISIMIPncfiles/")
  }

library(terra)
library(meteor)
library(rslurm)
dir.create("intermediate", FALSE, FALSE)

e <- ext(-180, 180, -60, 90)


radfun <- function(y, s, m) {
  browser()
	print(paste(y, m, s)); flush.console()
	if ((m == "") || (s=="")) {
		ff <- list.files(pattern=paste0("_rsds_global_.*.", y, ".nc$"), recursive=TRUE, full=TRUE) 
	} else {
		ff <- list.files(pattern=paste0(m, ".*", s, ".*_rsds_global_.*.", y, ".nc$"), recursive=TRUE, full=TRUE) 
	}

	if (length(ff) == 0) return(paste("no files"))
	print(ff)
	
	print("photoperiod")
	outf <- file.path("intermediate", gsub("nc$", "tif", basename(ff[length(ff)])))
	if (file.exists(outf)) return ("done")

	x <- rast(ff[1])
	window(x) <- e
	r <- rast(x[[1:(4*365.25)]])
	pp <- photoperiod(r)

	for (f in ff) {
		outf <- file.path("intermediate", gsub("nc$", "tif", basename(f)))
		print(basename(outf)); flush.console()
		if (file.exists(outf)) next
		x <- rast(f)
		window(x) <- e
		x <- (x * 24) / pp
		writeRaster(x, outf)
	}
}


years <- c("1991_2000", "2001_2010", "2041_2050", "2051_2060", "2081_2090", "2091_2100")
ssps <- c("historical", "ssp126", "ssp585")
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")

#test data
ssps <- "ssp370"
models = "ukesm"
years <- "2041_2050"
i <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID"))
if (is.na(i)) {
	for (y in years) {
		radfun(y, "", "")
	}
} else {
	x <- expand.grid(years[1:2], ssps[1], models)
	x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))
	if (i <= nrow(x)) {
		radfun(x[i,1], x[i,2], x[i,3])	
	} else {
		i
	}
}

#sbatch --array=1-50 -p bmh --time=30 --mem=32G --job-name=srad ~/farm/clusterR.sh ~/heatstress/v2/data/2b_fix_radiation.R

