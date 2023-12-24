# aggregate by time period for individual models
library(terra)
terraOptions(verbose = TRUE)
this <- system("hostname", TRUE)
if (grepl("Mac", this, fixed = TRUE)) terraOptions(verbose = TRUE, memfrac = 0.8)

years <- c("1991_2010", "2041_2060", "2081_2100") # 20 year periods
models <- c("ukesm", "gfdl", "mpi", "mri", "ipsl")
ssps <- c("historical", "ssp126", "ssp370", "ssp585")
x <- expand.grid(years[1:2], ssps[1], models)
x <- rbind(x, expand.grid(years[-1], ssps[-1], models))

nosun <- FALSE # variable to determine where solar radiation value is set to ISIMIP data (FALSE) or zero to simulate complete shade (TRUE)

# test data
# ssps <- "ssp585"
# years <- c("2041_2060", "2081_2100")
# x <- expand.grid(years[1:2], ssps[1], models)
# x <- rbind(x, expand.grid(years[-c(1:2)], ssps[-1], models))
# end test data -----

agg_time <- function(y, s, m, nosun = FALSE) {
  yrs <- matrix(c(
    "1991_2000", "2001_2010", "1991_2010",
    "2041_2050", "2051_2060", "2041_2060",
    "2081_2090", "2091_2100", "2081_2100"
  ), ncol = 3, byrow = TRUE)
  # test data
  # yrs <- matrix(c("2041_2050", "2051_2060", "2041_2060",
  #                 "2081_2090", "2091_2100", "2081_2100"), ncol = 3, byrow = TRUE)
  # end test data

  i <- which(y == yrs[, 3])

  if (nosun) {
    dir.create("data/agg/pwc_agg1_ns", FALSE, TRUE)
    fin1 <- paste0("data/pwc_ns/pwc_ns_", m, "_", s, "_", yrs[i, 1], ".tif")
    fin2 <- paste0("data/pwc_ns/pwc_ns_", m, "_", s, "_", yrs[i, 2], ".tif")
    fout <- paste0("data/agg/pwc_agg1_ns/pwc_ns_", m, "_", s, "_", yrs[i, 3], ".tif")
  } else {
    dir.create("data/agg/pwc_agg1", FALSE, TRUE)
    fin1 <- paste0("data/pwc/pwc_", m, "_", s, "_", yrs[i, 1], ".tif")
    fin2 <- paste0("data/pwc/pwc_", m, "_", s, "_", yrs[i, 2], ".tif")
    fout <- paste0("data/agg/pwc_agg1/pwc_", m, "_", s, "_", yrs[i, 3], ".tif")
  }
  if (file.exists(fout)) {
    print(paste0("exists fout: ", fout))
    return(fout)
  }
  print(fin1)
  print(fin2)
  print(fout)
  flush.console()
  if ((!file.exists(fin1)) | (!file.exists(fin2))) {
    return("error")
  }

  r <- rast(c(fin1, fin2))

  # first average Feb 28 and Feb 29
  leaps <- grep("-02-29", time(r))
  x <- tapp(r[[c(leaps, leaps - 1)]], rep(1:length(leaps), each = 2), "mean")
  r[[leaps - 1]] <- x
  r <- r[[-leaps]]

  tapp(r, 1:365, "mean", filename = fout)
}

for (i in 1:nrow(x)) {
  print(paste0(i, " of ", nrow(x)))
  y <- x[i, 1]
  s <- x[i, 2]
  m <- x[i, 3]
  print(paste0(y, " ", s, " ", m))
  agg_time(y, s, m, nosun)
}
