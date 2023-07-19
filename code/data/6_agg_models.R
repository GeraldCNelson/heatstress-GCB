
# this <- system('hostname', TRUE)
# if (this == "LAPTOP-IVSPBGCA") {
# 	setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc/data-raw/ISIMIP/")
# } else if (this == "Jerry: fill in your value for 'this'") {
# 	setwd('/Users/gcn/Google Drive/My Drive/pwc/data-raw/ISIMIP/')
# } else {
# 	setwd("/share/spatial03/ISIMIP/")
# }

# aggregate over models, by time-period, ssp 


library(terra)

agg_gcm <- function(y, s, nosun=FALSE) {
	if (nosun) {
		dir.create("data/agg/pwc_agg2_ns", FALSE, FALSE)
		ff <- list.files("data/agg/pwc_agg1_ns", pattern=paste0(s, ".*", y, ".*\\.tif$"), recursive = TRUE, full.names = TRUE)
		fout <- paste0("data/agg/pwc_agg2_ns/pwc_ns_", s, "_", y, ".tif")		
	} else {
		dir.create("data/agg/pwc_agg2", FALSE, FALSE)
		ff <- list.files("data/agg/pwc_agg1", pattern=paste0(s, ".*", y, ".*\\.tif$"), recursive = TRUE, full.names = TRUE)
		fout <- paste0("data/agg/pwc_agg2/pwc_", s, "_", y, ".tif")	
	}
	if (file.exists(fout)) return(fout)
	s <- rast(ff)
	tapp(s, 1:365, mean, filename=fout)
}

years <- c("1991_2010", "2041_2060", "2081_2100")
ssps <- c("historical", "ssp126", "ssp585")

ssps <- "ssp370"
years <- c("2041_2060", "2081_2100")

x <- expand.grid(years[2], ssps[1])
x <- rbind(x, expand.grid(years[-1], ssps[-1]))

nosun <- isTRUE(commandArgs(trailingOnly=TRUE)[1] == "nosun")

for (i in 1:nrow(x)) {
  agg_gcm(y = x[i,1], s = x[i,2], nosun)
} 
