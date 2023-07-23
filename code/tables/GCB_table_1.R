library(terra)

path <- "data/agg/pwc_agg3"
dir.create("tables", F, F)

regions <- c("global", "tropical", "S20N35")

crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm = TRUE) |> round()

get_cumul <- function(avar="annual", legend=TRUE, region = "global") {
  if (region=="global") {
    extRegion <- ext(-180, 180, -60, 67)
  } else if (region == "tropical") {
	extRegion <- ext(-180, 180, -23, 23)
  } else if (region == "S20N35") {
	extRegion <- ext(-180, 180, -20, 35)
  } else {
	stop("unknown region")
  }
  
  ff <- list.files(path, pattern = paste0(avar, ".*_mean.tif$"), full = TRUE)
  r <- rast(ff) / 100 # convert from % to ratio
  names(r) <- gsub("^pwc_", "", names(r))
  names(r) <- gsub("; ", "", names(r))
  n <- nlyr(r)
  
  r <- c(crps, r) |> round(2) |> mask(crps, maskvalue = 0)
  r <- crop(r, extRegion)
  
  d <- as.data.frame(r)
  
  x <- lapply(1:n, \(i) {
    a <- aggregate(d[,1,drop = FALSE], d[,i+1,drop = FALSE], sum) 
    a[,2] <- cumsum(a[,2] / sum(a[,2]))
    a
  })
  
  names(x) <- names(d)[-1]
  y <- lapply(x, \(i) {
    c(i[which.min(abs(i[,2]-0.10)), 1],
      i[which.min(abs(i[,2]-0.50)), 1],
      i[which.min(abs(i[,2]-0.90)), 1])
  })
  y <- do.call(rbind, y)
  colnames(y) <- paste0(avar, c("_.1", "_.5", "_.9"))
  y
}

make_tables <- function(regions) {
	library(flextable)
	library(officer)
	library(data.table)

	for (region in regions) {
	  ya <- get_cumul("annual", F, region)
	  yb <- get_cumul("season",F, region)
	  yc <- get_cumul("hot90", F, region)
	  
	  tab1 <- data.frame(ssp=rownames(ya), ya, yb, yc)
	  rownames(tab1) <- NULL
	  colnames(tab1) <- gsub("hot90", "Hottest period", colnames(tab1))
	  tab1
	  outf <- paste0("tables/table1_avePWC_3types_", region, ".csv")
	  write.csv(tab1, outf, row.names = FALSE)
	  
	  # convert csv to nice table
	  t <- as.data.table(tab1)
	  names(t) = gsub("_.", "", names(t))
	  s
	  t[[1]] <- gsub("_", ", ", t[[1]])
	  t[[1]] <- gsub("ssp", "SSP ", t[[1]])
	  t[[1]] <- gsub("126", "1-2.6", t[[1]])
	  t[[1]] <- gsub("370", "3-7.0", t[[1]])
	  t[[1]] <- gsub("585", "5-8.5", t[[1]])
	  cheadername <- names(t)
	  cnewname <- c("Area percentile", "10", "50", "90", "10", "50", "90", "10", "50", "90")
	  cvalues <- setNames(cnewname, cheadername)
	  
	  t_flex <- flextable(t) |> 
		set_header_labels(values = cvalues) |>
		add_header_row(colwidths = c(1, 3, 3, 3),
					   values = c("Thermal environment, SSP & period", "Annual", "Growing season", "Hottest period")) |> 
		
		theme_vanilla() |> 
		color(part = "footer", color = "#666666") |>
		align(align = "right", part = "header") 
	  t_flex
	  path_out <- paste0("tables/table1_avePWC_3types_", region, ".docx")
	  save_as_docx(t_flex, values = NULL, path = path_out)
	  print(t_flex, preview = "docx", pr_section = sect_properties)
	}
}

make_tables(regions)



