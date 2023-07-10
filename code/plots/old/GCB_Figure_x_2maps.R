
this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
	setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {
	setwd('/Users/gcn/Google Drive/My Drive/pwc')
}

dir.create("figures", F, F)

library(terra)
path <- "data-raw/ISIMIP/pwc_agg3"


make_2plot <- function(x, crops, main="", pngfile="") {

	capt <- gsub("pwc_", "", names(x))
	capt <- gsub("historical_", "", capt)
	capt <- gsub("_", ", ", capt)

	subs <- paste0("(", letters[1:3], ")")

	e <- ext(-12000000, 16038790, -6168256, 6942628)
	prj <- "+proj=robin"

	back <- crop(project(x[[1]], prj), e)
	x <- mask(x, crops<100, maskvalue=TRUE) 
	x <- crop(project(x, prj), e)
#	x <- crop(project(x, prj), e)
	
	wrld <- geodata::world(path="data-raw") |> project(prj) |> crop(e)
	grat <- graticule(30, crs=prj) |> crop(e)
	cols <- rev(viridis::turbo(100)[15:100])

	rng <- range(minmax(x))
#	rng <- c(0, 25)
	lege <- ext(18100000, 19000000, -1000000, 15500000)

	if (pngfile != "") {
		png(pngfile, units="in", width=5, height=6, res=300)
	}
	layout(matrix(c(1:3,3), 2, 2), width=c(1,.2))
	for (i in 1:2) {
		plot(grat, col="gray", background="azure", lty=2, mar=c(0,0,0,0), labels=FALSE)
		plot(back, add=TRUE, axes=FALSE, legend=FALSE, col=gray(0.99))
		plot(x[[i]], add=TRUE, axes=FALSE, col=cols, legend=i==2, plg=list(ext=lege, cex=1.1), xpd=TRUE, range=rng)
		lines(wrld, col=gray(.4), lwd=.5)
		text(-11300000, -5200000, subs[i], cex=2)
		text(vect(cbind(-2000000, -5463047)), capt[i], pos=4, halo=TRUE)
	}
	plot(0, axes=FALSE, type="n")	
	if (main == "hot90") main = "Hottest period"
	text(0.6, ifelse(grepl("\n", main), 0.8, 0.72), pos=4, xpd=TRUE, main, cex=1.4)
	if (pngfile != "") dev.off()
}


crps <- rast("data-raw/crops/total_crop_area.tif")
crps <- aggregate(crps, 6, sum, na.rm=TRUE)
crps <- crop(crps, c(-180, 180, -60, 67))

avars <- c("annual", "season", "hot90")
rann <- rast(file.path(path, paste0("pwc_annual_mean.tif")))
rsea <- rast(file.path(path, paste0("pwc_season_mean.tif")))
rhot <- rast(file.path(path, paste0("pwc_hot90_mean.tif")))


for (a in avars) {
	f <- file.path(path, paste0("pwc_", a, "_mean.tif"))
	r <- rast(f)[[c(1,4,5)]]
	make_2plot(r, crps, main=paste0("PWC\n", a), paste0("figures/maps_pwc_", a, "2maps.png"))
}


