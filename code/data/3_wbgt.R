
this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
  setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc/data-raw/ISIMIP/")
} else {
#  setwd('/Users/gcn/Google Drive/My Drive/pwc/data-raw/ISIMIP/')
  setwd("/Volumes/ExtremeSSD2/ISIMIP/")
}

# compute WGBT

library(terra)
library(meteor)


compute_wbgt <- function(y, s, m, nosun=FALSE) {
	if (nosun) {
		dir.create("wbgt_ns", FALSE, FALSE)
		fout <- paste0("wbgt_ns/wbgt_ns_", m, "_", s, "_", y, ".tif") 	
	} else {
		dir.create("wbgt", FALSE, FALSE)
		fout <- paste0("wbgt/wbgt_", m, "_", s, "_", y, ".tif") 
	}
	if (file.exists(fout)) return(fout)
	print(fout); flush.console()
	
	ff <- list.files(pattern=paste0("^", m, ".*", s, ".*", y, ".*\\.nc$"), recursive=TRUE, full=TRUE)
#	vars <- c("tas", "hurs", "sfcwind")	
	vars <- c("hurs", "sfcwind")	
	ff <- lapply(paste0(vars, "_"), \(v) grep(v, ff, value=TRUE)) |> unlist() |> as.vector()	
	if (length(ff) != 2) {
		print("error: files missing")
		return(ff)
	}
	m <- rast("mask.tif") # land only mask
	e <- ext(m)
	#e <- ext(-180, 180, -60, 67)
	x <- lapply(ff, \(f) {r <- rast(f); window(r) <- e; r })


	if (nosun) {
		x$rsds <- init(rast(x[[1]]), 0)
	} else {
		fsds <- gsub("hurs", "rsds", grep("hurs", basename(ff), value=TRUE))
		fsds <- file.path("intermediate", gsub("nc$", "tif", fsds))
		x$rsds <- rast(fsds)
		window(x$rsds) <- e
	}

	tas <- gsub("hurs", "tasday", grep("hurs", basename(ff), value=TRUE))
	tas <- gsub("nc$", "tif", tas)
	tas <- file.path("intermediate", tas)

	tmp <- rast(tas)
	window(tmp) <- e
	x$tmp <- tmp
		
	d <- sds(x)
	names(d) <- c('rhum', 'wind', 'srad', 'temp')
	
	WBGT(d, kelvin=TRUE, mask=m, filename=fout, overwrite=TRUE, steps=16)
}

years <- c("1991_2000", "2001_2010", "2041_2050", "2051_2060", "2081_2090", "2091_2100")
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")
ssps <- c("historical", "ssp126", "ssp370", "ssp585")

#test data
ssps <- "ssp370"
models = "ukesm"
years <- "2041_2050"

x <- expand.grid(years[1:2], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))

i <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID"))
nosun <- isTRUE(commandArgs(trailingOnly=TRUE)[1] == "nosun")


if (i <= nrow(x)) {
	compute_wbgt(x[i,1], x[i,2], x[i,3], nosun)
} else {
	i
}


#sbatch --array=1-50 -p bmh --time=120 --mem=32G --job-name=wgbt ~/farm/clusterR.sh ~/heatstress/v2/data/3_wbgt.R

#sbatch --array=1-50 -p bmh --time=120 --mem=32G --job-name=wgbt ~/farm/clusterR.sh ~/heatstress/v2/data/3_wbgt.R nosun
