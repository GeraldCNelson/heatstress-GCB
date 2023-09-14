# create 3 plots (annual, season, hot90 vertically for a single time period, 
library(terra)
this <- system('hostname', TRUE)
if (this == "MacBook-Pro-M1X.local") terraOptions(verbose = TRUE, memfrac = 0.8)

path <- "data/agg/pwc_agg3"
dir.create("figures", F, F)
prj <- "+proj=robin"
wrld <- geodata::world(path = "data-raw")
e <- ext(-12000000, 16038790, -6168256, 6942628)

crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm = TRUE) |> round()

# crps <- rast("data-raw/crops/total_crop_area.tif")
# crps <- aggregate(crps, 6, sum, na.rm = TRUE)
# crps <- crop(crps, c(-180, 180, -60, 67))
crops <- mask(crps > 100, wrld)
wrld <- project(wrld, prj) |> crop(e)
back <- crop(project(crops, prj), e)

supp_maps <- function(x, capt, main="", rng=c(15, 100), pngfile="") {
  
  subs <- paste0("(", letters[1:3], ")")
  x <- mask(x, crops, maskvalue = FALSE)
  x <- crop(project(x, prj), e)
  x <- clamp(x, rng[1], rng[2], values=TRUE)
  
  grat <- graticule(30, crs = prj) |> crop(e)
  cols <- rev(viridis::turbo(100)[15:100])
  
  #	rng <- range(minmax(x))
  
  lege <- ext(18000000, 19000000, -9000000, 9000000)
  
  if (pngfile != "") {
    png(pngfile, units="in", width = 5, height = 6, res = 300)
  }
  layout(matrix(c(1:4,4,4), 3, 2), width = c(1,.2))
  for (i in 1:3) {
    browser()
    plot(grat, col = "gray", background="azure", lty = 2, mar = c(0,0,0,0), labels = FALSE)
    plot(back, add = TRUE, axes = FALSE, legend = FALSE, col = "light gray")
    plot(x[[i]], add = TRUE, axes = FALSE, col = cols, legend = i==2, xpd=TRUE, range=rng, 
         plg=list(ext=lege, cex=1.5, title=main, title.cex=1.5))
    lines(wrld, col = gray(.4), lwd=.5)
    text(-11300000, -5200000, subs[i], font=2, cex=1.5)
    text(vect(cbind(-2000000, -5463047)), capt[i], pos=4, halo=TRUE, cex=1.3)
  }
  # add legend
  plot(0, axes=FALSE, type="n")
  #text(0.6, ifelse(grepl("\n", main), 0.6, 0.52), pos=4, xpd=TRUE, main, cex=1.4)
  
  if (pngfile != "") dev.off()
}

avars <- c("annual", "season", "hot90")
bvars <- c("Annual", "Growing season", "Hottest\nperiod")

cpt <- c("1991-2010", "2041-2060", "2081-2100")

for (j in 1:2) {
  if (j==1) {
    s <- 1:3 
    capt <- paste0(cpt, " (SSP1-2.6)")
    rn <- c(30, 100)
  } else {
    s <- c(1,4,5)
    capt <- paste0(cpt, " (SSP5-8.5)")
    rn <- c(15, 100)
  }
  for (i in 1:length(avars)) {
    f <- file.path(path, paste0("pwc_", avars[i], "_mean.tif"))
    r <- rast(f)[[s]]
    mainval <- paste0(bvars[i], "\nPWC (%)\n")
    k <- i + (j-1) * 3
    fpng <- paste0("plots/agg/SupMat_pwc_figure_S", k, ".png")
    supp_maps(r, capt, main=mainval, rng=rn, pngfile=fpng)
  }
}

