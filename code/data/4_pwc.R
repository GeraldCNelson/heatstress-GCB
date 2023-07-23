# 
# this <- system('hostname', TRUE)
# if (this == "LAPTOP-IVSPBGCA") {
# 	setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc/data-raw/ISIMIP/")
# } else if (this == "Jerry: fill in your value for 'this'") {
# 	setwd('/Users/gcn/Google Drive/My Drive/pwc/data-raw/ISIMIP/')
# } else {
# 	setwd("/share/spatial03/ISIMIP/")
# }


library(terra)
library(meteor)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (this == "MacBook-Pro-M1X.local") terraOptions(verbose = TRUE, memfrac = 0.8)

years <- c("1991_2000", "2001_2010", "2041_2050", "2051_2060", "2081_2090", "2091_2100")
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")
ssps <- c("historical", "ssp126", "ssp585")
nosun <- FALSE # variable to determine where solar radiation value is set to ISIMIP data (FALSE) or zero to simulate complete shade (TRUE)
x <- expand.grid(years[1:4], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))

#test data
ssps <- "ssp585"
years <- c("2041_2050", "2051_2060", "2081_2090", "2091_2100")# -----
x <- expand.grid(years[1:2], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))
# end test data -----

compute_pwc <- function(y, s, m, nosun=FALSE) {
# browser()
	if (nosun) {
		dir.create("data/pwc_ns", FALSE, FALSE)
		fin <- paste0("data/wbgt_ns/wbgt_ns_", m, "_", s, "_", y, ".tif") 
		fout <- gsub("data/wbgt_ns/wbgt_ns", "data/pwc_ns/pwc_ns", fin)	
	} else {
		dir.create("data/pwc", FALSE, FALSE)
		fin <- paste0("data/wbgt/wbgt_", m, "_", s, "_", y, ".tif") 
		fout <- gsub("data/wbgt/wbgt", "data/pwc/pwc", fin)
	}
	if (file.exists(fout)) return(fout)
	print(fin); print(fout); flush.console()
	if (!file.exists(fin)) return("error")
	
	r <- rast(fin)
	pwc(r, filename=fout)
}

for (i in 1:nrow(x)) {
  compute_pwc(y = x[i,1], s = x[i,2], m = x[i,3], nosun)
}
