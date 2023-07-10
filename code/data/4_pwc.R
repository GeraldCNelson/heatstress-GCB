
this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
	setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc/data-raw/ISIMIP/")
} else if (this == "Jerry: fill in your value for 'this'") {
	setwd('/Users/gcn/Google Drive/My Drive/pwc/data-raw/ISIMIP/')
} else {
	setwd("/share/spatial03/ISIMIP/")
}


library(terra)
library(meteor)


compute_pwc <- function(y, s, m, nosun=FALSE) {
	if (nosun) {
		dir.create("pwc_ns", FALSE, FALSE)
		fin <- paste0("wbgt_ns/wbgt_ns_", m, "_", s, "_", y, ".tif") 
		fout <- gsub("wbgt_ns/wbgt_ns", "pwc_ns/pwc_ns", fin)	
	} else {
		dir.create("pwc", FALSE, FALSE)
		fin <- paste0("wbgt/wbgt_", m, "_", s, "_", y, ".tif") 
		fout <- gsub("wbgt/wbgt", "pwc/pwc", fin)
	}
	if (file.exists(fout)) return(fout)
	print(fin); print(fout); flush.console()
	if (!file.exists(fin)) return("error")
	
	r <- rast(fin)
	pwc(r, filename=fout)
}

years <- c("1991_2000", "2001_2010", "2041_2050", "2051_2060", "2081_2090", "2091_2100")
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")
ssps <- c("historical", "ssp126", "ssp585")
x <- expand.grid(years[1:2], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))

nosun <- isTRUE(commandArgs(trailingOnly=TRUE)[1] == "nosun")
i <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID"))

if (i <= nrow(x)) {
	compute_pwc(x[i,1], x[i,2], x[i,3], nosun)
} else {
	i
}

#sbatch --array=1-50 -p bmh --time=15 --mem=32G --job-name=pwc ~/farm/clusterR.sh ~/heatstress/v2/data/4_pwc.R

#sbatch --array=1-50 -p bmh --time=15 --mem=32G --job-name=pwc ~/farm/clusterR.sh ~/heatstress/v2/data/4_pwc.R nosun
