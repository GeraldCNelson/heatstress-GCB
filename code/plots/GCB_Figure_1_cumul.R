# create table 1 in the GCB paper - Physical Work Capacity (PWC) for 1991-2010 and potential future thermal conditions

library(terra)
library(meteor)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (this == "MacBook-Pro-M1X.local") terraOptions(verbose = TRUE, memfrac = 0.8)


path <- "data-raw/ISIMIP/pwc_agg3"

dir.create("figures", F, F)

crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm = TRUE) |> round()
#crps <- aggregate(crps, 6, sum, na.rm = TRUE)
#crps <- crop(crps, c(-180, 180, -60, 67))

cval <- 100
#minx <- 25/cval
minx <- 0
fig_cumul <- function(avar="annual", lgnd=TRUE) {
  
  ff <- list.files(path, pattern = paste0(avar, ".*_mean.tif$"), full = TRUE)
  
  r <- rast(ff) / cval # convert from % to ratio
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
  capt <- gsub("historical_", "", names(x))
  i <- grepl("ssp126_", capt)
  capt[i] <- paste(gsub("ssp126_", "", capt[i]), "(SSP1-2.6)")
  i <- grepl("ssp585_", capt)
  capt[i] <- paste(gsub("ssp585_", "", capt[i]), "(SSP5-8.5)")
  
  y <- lapply(x, \(i) {
    c(i[which.min(abs(i[,2]-0.25)), 1],
      i[which.min(abs(i[,2]-0.50)), 1],
      i[which.min(abs(i[,2]-0.75)), 1])
  })
  y <- do.call(rbind, y)
  colnames(y) <- paste0(avar, c("_.25", "_.50", "_.75"))
  
  cols <- RColorBrewer::brewer.pal(n, "Set1")
  
  plot(x[[1]][,1], x[[1]][,2], col=cols[1], lwd=2, type="l", xlim=c(minx,100/cval), 
       las=1, xlab="PWC", ylab="Fraction of global crop land", axes=FALSE,  
       yaxs="i",  xaxs="i")
  for (i in 2:n) {
    lines(x[[i]][,1], x[[i]][,2], col=cols[i], lwd=2, lty=i)
  }
  
  grid(NULL, 4)
  
  if (lgnd) {
    legend(minx+2/cval, 1, capt, lty=1:5, col=cols, cex=.9, lwd=3, bg="white", box.col="white")
  } 
  axis(1,  xlab="PWC", cex.axis=.9) # removed at=seq(.20, 1.00, 1.0), when converted to ratio
  axis(2, at=seq(0,1,.25), las=1, cex.axis=.9, labels=lgnd)
  
  i <- match(avar, c("annual", "season", "hot90"))
  text(42/cval, 1.1, c("(a) Annual", "(b) Growing season", "(c) Hottest period")[i], pos=4, xpd=TRUE) 
}

outf <- "figures/pwc_figure1.png"
png(outf, units="in", width = 12, height = 4, res = 300, pointsize=18)
par(family = "Times New Roman")#, fg = mycol, col = mycol, col.axis = mycol, col.lab = mycol, col.main = mycol, col.sub = mycol)

par(mfrow=c(1,3))
par(mar=c(4,4,2,0))
ya <- fig_cumul("annual")
par(mar=c(4,2,2,2))
yb <- fig_cumul("season", F)
par(mar=c(4,0,2,4))
yc <- fig_cumul("hot90", F)

dev.off()

