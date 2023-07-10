
this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
  setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {
  setwd('/Users/gcn/Google Drive/My Drive/pwc')
}
path <- "data-raw/ISIMIP/pwc_agg3"

dir.create("figures", F, F)

library(terra)

crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm=TRUE) |> round()
# crps <- rast("data-raw/crops/total_crop_area.tif")
# crps <- aggregate(crps, 6, sum, na.rm=TRUE)
# crps <- crop(crps, c(-180, 180, -60, 67))
# crps <- round(crps)
w <- geodata::world(path="data-raw")

fig_lat <- function(avar="annual", legend=TRUE) {

	ff <- list.files(path, pattern = paste0(avar, ".*_mean.tif$"), full=TRUE)

	r <- rast(ff)
	names(r) <- gsub("^pwc_", "", names(r))
	r <- r[[names(r) != "ssp126_2081-2100"]]
	n <- nlyr(r)
	nms <- names(r)
	r <- c(crps, r)
	r <- mask(r, crps, maskvalue=0)
	an <- anyNA(r)
	r <- mask(r, an, maskvalue=TRUE)
	e <- na.omit(extract(r, w))
	a <- aggregate(e[,2] * e[,3:6], e[,1,drop=FALSE], sum)
	b <- aggregate(e[,2, drop=FALSE], e[,1,drop=FALSE], sum)
	ab <- merge(a, b, by="ID")
	ab[,2:5] <- round(ab[,2:5] / ab[,6], 1)
	v <- values(w)
	v <- data.frame(v[ab$ID,], ab[,-1])
	d <- v[v$sum > 100000, ]
	d <- d[order(d[,3]), ]
	
	capt <- gsub("_", ", ", nms)
	cols <- RColorBrewer::brewer.pal(n, "Set1")
	plot(d[1:20,3], type="n", las=1)
	text(d[1:20,3], label=d[1:20,1], cex=.5)
}

#outf <- "figures/pwc_figure3.png"
#png(outf, units="in", width=12, height=4, res=300, pointsize=18)

#par(mfrow=c(1,3))
#par(mar=c(4,4,1,0))
ya <- fig_lat("annual")
#par(mar=c(4,2,1,2))
yb <- fig_lat("season", F)
#par(mar=c(4,0,1,4))
yc <- fig_lat("hot90", F)

#dev.off()



