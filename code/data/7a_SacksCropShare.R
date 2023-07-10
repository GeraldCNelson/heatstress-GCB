library(terra)
library(geodata)
m <- crop_monfreda("all", "area_ha", path = "data-raw/crops")
x <- sum(m, na.rm = TRUE)

fc <- function(crp) {
  print(crp)
  m_sub <- crop_monfreda(crp, "area_ha", path = "data-raw/crops")
  return(m_sub)
}
crops_sub <- sacksCrops()
pln <- unique(sapply(strsplit(crops_sub, " \\("), \(i)i[1]))
pln <- gsub("oat", "oats", pln)
pln <- gsub("pulses", "pulsenes", pln)
m_sub <- lapply(pln, FUN = fc)
m_sub <- rast(m_sub)
x_sub <- sum(m_sub, na.rm = TRUE)

tot_area <- global(x, fun = "sum")
sub_area <- global(x_sub, fun = "sum")
sub_area/tot_area

