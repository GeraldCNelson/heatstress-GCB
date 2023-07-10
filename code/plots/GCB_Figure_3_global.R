
this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
	setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {
	setwd('/Users/gcn/Google Drive/My Drive/pwc')
}

library(terra)
cval <- 100 # used to convert from percent to ratio
path <- "data-raw/ISIMIP/pwc_agg3"
dir.create("figures", F, F)
prj <- "+proj=robin"
e <- ext(-12000000, 16038790, -6168256, 6942628)
wrld <- geodata::world(path="data-raw")

crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm=TRUE) |> round()
crops <- mask(crps >100, wrld)
wrld <- project(wrld, prj) |> crop(e)

capt <- c("1991-2010", "2041-2060 (SSP5-8.5)", "2081-2100 (SSP5-8.5)")
#tvars <- c("1991-2010", "2041-2060", "2081-2100")

grat <- graticule(30, crs=prj) |> crop(e)
cols <- rev(viridis::turbo(100)[15:100])
rng <- c(35, 100) / cval
lege <- ext(18000000, 19000000, -9000000, 9000000)
aggm <- c("season", "hot90")
agglab <- c("Growing season", "Hottest period")
back <- crop(project(crops, prj), e)

make_fig3 <- function(pcol=1) {

	f <- file.path(path, paste0("pwc_", aggm[pcol], "_mean.tif"))
	x <- rast(f)[[c(1,4,5)]] / cval

	if (pcol==1) {
		mainval <- paste0("PWC\n", aggm[1])
	} else {
		mainval <- paste0("PWC\n", "warm period")
	}
	subs <- paste0("(", letters[(1:3)+3*(pcol-1)], ")")
	
	x <- mask(x, crops, maskvalue=FALSE)
	x <- crop(project(x, prj), e)
	x <- clamp(x, rng[1], rng[2], values=TRUE)
	
	par(family = "Times New Roman")#, fg = mycol, col = mycol, col.axis = mycol, col.lab = mycol, col.main = mycol, col.sub = mycol)
	for (i in 1:3) {
		plot(grat, col="light gray", background="azure", lty=3, mar=c(0,0,1.5,0), labels=FALSE)
		plot(back, add=TRUE, axes=FALSE, legend=FALSE, col="light gray")
		plot(x[[i]], add=TRUE, axes=FALSE, col=cols, legend=(i==2 & pcol==2), range=rng,
			plg=list(ext=lege, cex=1.2, title.cex=1.2, title="PWC\n"))
		lines(wrld, col=gray(.4), lwd=.5)
		terra:::.halo(-11300000, -5200000, subs[i], font=2, cex=1.1)
		if (i==1) {
			text(e[1] + diff(e[1:2])/2, e[4], agglab[pcol], cex=1.5, pos=3, xpd=NA, font=2) 
		}
		if (pcol == 1) {
			text(e[2], e[4], capt[i], cex=1.2, pos=3, xpd=NA)
		}
	}
}

pngfile = paste0("figures/pwc_figure3.png")
#pngfile = ""
if (pngfile != "") {
	h = 6
	png(pngfile, units="in", width=1.3*h, height=h, res=300)
}

layout(matrix(c(1:7, 7, 7), 3, 3), width=c(1,1,.2))

for (i in 1:length(aggm)) {
	make_fig3(i)
}

if (pngfile != "") dev.off()

