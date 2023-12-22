#create Figure 4. Average PWCs during the growing season for three countries

library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (grepl("Mac", this, fixed = TRUE)) terraOptions(verbose = TRUE, memfrac = 0.8)

library(terra)
library(geodata)
library(extrafont)
extrafont::loadfonts(quiet = TRUE)
path <- "data-raw/ISIMIP/pwc_agg3"
dir.create("plots", F, F)
wrld <- geodata::world(path = "data-raw")
crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm = TRUE) |> round() 
crps <- crps > 100

capt <- c("1991-2010", "2041-2060", "2081-2100")

make_fig4 <- function(x, country, n, rng=c(.25, 1)) {
	rc <- gadm(country, level=1, path = "data-raw/gadm/", resolution = 2)
	covbx <- NULL
	if (country == "Brazil") {
		rc <- crop(rc, c(-75, -34, -34, 7))
		sdist <- 1000
		subd <- 1
		e <- ext(rc)
	} else if (country == "India") {
		rc <- crop(rc, c(68, 98, 6.9, 36))
		sdist <- 750
		subd <- 2
		e <- ext(rc)
		covbx <- ext(91, 95, 6.3, 10)
	} else if (country == "Nigeria") {
		sdist <- 300
		subd <- 4
		e <- ext(rc)
		e$ymin <- 2.55
		e$ymax <- 15.45
	}
	crops <- crop(crps, e)
	if (subd > 1) {
		crops <- disagg(crops, subd)
		x <- disagg(x, subd)
	}
	crops <- mask(crops, rc)
	x <- crop(x, crops)
	x <- mask(x, crops, maskvalue = FALSE) 
	x <- mask(x, rc)
	x <- clamp(x, rng[1], rng[2], values=TRUE)
	
	subs <- paste0("(", letters[(1:3) + (n-1)*3], ")") 
	cols <- rev(viridis::turbo(100)[15:100])
	lege <- ext(16.5, 17.3, 0, 18)
	
	par(family = "Times New Roman")
	for (i in 1:3) {
		mapext <- e + diff(e[1:2])/100
		plot(wrld, col = gray(.92), ext=mapext, axes=FALSE, mar=c(.1, .1, 2, .1), backgroun="azure", border="gray", lwd=1.5, box=TRUE)
		plot(x[[i]], col = cols, axes=FALSE, legend = (n==3) & (i==2), xpd=TRUE, range=rng, add=TRUE, 
			plg=list(ext=lege, cex=1.2, title.cex=1.2, title="   PWC\n"))
		lines(rc, col = gray(0.4))
		text(e[1], e[3]+.5*strheight("a"), subs[i], font=2, cex=1.0, adj = 0.0, xpd=TRUE)
		if (country=="India") text(e[1] + diff(e[1:2])/2, e[4]+1.7*strheight("a"), capt[i], xpd=TRUE, cex=1.25)
		if (i == 3) {
			if (!is.null(covbx)) {
				polys(covbx, col = "azure", border="azure")
			}
			sbar(sdist, xy="bottomright", type="line", divs=2, labels=paste(sdist, "km"), lwd=1, lonlat=TRUE, cex=.8, col = gray(0.3), halo=TRUE)	
		}
		if (i == 1) {
			terra:::.halo(e[2], e[4] - .5*strheight("a"), country, font=3, cex=1.2, pos=2, xpd=TRUE)
		}
	}
}

avars <- c("annual", "season", "hot90")
a <- "season"

f <- file.path(path, paste0("pwc_", a, "_mean.tif"))
r <- rast(f)[[c(1,4,5)]]
r <- r/100 # convert from percent to ratio

countries <- c("Brazil", "India", "Nigeria")

pngfile <- paste0("plots/pwc_figure4.png")
#pngfile=""
if (pngfile != "") {
	png(pngfile, units="in", width = 5.5, height = 6, res = 300)
}	

m = cbind(matrix(c(1:9), 3, 3), 10)
layout(m, widths=c(1,1,1,0.4))

for (i in 1:length(countries)) {
	make_fig4(r, countries[i], i)
}

if (pngfile != "") dev.off()

