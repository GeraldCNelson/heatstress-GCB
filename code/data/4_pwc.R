# calculate PWC values for individual models and periods

library(terra)
library(meteor)
terraOptions(verbose = TRUE)
this <- system("hostname", TRUE)
if (grepl("Mac", this, fixed = TRUE)) terraOptions(verbose = TRUE, memfrac = 0.8)

years <- c("1991_2000", "2001_2010", "2041_2050", "2051_2060", "2081_2090", "2091_2100")
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")
ssps <- c("historical", "ssp126", "ssp370", "ssp585")
nosun <- FALSE # variable to determine where solar radiation value is set to ISIMIP data (FALSE) or zero to simulate complete shade (TRUE)
x <- expand.grid(years[1:2], ssps[1], models)
x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))

# test data
# ssps <- "ssp585"
# years <- c("2041_2050", "2051_2060", "2081_2090", "2091_2100")
# x <- expand.grid(years[1:4], ssps[1], models)
# x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))
# end test data -----

compute_pwc <- function(y, s, m, nosun = FALSE) {
  if (nosun) {
    dir.create("data/pwc_ns", FALSE, FALSE)
    fin <- paste0("data/wbgt_ns/wbgt_ns_", m, "_", s, "_", y, ".tif")
    fout <- gsub("data/wbgt_ns/wbgt_ns", "data/pwc_ns/pwc_ns", fin)
  } else {
    dir.create("data/pwc", FALSE, FALSE)
    fin <- paste0("data/wbgt/wbgt_", m, "_", s, "_", y, ".tif")
    fout <- gsub("data/wbgt/wbgt", "data/pwc/pwc", fin)
  }
  if (file.exists(fout)) {
    return(fout)
  }
  print(fin)
  print(fout)
  flush.console()
  if (!file.exists(fin)) {
    return("error")
  }

  r <- rast(fin)
  pwc(r, filename = fout)
}

for (i in 1:nrow(x)) {
  print(paste0(i, " of ", nrow(x)))
  y <- x[i, 1]
  s <- x[i, 2]
  m <- x[i, 3]
  print(paste0(y, " ", s, " ", m))
  compute_pwc(y, s, m, nosun)
}
