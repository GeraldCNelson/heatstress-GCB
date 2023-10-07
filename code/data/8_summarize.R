# Aggregation to means of annual, growing season and hottest periods. Also includes impact of eliminating radiation effect in PWC values. # see notes at bottom about order of running the code.

library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (grepl("Mac", this, fixed=TRUE)) terraOptions(verbose = TRUE, memfrac = 0.8)

dir.create("data/agg/pwc_agg3/", FALSE, FALSE)
dir.create("data/agg/pwc_agg3_ns/", FALSE, FALSE)

get_names <- function(ff) {
  nms <- gsub("\\.tif$", "", basename(ff))
  gsub("1_2", "1-2", nms)
}

get_diff <- function(r, outf) {
  if (file.exists(outf)) return(rast(outf)) 
  x <- r[[1]] - r[[-1]]
  writeRaster(x, filename=outf, names = gsub("pwc", "d", names(r)[-1]))
}

annual_mean <- function(nosun=FALSE) {
  if (nosun) {
    ff <- list.files("data/agg/pwc_agg2_ns", pattern="tif$", full = TRUE)
    outf1 <- "data/agg/pwc_agg3_ns/pwc_annual_mean_ns.tif"
    outf2 <- "data/agg/pwc_agg3_ns/pwc_annual_change_ns.tif"	
  } else {
    ff <- list.files("data/agg/pwc_agg2", pattern="tif$", full = TRUE)
    outf1 <- "data/agg/pwc_agg3/pwc_annual_mean.tif"
    outf2 <- "data/agg/pwc_agg3/pwc_annual_change.tif"
  }
  if (!file.exists(outf1)) {
    r <- rast(lapply(ff, \(i) mean(rast(i))))
    r <- writeRaster(r, filename=outf1, names = get_names(ff))
  } else {
    r <- rast(outf1)
  }
  get_diff(r, outf2)
}

hot90_mean <- function(nosun=FALSE) {
  if (nosun) {
    ff <- list.files("data/agg/pwc_agg2_ns/", pattern="tif$", full = TRUE)
    outf1 <- "data/agg/pwc_agg3_ns/pwc_hot90_mean_ns.tif"
    outf2 <- "data/agg/pwc_agg3_ns/pwc_hot90_change_ns.tif"
  } else {
    ff <- list.files("data/agg/pwc_agg2/", pattern="tif$", full = TRUE)
    outf1 <- "data/agg/pwc_agg3/pwc_hot90_mean.tif"
    outf2 <- "data/agg/pwc_agg3/pwc_hot90_change.tif"
  }
  if (!file.exists(outf1)) {
    r <- rast(lapply(ff, \(i) min(roll(rast(i), 90, circular=TRUE)))) 
    r_first <- rast(lapply(ff, \(i) which.min(roll(rast(i), 90, type = "from", circular=TRUE))))
    r <- writeRaster(r, filename=outf1, names = get_names(ff))
    r_first <- writeRaster(r_first, filename=gsub("_mean", "_mean_first", outf1), names = get_names(ff))
  } else {
    r <- rast(outf1)
  }	
  get_diff(r, outf2)
}

season_mean <- function(nosun=FALSE) {
  if (nosun) {
    ff <- list.files("data/agg/pwc_agg2_ns/", pattern="tif$", full = TRUE)
    outf1 <- "data/agg/pwc_agg3_ns/pwc_season_mean_ns.tif"
    outf2 <- "data/agg/pwc_agg3_ns/pwc_season_change_ns.tif"	
  } else {
    ff <- list.files("data/agg/pwc_agg2/", pattern="tif$", full = TRUE)
    outf1 <- "data/agg/pwc_agg3/pwc_season_mean.tif"
    outf2 <- "data/agg/pwc_agg3/pwc_season_change.tif"
  }
  
  if (!file.exists(outf1)) {
    fseason <- "data-raw/calendar-sacks/growing_season.tif"
    s <- rast(fseason)
    s <- crop(s, ext(-180, 180, -60, 67))		
    r <- rast(lapply(ff, \(i) sum(rast(i) * s)))
    r <- writeRaster(r, filename=outf1, names = get_names(ff))
  } else {
    r <- rast(outf1)
  }
  get_diff(r, outf2)
}

a1 <- annual_mean()
b1 <- hot90_mean()
d1 <- season_mean()

# these will fail unless earlier code has been run with nosun <- TRUE
# This needs to be done in 3_wbgt.R, 4_pwc.R, 5_agg_time.R and 6_agg_models.R
nosun <- TRUE # false is run just above
a2 <- annual_mean(nosun)
b2 <- hot90_mean(nosun)
d2 <- season_mean(nosun) # nosun
