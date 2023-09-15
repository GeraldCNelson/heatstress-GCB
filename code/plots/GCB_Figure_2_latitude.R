# create Figure 2. Physical Work Capacity (PWC) by latitude for global cropland for recent historical (1991-2010) and potential future thermal conditions 

library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (this == "MacBook-Pro-M1X.local") terraOptions(verbose = TRUE, memfrac = 0.8)

path <- "data/agg/pwc_agg3"

dir.create("figures", F, F)

library(terra)

latRangeChoices <- c("global", "tropical", "S20N35")
ext_global <- ext(-180, 180, -60, 67)
ext_tropical <- ext(-180, 180, -23, 23)
ext_S20N35 <- ext(-180, 180, -20, 35)
# crps <- rast("data-raw/crops/total_crop_area.tif")
# crps <- aggregate(crps, 6, sum, na.rm = TRUE)
# crps <- crop(crps, c(-180, 180, -60, 67))
# crps <- round(crps)

crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm = TRUE) |> round()

# convert to ratio, divide by 100
cval <- 100
minx = 35/cval

fig_lat <- function(avar="annual", lgnd=TRUE, region="global") {
  extRegion <- get(paste0("ext_", region))
  ff <- list.files(path, pattern = paste0(avar, ".*_mean.tif$"), full = TRUE)
  r <- rast(ff)/cval
  names(r) <- gsub("^pwc_", "", names(r))
  r <- r[[!names(r) %in% c("ssp126_2041-2060", "ssp126_2081-2100")]]
  n <- nlyr(r)
  nms <- names(r)
  
  # r <- c(crps, r)
  #  r <- mask(r, crps, maskvalue = 0)
  r <- c(crps, r) |> round(1) |> mask(crps, maskvalue = 0)
  
  an <- anyNA(r)
  r <- mask(r, an, maskvalue = TRUE)
  
  s <- r[[1]] * r[[-1]] # multiply crop area [1] by pwc values for each period [-1]
  a <- aggregate(s, c(1, ncol(s)), sum, na.rm = TRUE)
  b <- aggregate(r[[1]], c(1, ncol(r)), sum, na.rm = TRUE)
  w <- a / b
  w <- crop(w, extRegion)
  d <- as.data.frame(w, xy = TRUE)
  d$x <- NULL
  
  for (i in 2:(n+1)) {
    d[,i] = roll(d[,i], 5, fun = mean, type="around", circular=FALSE, na.rm = TRUE) 
  }
  
  capt <- gsub("historical_", "", nms)
  capt <- gsub("126", "1-2.6", toupper(capt))
  capt <- gsub("370", "3-7.0", capt)
  capt <- gsub("585", "5-8.5", capt)
  capt <- sapply(strsplit(capt, "_"), \(i) paste(sort(i), collapse=" ("))
  i <- capt!="1991-2010" 
  capt[i] <- paste0(capt[i], ")")
  
  cols <- RColorBrewer::brewer.pal(n, "Set1")
  if(region == "global")  ylim <- c(-60,70)
  if(region == "tropical")  ylim <- c(-25,30) #c(-25,30)
  if(region == "S20N35")  ylim <- c(-25,40) 
  
  plot(d[,2], d[,1], col = cols[1], lwd=2, type="l", xlim=c(minx,100/cval), ylim=ylim,
       las=1, xlab = "PWC", ylab = "Latitude", axes=FALSE,  
       yaxs = "i",  xaxs = "i") #, main=titleText
  
  for (i in 2:n) {
    lines(d[,i+1], d[,1], col = cols[i], lwd=2, lty=i)
  }
  grid(NULL, 4, col = "gray")
  
  if (lgnd) {
    legend(minx, ylim[2], capt, lty=1:5, col = cols, cex=.8, lwd=3, bg="white", box.col = "white")
  } 
  i <- match(avar, c("annual", "season", "hot90"))
  text(55/cval, ylim[2], c("(a) Annual", "(b) Growing season", "(c) Hottest period")[i], pos=4, xpd=TRUE) 
  axis(1,  cex.axis = .9) 
  axis(2, las=1, cex.axis = .9, labels=lgnd) #, at=seq(-60,75,15)
}

for (region in latRangeChoices) {
  outf <- paste0("plots/pwc_figure2", region, ".png")
  png(outf, units="in", width = 12, height = 4, res = 300, pointsize=18)
  par(family = "Times New Roman")
  par(mfrow=c(1,3))
  par(mar=c(4,4,2,0))
  ya <- fig_lat("annual", T, region)
  par(mar=c(4,2,2,2))
  yb <- fig_lat("season", F, region)
  par(mar=c(4,0,2,4))
  yc <- fig_lat("hot90", F, region)
  
  dev.off()
}

