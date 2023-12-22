# create lists of nc files to download from ISIMIP

# install packages that are not already installed
list.of.needed.packages <- c("terra", "data.table", "rvest", "xml2")
new.packages <- list.of.needed.packages[!(list.of.needed.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
###

library(rvest)
library(xml2)
library(data.table)
library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (grepl("Mac", this, fixed = TRUE)) terraOptions(verbose = TRUE, memfrac = 0.8) # for Macs with Mac silicon, speeds up process

pats <- c("ssp370") # all ISIMIP scenarios
pats_hist <- c("historical")
models <- c("gfdl-esm4", "ipsl-cm6a-lr", "mpi-esm1-2-hr", "mri-esm2-0", "ukesm1-0-ll")
yearChoices <- c("2041-2050", "2051-2060")
yrChoices <- gsub("-","_", yearChoices)
yearChoices_hist <- c("1991-2000", "2001-2010")
yrChoices_hist <- c("1991_2000", "2001_2010")
# create the download links
# first get the list of files from ISIMIP
dpath <- "https://files.isimip.org/ISIMIP3b/InputData/climate/atmosphere/bias-adjusted/global/daily/"
destpath <- "data-raw/ISIMIP/filelists/"

createlinkfiles <- function(model, pat) {
  pg <- read_html(paste0(dpath, pat, "/", toupper(model), "/"))
  a_tags <- html_nodes(pg, "a")
  hrefs <- html_attr(a_tags, "href")
  hrefs <- as.data.table(hrefs[-1])
  hrefs <- hrefs[!grep(".json", V1),][!is.na(V1),]
  hrefs[, V1 := paste0(dpath, pat, "/", toupper(model), "/", V1)]
  setnames(hrefs, old = "V1", new = "url")
  destfile = paste0(destpath, model, "_", pat, ".txt")
  print(destfile)
  writeLines(hrefs$url, destfile)
}

for (model in models) {
  for (pat in pats) {
    createlinkfiles(model, pat)
  }
}

# historical
pat <- pats_hist
for (model in models) {
  createlinkfiles(model, pat)
}

# create GCB subset
GCBSub <- function(model, pat, yrs) {
  print(pat)
  print(model)
  print(yrs)
  infile = paste0(destpath, model, "_", pat, ".txt")
  hrefs <- as.data.table(readLines(infile)) # all years
  hrefs <- hrefs[grep(paste(yrs, collapse = "|"), V1),] # year choices for GCB PWC paper
  hrefs <- hrefs[grep(paste(yrs, collapse = "|"), V1),] # variable choices for GCB PWC paper
  outf <- paste0(destpath, model, "_", pat, "_GCB.txt")
  print(paste0("outf: ", outf))
  writeLines(hrefs$V1, outf)
}

for (model in models) {
  for (pat in pats) {
     GCBSub(model, pat, yrs = yrChoices)
  }
}

# do historical GCB
pat <- pats_hist
for (model in models) {
  GCBSub(model, pat = pats_hist, yrs = yrChoices_hist)
}

