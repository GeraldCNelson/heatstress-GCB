# aggregate over models, by time-period, ssp 

library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (this == "MacBook-Pro-M1X.local") terraOptions(verbose = TRUE, memfrac = 0.8)
nosun <- FALSE # variable to determine where solar radiation value is set to ISIMIP data (FALSE) or zero to simulate complete shade (TRUE)

years <- c("1991_2010", "2041_2060", "2081_2100")
ssps <- c("historical", "ssp126", "ssp585")

x <- expand.grid(years[2], ssps[1])
x <- rbind(x, expand.grid(years[-1], ssps[-1]))

#test data
ssps <- "ssp585"
years <- c("2041_2060", "2081_2100")
x <- expand.grid(years[1:2], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))
# end test data -----

agg_gcm <- function(y, s, nosun=FALSE) {
	if (nosun) {
		dir.create("data/agg/pwc_agg2_ns", FALSE, FALSE)
		ff <- list.files("data/agg/pwc_agg1_ns", pattern = paste0(s, ".*", y, ".*\\.tif$"), recursive = TRUE, full.names = TRUE)
		fout <- paste0("data/agg/pwc_agg2_ns/pwc_ns_", s, "_", y, ".tif")		
	} else {
		dir.create("data/agg/pwc_agg2", FALSE, FALSE)
		ff <- list.files("data/agg/pwc_agg1", pattern = paste0(s, ".*", y, ".*\\.tif$"), recursive = TRUE, full.names = TRUE)
		fout <- paste0("data/agg/pwc_agg2/pwc_", s, "_", y, ".tif")	
	}
	if (file.exists(fout)) return(fout)
	s <- rast(ff)
	tapp(s, 1:365, mean, filename = fout)
}

for (i in 1:nrow(x)) {
  print(paste0(i, " of ", nrow(x)))
  y = x[i,1]; s = x[i,2]
  print(paste0(y, " ", s))
  agg_gcm(y, s, nosun)
} 
