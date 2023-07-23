# compute WGBT

library(terra)
library(meteor)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (this == "MacBook-Pro-M1X.local") terraOptions(verbose = TRUE, memfrac = 0.8) # useful for Macs because they have better memory management

path_intermediate <- "data-raw/ISIMIP/ISIMIPncfiles/intermediate/"
ncfiles <- "data-raw/ISIMIP/ISIMIPncfiles/"

years <- c("1991_2000", "2001_2010", "2041_2050", "2051_2060", "2081_2090", "2091_2100")
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")
ssps <- c("historical", "ssp126", "ssp370", "ssp585")
x <- expand.grid(years[1:4], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))

nosun <- FALSE # variable to determine where solar radiation value is set to ISIMIP data (FALSE) or zero to simulate complete shade (TRUE)

#test data
ssps <- "ssp585"
years <- c("2041_2050", "2051_2060", "2081_2090", "2091_2100")# -----
x <- expand.grid(years[1:2], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))
# end test data -----

compute_wbgt <- function(y, s, m, nosun=FALSE) {
#browser()
	if (nosun) {
		dir.create("data/wbgt_ns", FALSE, FALSE)
		fout <- paste0("data/wbgt_ns/wbgt_ns_", m, "_", s, "_", y, ".tif") 	
	} else {
		dir.create("data/wbgt", FALSE, FALSE)
		fout <- paste0("data/wbgt/wbgt_", m, "_", s, "_", y, ".tif") 
	}
	if (file.exists(fout)) return(fout)
	print(fout); flush.console()
	
	ff <- list.files(ncfiles, pattern = paste0(m, ".*", s, ".*", y, ".*\\.nc$"), recursive = TRUE, full.names = TRUE)
#	vars <- c("tas", "hurs", "sfcwind")	
	vars <- c("hurs", "sfcwind")	
	ff <- lapply(paste0(vars, "_"), \(v) grep(v, ff, value=TRUE)) |> unlist() |> as.vector()	# "\" here means a function
	if (length(ff) != 2) {
		print("error: files missing")
		return(ff)
	}
	m <- rast("data-raw/mask.tif") # land only mask
	e <- ext(m)
	#e <- ext(-180, 180, -60, 67)
	x <- lapply(ff, \(f) {r <- rast(f); window(r) <- e; r })


	if (nosun) {
		x$rsds <- init(rast(x[[1]]), 0)
	} else {
		fsds <- gsub("hurs", "rsds", grep("hurs", basename(ff), value=TRUE))
		fsds <- file.path(path_intermediate, gsub("nc$", "tif", fsds))
		x$rsds <- rast(fsds)
		window(x$rsds) <- e
	}

	tas <- gsub("hurs", "tasday", grep("hurs", basename(ff), value=TRUE))
	tas <- gsub("nc$", "tif", tas)
	tas <- file.path(path_intermediate, tas)

	tmp <- rast(tas)
	window(tmp) <- e
	x$tmp <- tmp
		
	d <- sds(x)
	names(d) <- c('rhum', 'wind', 'srad', 'temp')
	
	WBGT(d, kelvin=TRUE, mask=m, filename=fout, overwrite = TRUE, steps=16)
	tmpFiles(remove = TRUE)
}

for (i in 1: nrow(x)) {
	compute_wbgt(y = x[i,1], s = x[i,2], m = x[i,3], nosun)
} 
