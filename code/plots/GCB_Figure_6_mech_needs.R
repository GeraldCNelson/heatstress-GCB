# create Figure 6. The additional HP per crop area in a country to increase the ratio to 1.0
library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (grepl("Mac", this, fixed=TRUE)) terraOptions(verbose = TRUE, memfrac = 0.8)

library(data.table)
prj_rob <- "+proj=robin"
prj_latlon <- "+proj=longlat +datum=WGS84"
noAnt <- ext(-180,180, -60, 90)
e <- project(noAnt, from = prj_latlon, to = prj_rob)

grat <- graticule(30, crs = prj_rob)  |> crop(e)
w <- geodata::world(path = "data-raw/gadm")  |> crop(noAnt) |> project(prj_rob)

temp <- as.data.table(read.csv("data-raw/machines/ERSmach_land_labor.csv")) # created in ERS_mach_land_labor.R, machinery, land and labor
temp <- temp[year > 2017,]
temp[, c("FAO", "Region", "Sub.Region") := NULL]

reqHP <- 1 # Each country should have at least 1 hp/ha
temp <- temp[, lapply(.SD, mean), by = ISO3, .SDcols = c("ERSvalue_machinery", "ERSvalue_land", "ERSvalue_cropland", "ERSvalue_labor", "mech_cropland_ratio", "mech_labor_ratio" )]

temp[, HPgap := reqHP - mech_cropland_ratio] 
temp[HPgap < 0, HPgap := 0]
temp[, HPNeeded := HPgap * ERSvalue_cropland ] #ERSvalue_labor and HPneeds_global <- sum(temp$HPgap)

w <- merge(w, temp, by.x = "GID_0", by.y = "ISO3", all.x = F)
HPgap_sum <- sum(temp$HPNeeded)
HP_gap_ratio <- HPgap_sum / sum(temp$ERSvalue_machinery)
print(paste0("2020 total ag HP (million HP(CV)): ", round(sum(temp$ERSvalue_machinery/1000), 0), ", Added HP needed (million HP(CV)) to provide every hectare with ", reqHP, " HP: ", round(HPgap_sum/1000, 0)))

make_fig6 <- function() {
  par(family = "Times New Roman", fig = c(0, 0.9, 0, 1) )#, fg = mycol, col = mycol, col.axis = mycol, col.lab = mycol, col.main = mycol, col.sub = mycol)
  plot(grat, col = "gray", background="azure", lty = 2, mar = c(0,0,1.5,0), labels = FALSE)
  plot(w, "HPgap", breaks = c(.1, .3,  .5, .7, .9, 1), add = TRUE, axes = FALSE, legend = F)
  plot(w, "HPgap", breaks = c(.1, .3,  .5, .7, .9, 1), axes = FALSE, legend.only = T, 
       plg = list(cex = 0.8, title.cex = 0.8, title="Additional\nHP/ha")
  )
}

pngfile = paste0("plots/Fig6_country_HP_needs.png")
h = 5
png(pngfile, units="in", width = 1.3*h, height = h, res = 300)

make_fig6()
dev.off()
