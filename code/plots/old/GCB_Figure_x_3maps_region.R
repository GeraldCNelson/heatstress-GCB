
this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
  setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {
  setwd('/Users/gcn/Google Drive/My Drive/pwc')
}

library(terra)
library(geodata)
path <- "data-raw/ISIMIP/pwc_agg3"
dir.create("figures", F, F)
#prj <- "+proj=robin"
wrld <- geodata::world(path="data-raw")
crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm=TRUE) |> round() 
crps <- crps > 100

cntry_3plot <- function(x, capt, main="", country, pngfile="") {
#	lev = ifelse(country=="Brazil", 0, 1)
	lev = 1
	rc <- gadm(country = country, level = lev, path = "data-raw/gadm/", resolution = 2)
	if (country == "Brazil") rc <- crop(rc, c(-75, -34, -34, 7))
	crops <- crop(crps, rc, mask=TRUE)
	x <- crop(x, crops, mask=TRUE) 
	x <- mask(x, rc)
	e <- as.vector(ext(rc))
	subs <- paste0("(", letters[1:3], ")") 
	cols <- rev(viridis::turbo(100)[15:100])
	rng <- c(35, 100)
	if (pngfile != "") {
		png(pngfile, units="in", width=3, height=6, res=300)
	}	
	layout(matrix(c(1:3), 3, 1))
	for (i in 1:3) {
		mapext <- ext(rc) + diff(ext(rc)[1:2])/100
		plot(wrld, col=gray(.92), ext=mapext, axes=FALSE, mar=c(2, .1, .1, 3), backgroun="azure", border="gray", lwd=1.5)
		plot(x[[i]], col=cols, axes=FALSE, legend=i==2, plg=list(cex=1.1), xpd=TRUE, range=rng, add=TRUE)
		lines(rc, col=gray(0.4))
		text(e[1], e[3]-1.5*strheight("a"), subs[i], font=2, cex=1.0, adj = 0.0, xpd=TRUE)
		text(e[1]+strwidth("(a) "), e[3]-1.5*strheight("a"), capt[i], xpd=TRUE, adj=0)
	}
	if (pngfile != "") dev.off()
}


capt <- c("1991-2010", "SSP5-8.5, 2041-2060", "SSP5-8.5, 2081-2100")
#avars <- c("annual", "season", "hot90")
avars <- "season"
countries <- c("Brazil", "India", "Nigeria")

for (a in avars) {
	f <- file.path(path, paste0("pwc_", a, "_mean.tif"))
	r <- rast(f)[[c(1,4,5)]]
	mainval <- paste0("PWC\n", a)
	if (a == "hot90") mainval <- paste0("PWC\n", "hottest period")
	for (country in countries) {
		fpng <- paste0("figures/maps_pwc_", a, "_", country, ".png")
		#fpng = ""
		cntry_3plot(r, capt, main=mainval, country, fpng)
	}
}
