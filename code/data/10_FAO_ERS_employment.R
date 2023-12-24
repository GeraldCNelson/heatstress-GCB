# creates rasterized versions of the country specific ag labor data from FAO and ERS. GCB paper uses ERS version
library(terra)
terraOptions(verbose = TRUE)
this <- system("hostname", TRUE)
if (grepl("Mac", this, fixed = TRUE)) terraOptions(verbose = TRUE, memfrac = 0.8)

library(geodata)
dir.create("data-raw/employment", FALSE, FALSE)

FAO_employment <- function() {
  # employment ------
  outf <- "data-raw/employment/clean_employment_FAO.rds"
  url <- "https://fenixservices.fao.org/faostat/static/bulkdownloads/Employment_Indicators_Agriculture_E_All_Data_(Normalized).zip"
  f <- paste0("data-raw/employment/", basename(url))
  if (!file.exists(f)) {
    dir.create(dirname(f), FALSE, TRUE)
    download.file(url, f)
    unzip(f, exdir = "data-raw/employment")
  }
  fc <- gsub("zip$", "csv", f)
  d <- read.csv(fc, encoding = "latin1")

  # here using the last three years available: 2018-2020
  d <- d[d$Sex == "Total" & d$Year > 2017, ]
  d <- d[d$Indicator == "Employment in agriculture, forestry and fishing - ILO modelled estimates", ]
  # number of people employed in Ag by country
  x <- d[, c("Area", "Value")]
  x$persons <- x$Value * 1000
  x$Value <- NULL
  # average over years
  x <- aggregate(x[, "persons", drop = FALSE], x[, "Area", drop = FALSE], mean, na.rm = TRUE)

  # match FAO names with ISO codes
  cc <- na.omit(geodata::country_codes()[, c("NAME_FAO", "ISO3")])
  # there is no Sudan, but we have
  cc$NAME_FAO[cc$ISO3 == "SDN"] <- "Sudan (former)"
  # probably need to subtract South Sudan from this number.

  m <- merge(cc, x, by = 1, all.x = TRUE)
  m$persons[m$ISO3 == "SDN"] <- m$persons[m$ISO3 == "SDN"] - m$persons[m$ISO3 == "SSD"]
  # French Guyana is largish country with no FAO data as it is part of France
  # assume (based on population size) that it is half that of Suriname
  m$persons[m$ISO3 == "GUF"] <- m$persons[m$ISO3 == "SUR"] / 2
  m$persons[m$ISO3 == "FRA"] <- m$persons[m$ISO3 == "FRA"] - m$persons[m$ISO3 == "GUF"]
  names(m) <- c("NAME", "ISO3", "persons")
  saveRDS(m, outf)
  m
}

ERS_employment <- function() {
  outf <- "data-raw/employment/clean_employment_ERS.rds"
  url <- "https://www.ers.usda.gov/webdocs/DataFiles/51270/AgTFPInternational2020_long.xlsx?v=8337"
  f <- paste0("data-raw/machines/", basename(url))
  if (!file.exists(f)) {
    dir.create(dirname(f), FALSE, TRUE)
    download.file(url, f)
    unzip(f, exdir = "data-raw/machines")
  }
  f <- paste0("data-raw/machines/", "AgTFPInternational2020.xlsx")
  d <- as.data.table(readxl::read_xlsx(path = f, sheet = "Labor", range = "B3:F182", na = "NA")) # names, etc
  d <- cbind(d, as.data.table(readxl::read_xlsx(paste0("data-raw/machines/", "AgTFPInternational2020.xlsx"), sheet = "Labor", range = "BT3:EA182", na = "NA"))) # quantity data
  oldNames <- as.character(1961:2020)
  newNames <- paste0("X", 1961:2020)
  setnames(d, old = oldNames, new = newNames, skip_absent = T)
  d[, (newNames) := lapply(.SD, as.numeric),
    .SDcols = newNames
  ]
  d <- melt(d, id.vars = c("FAO", "ISO3", "Country/territory", "Region", "Sub-Region"), variable.name = "year", value.name = paste0("ERSvalue_", tolower("Labor")), variable.factor = FALSE)
  d[, year := gsub("X", "", year)]
  d <- d[year > 2017, ]
  d <- d[, c("FAO", "Region", "Sub-Region") := NULL]
  setnames(d, old = "Country/territory", new = "NAME")
  setorder(d, NAME)
  x <- d[, persons := mean(ERSvalue_labor), by = "NAME"]
  x[, c("ERSvalue_labor", "year") := NULL]
  x <- unique(x)
  x[, persons := persons * 1000] # to get in same units as the FAO numbers

  saveRDS(d, outf)
  x
}

get_labor <- function(src) {
  outf <- paste0("data-raw/labor_", src, ".tif")
  # 	if (file.exists(outf)) return(rast(outf))

  if (src == "FAO") {
    emp <- FAO_employment()
  }
  if (src == "ERS") {
    emp <- ERS_employment()
  }

  w <- geodata::world(path = "data-raw/gadm")
  w <- merge(w, emp, by.x = "GID_0", by.y = "ISO3", all.x = TRUE)

  # created with "crop_data.R"
  crps <- rast("data-raw/crops/total_crop_area.tif")
  w$crparea <- extract(crps, w, "sum", na.rm = TRUE, ID = FALSE)
  w$dens <- w$persons / w$crparea
  w$dens[!is.finite(w$dens)] <- NA
  w$dens[w$dens > 15] <- NA # Djibouti and Hong Kong, huge outliers
  # a few very small countries
  w$dens[is.na(w$dens)] <- median(w$dens, na.rm = TRUE)
  w$dens[w$GID_0 %in% c("ATA", "GRL")] <- NA

  labor <- rasterize(w, crps, "dens")
  labor <- focal(labor, w = 5, fun = mean, na.policy = "only")
  labor <- subst(labor, NA, median(w$dens, na.rm = TRUE))
  labor <- labor * crps
  writeRaster(labor, outf, overwrite = TRUE, names = "aglabor")
}

lab <- get_labor("ERS")
lab_fao <- get_labor("FAO")
