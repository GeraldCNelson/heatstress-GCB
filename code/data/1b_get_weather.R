# # downloads the .nc files from ISIMIP using the lists created in 1a_get_weather
library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (this == "MacBook-Pro-M1X.local") terraOptions(verbose = TRUE, memfrac = 0.8)

#download the ISIMIP data used for the PWC paper
variables <- c("tasmin", "tasmax", "tas", "hurs", "rsds", "sfcwind") # principal weather variables. pr left out because not used in the GCB PWC paper
pats <- c("126", "585", "historical") 
yearChoices <- c("2041-2050", "2051-2060", "2081-2090", "2091-2100")

# test data
pats <- c("585") 
variables <- c("tasmin", "tasmax", "rsds", "hurs", "sfcwind")
yearChoices <- c( "2081_2090", "2091_2100")
yrChoices <- gsub("-","_", yearChoices)

ncfiles <- "data-raw/ISIMIP/ISIMIPncfiles/"
options(timeout = 3600)

for (pat in pats) {
  destdir <- paste0(ncfiles, pat, "/")
  if (!dir.exists(destdir)) dir.create(destdir, recursive = FALSE) 
  ff <- list.files("data-raw/ISIMIP/filelists", pattern = pat, full = TRUE)
    for (f in ff) {
       print(f); flush.console()
    d <- readLines(f)
    d <- d[grepl(paste(variables, collapse = "|"), d)]
    d <- d[grepl(paste(yrChoices, collapse = "|"), d)]
    
    if (pat == "historical") {
      d <- d[as.numeric(substr(d, nchar(d)-11, nchar(d)-8)) > 1990]
    }
    for (i in 1:length(d)) {
      outf <- paste0(destdir, basename(d[i]))
      print(outf)
      if (!file.exists(outf)) {
        download.file(d[i], outf, mode="wb")
      }
    }
  }
}


#ln -s /Volumes/ExtremeSSD2/ISIMIP/ISIMIPncfiles /Users/gcn/Documents/workspace/heatstress_GCB/data-raw/ISIMIP/

