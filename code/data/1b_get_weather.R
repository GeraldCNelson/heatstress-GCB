# # downloads the .nc files from ISIMIP using the lists created in 1a_get_weather
# this <- system('hostname', TRUE)
# if (this == "LAPTOP-IVSPBGCA") {
#   setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc/")
# } else {
#   setwd('/Users/gcn/Google Drive/My Drive/pwc')
# }

#download the ISIMIP data used for the PWC paper
variables <- c("tasmin", "tasmax", "tas", "hurs", "rsds", "sfcwind") # principal weather variables. pr left out because not used in the GCB PWC paper
yearChoices <- c("2041-2050", "2051-2060", "2081-2090", "2091-2100")
yrChoices <- gsub("-","_", yearChoices)
pats <- c("126", "585", "historical") 
pats <- c("370") 
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

