#create Figure 1. Cumulative distribution of early 21st century cropland Physical Work Capacity (PWC) for recent historical (1991-2010) and potential future thermal conditions 

library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (this == "MacBook-Pro-M1X.local") terraOptions(verbose = TRUE, memfrac = 0.8)

path <- "data-raw/ISIMIP/pwc_agg3"

dir.create("figures", F, F)

library(terra)

crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm = TRUE) |> round()

fig_cumul <- function(avar="annual", legend=TRUE) {
  
  ff <- list.files(path, pattern = paste0(avar, ".*_mean.tif$"), full = TRUE)
  
  r <- rast(ff)
  names(r) <- gsub("^pwc_", "", names(r))
  names(r) <- gsub("; ", "", names(r))
  
  # r <- r[[names(r) != "ssp126_2081-2100"]] # drop end century ssp126
  n <- nlyr(r)
  
  r <- c(crps, r) |> round(1) |> mask(crps, maskvalue = 0)
  #	r <- round(r,1)
  #	r <- mask(r, crps, maskvalue = 0)
  
  d <- as.data.frame(r)
  
  x <- lapply(1:n, \(i) {
    a <- aggregate(d[,1,drop = FALSE], d[,i+1,drop = FALSE], sum) 
    a[,2] <- cumsum(a[,2] / sum(a[,2]))
    a
  })
  
  names(x) <- names(d)[-1]
  capt <- gsub("_", ", ", names(x))
  
  y <- lapply(x, \(i) {
    c(i[which.min(abs(i[,2]-0.25)), 1],
      i[which.min(abs(i[,2]-0.50)), 1],
      i[which.min(abs(i[,2]-0.75)), 1])
  })
  y <- do.call(rbind, y)
  colnames(y) <- paste0(avar, c("_.25", "_.50", "_.75"))
  
  cols <- RColorBrewer::brewer.pal(n, "Set1")
  
  plot(x[[1]][,1], x[[1]][,2], col=cols[1], lwd=2, type="l", xlim=c(40,100), 
       las=1, xlab="PWC (%)", ylab="Fraction of global crop land", axes=FALSE,  
       yaxs="i",  xaxs="i")
  for (i in 2:n) {
    lines(x[[i]][,1], x[[i]][,2], col=cols[i], lwd=2, lty=i)
  }
  
  grid(NULL, 4)
  
  if (legend) {
    legend(42, .9, capt, lty=1:5, col=cols, cex=.8, lwd=3, bg="white")
  } 
  axis(1, xlab="PWC (%)", cex.axis=.9)
  axis(2, at=seq(0,1,.25), las=1, cex.axis=.9, labels=legend)
  
  i <- match(avar, c("annual", "season", "hot90"))
  text(42, 1, c("(a) Annual", "(b) Growing season", "(c) Hottest period")[i], pos=4, xpd=TRUE) 
  y
}

outf <- "figures/pwc_cum_3types.png"
png(outf, units="in", width = 12, height = 4, res = 300, pointsize=18)

par(mfrow=c(1,3))
par(mar=c(4,4,1,0))
ya <- fig_cumul("annual")
par(mar=c(4,2,1,2))
yb <- fig_cumul("season", F)
par(mar=c(4,0,1,4))
yc <- fig_cumul("hot90", F)

dev.off()
