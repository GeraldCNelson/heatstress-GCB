
this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
	setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc/data-raw/ISIMIP/")
} else if (this == "Jerry: fill in your value for 'this'") {
	setwd('/Users/gcn/Google Drive/My Drive/pwc/data-raw/ISIMIP/')
} else {
	setwd("/share/spatial03/ISIMIP/")
}

# aggregate over years by time period, model, ssp 


library(terra)

agg_time <- function(y, s, m, nosun=FALSE) {

	yrs <- matrix(c("1991_2000", "2001_2010", "1991_2010", 
					"2041_2050", "2051_2060", "2041_2060", 
					"2081_2090", "2091_2100", "2081_2100"), ncol=3, byrow=TRUE)
	i <- which(y ==yrs[,3])

	if (nosun) {
		dir.create("pwc_agg1_ns", FALSE, FALSE)
		fin1 <- paste0("pwc_ns/pwc_ns_", m, "_", s, "_", yrs[i,1], ".tif") 
		fin2 <- paste0("pwc_ns/pwc_ns_", m, "_", s, "_", yrs[i,2], ".tif") 	
		fout <- paste0("pwc_agg1_ns/pwc_ns_", m, "_", s, "_", yrs[i,3], ".tif")	
	} else {
		dir.create("pwc_agg1", FALSE, FALSE)
		fin1 <- paste0("pwc/pwc_", m, "_", s, "_", yrs[i,1], ".tif") 
		fin2 <- paste0("pwc/pwc_", m, "_", s, "_", yrs[i,2], ".tif") 	
		fout <- paste0("pwc_agg1/pwc_", m, "_", s, "_", yrs[i,3], ".tif")		
	}
	if (file.exists(fout)) return(fout)
	print(fin1); print(fin2); print(fout); flush.console()
	if ((!file.exists(fin1)) | (!file.exists(fin2))) return("error")
	
	r <- rast(c(fin1, fin2))
	
	# first average Feb 28 and Feb 29
	leaps <- grep("-02-29", time(r))
	x <- tapp(r[[c(leaps, leaps-1)]], rep(1:length(leaps), each=2), "mean")
	r[[leaps-1]] <- x
	r <- r[[-leaps]]

	tapp(r, 1:365, "mean", filename=fout)
}

years <- c("1991_2010", "2041_2060", "2081_2100")
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")
ssps <- c("historical", "ssp126", "ssp585")
x <- expand.grid(years[1], ssps[1], models)
x <- rbind(x, expand.grid(years[-1], ssps[-1], models))

i <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID"))
nosun <- isTRUE(commandArgs(trailingOnly=TRUE)[1] == "nosun")
if (i <= nrow(x)) {
	agg_time(x[i,1], x[i,2], x[i,3], nosun)
} else {
	i
}

#sbatch --array=1-25 -p bmh --time=30 --mem=32G --job-name=pwc ~/farm/clusterR.sh ~/heatstress/v2/data/5_agg_time.R

#sbatch --array=1-25 -p bmh --time=30 --mem=32G --job-name=pwc ~/farm/clusterR.sh ~/heatstress/v2/data/5_agg_time.R nosun
