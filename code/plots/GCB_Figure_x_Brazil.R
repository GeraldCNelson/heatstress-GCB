
#plot cheat sheet
#https://www.rstudio.com/wp-content/uploads/2016/10/how-big-is-your-graph.pdf
this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
  setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {
  setwd('/Users/gcn/Google Drive/My Drive/pwc')
}

# prepare data
path <- "compute_pwc/quarters"
prj <- "+proj=robin"
crsLatLong <- "EPSG:4326"
library(terra)
library(geodata)
library(viridis)
#e <- ext(-12000000, 16038790, -6168256, 6942628)
qNames <- c("q1", "q3")
# regionChoices <- c("country_Brazil", "country_India", "countries_WestAfrica")
# country_India <- gadm(country = "IND", level = 0, path = "data-raw/gadm/", resolution = 2) |>  project(prj) 
 country_Brazil <- gadm(country = "BRA", level = 0, path = "data-raw/gadm/", resolution = 2) |>  project(prj)
# Africa_3digit <- readxl::read_excel("data-raw/Africa_3digit.xlsx") 
# countries_WestAfrica_3digit <- Africa_3digit[Africa_3digit$region %in% "WA" & !Africa_3digit$A3 == "CPV",] # leave out Cape Verde, CPV
# countries_WestAfrica <- gadm(country = countries_WestAfrica_3digit$A3, level = 0, path = "data-raw/gadm/", resolution = 2) |>  project(prj)

wrld <- geodata::world(path = "data-raw/gadm") |> project(prj)

regionChoice <- "country_Brazil"
e <- ext(get(regionChoice)) 
xm <- e[1]; xx <- e[2]; ym <- e[3]; yx <- e[4]
e_ratio <- (yx-ym)/(xx- xm)
grat <- graticule(5, 5, crs = prj) |> crop(e)
r <- wrld |>  crop(e)
crps <- rast("data-raw/crops/total_crop_area.tif") |> project(prj) |> crop(get(regionChoice), mask = TRUE)
crps1 <- rast("data-raw/crops/total_crop_area.tif", win = e) |> 
  aggregate(6, sum, na.rm = TRUE) |> round()

for (qName in qNames) {
  f <- file.path(path, paste0("globe_", qName, "_rf_ensemble_pwc_wbgt_out_daily_mean_historical_mean_1991_2010.tif")) 
  cur <- rast(f)  |> project(crps) |> crop(get(regionChoice), mask = TRUE)
  names(cur) <- "Historical, 1991-2010"
  
  f <- file.path(path, paste0("globe_", qName, "_rf_ensemble_pwc_wbgt_out_daily_mean_ssp585_mean_2081_2100.tif"))
  bad <- rast(f)|> project(crps) |> crop(get(regionChoice), mask = TRUE)
  names(bad) <- "SSP5-8.5, 2081-2100"
  mcur <- mask(cur, crps<100, maskvalue = TRUE)
  mbad <- mask(bad, crps<100, maskvalue = TRUE)
  
  x <- c(mcur, mbad)
  y <- c(cur, bad) 
  names(x) <- names(y) <- paste0(names(y), ", ", qName)
  assign(paste0("x_", qName), x)
  assign(paste0("y_", qName), y)
}

x <- c(x_q1, x_q3)
y <- c(y_q1, y_q3)
capt <- names(y)
capt <- gsub("q1", "quarter 1", capt)
capt <- gsub("q3", "quarter 3", capt)

# plot

#cols <- colorRampPalette(c("red", "light blue"))(25) 
cols <- rev(turbo(100)[15:100])
rng<- c(35, 100) # makes all graph have the same range
sub <- letters
lege <- ext(18000000, 19000000, -1690253, 15544802)

rng<- c(35, 100) # makes all graph have the same range
width <- 8
#height <- width * e_ratio
height = 8
#height <- round(width / e_ratio, 0)
print(paste0("width: ", width, ", height: ", height))
out_f_png <- paste0("GCBheatstress_figure8_", "q1Nq3", "_", regionChoice, ".png")
png(file.path("output", out_f_png), units="in", width = width, height = height, res = 300)

par(mfrow=c(1,3), mai = c(.1, 0.1, 0.1, 0.1), omd = c(0,1,0,1))
layout(
  matrix(c(1,2,5,3,4,5), 2, 3, byrow = TRUE),
  widths=c(1,1,.2))#, heights = c(.5,.5,1))
for (i in 1:4) {
  plot(grat, col = "gray", background = "azure", lty=2, mar = c(.1,.1,.1,.1),  lwd = .3, labels = FALSE)
  polys(r, col=gray(.99), lwd = .1, alpha = 1)
  # plot(x[[i]], add=TRUE, axes=FALSE, col=cols, legend=i==4, plg=list(ext=lege, cex=1.1), xpd=TRUE, range=rng)
  plot(x[[i]], add=TRUE, axes=FALSE, col=cols, legend=F, xpd=TRUE, range=rng, buffer = "T")
  text(xm - xm*.3, ym +ym*.05 , cex = 1, (bquote(paste((bold(.(letters[i])))*'               ', .(capt[i])))))
}
# add legend

plot(cbind(c(0,1), c(0,1)), type = "n", axes = F, xlab = "", ylab = "")
text(.1, .79, pos=4, xpd = TRUE, paste0("PWC (%)"), cex=1) # legend caption
plot(bad, legend.only=T, col=cols, plg=list(ext=ext(c(.2, .4, .25, 0.75)), cex = .8), range=rng, xpd = TRUE) # get legend from 'bad'

dev.off()
 # tmp <- file.path("output", out_f_pdf)
 # system2('pdfcrop', c(tmp, tmp)) # gets rid of white space around the figure in the pdf

