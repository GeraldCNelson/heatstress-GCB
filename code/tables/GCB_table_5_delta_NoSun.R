
this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
  setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {
  setwd('/Users/gcn/Google Drive/My Drive/pwc')
}

path <- "data-raw/ISIMIP/pwc_agg3"
path_ns <- "data-raw/ISIMIP/pwc_agg3_ns"

dir.create("figures", F, F)

library(terra)

crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm=TRUE) |> round()

fig_cumul <- function(avar="annual", legend=TRUE) {
  
  ff <- list.files(path, pattern = paste0(avar, ".*_mean.tif$"), full=TRUE)
  r <- rast(ff)/100 # divide by 100 to get to ratio rather than %
  names(r) <- gsub("^pwc_", "", names(r))
  names(r) <- gsub("; ", "", names(r))
 n <- nlyr(r)
  
  r <- c(crps, r) |> round(2) |> mask(crps, maskvalue=0)

  d <- as.data.frame(r)
  
  x <- lapply(1:n, \(i) {
    a <- aggregate(d[,1,drop=FALSE], d[,i+1,drop=FALSE], sum) 
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
  colnames(y) <- paste0(avar, c("_.10", "_.50", "_.90"))
 y
}

fig_cumul_ns <- function(avar="annual", legend=TRUE) {
  
  ff <- list.files(path_ns, pattern = paste0(avar, ".*_mean_ns.tif$"), full=TRUE)
  r <- rast(ff)/100
  names(r) <- gsub("^pwc_", "", names(r))
  names(r) <- gsub("; ", "", names(r))
  n <- nlyr(r)
  
  r <- c(crps, r) |> round(2) |> mask(crps, maskvalue=0)
  
  d <- as.data.frame(r)
  
  x <- lapply(1:n, \(i) {
    a <- aggregate(d[,1,drop=FALSE], d[,i+1,drop=FALSE], sum) 
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
  colnames(y) <- paste0(avar, c("_.25", "_.50", "_.75"))
  y
}

ya <- fig_cumul("annual")
yb <- fig_cumul("season", F)
yc <- fig_cumul("hot90", F)

ya_ns <- fig_cumul_ns("annual")
yb_ns <- fig_cumul_ns("season", F)
yc_ns <- fig_cumul_ns("hot90", F)

ya_delta <- ya_ns - ya
yb_delta<- yb_ns - yb
yc_delta<- yc_ns - yc

tab1 <- data.frame(ssp=rownames(ya), ya_delta, yb_delta, yc_delta)
rownames(tab1) <- NULL
colnames(tab1) <- gsub("hot90", "Hottest period", colnames(tab1))
tab1
write.csv(tab1, "tables/table5_avePWC_3types_NoSunDelta.csv", row.names=FALSE)

# convert csv to nice table
library(flextable)
library(officer)
library(data.table)
set_flextable_defaults(font.family = "Times New Roman")

t <- as.data.table(tab1)
names(t) = gsub("_.", "", names(t))

t[[1]] <- gsub("_", ", ", t[[1]])
t[[1]] <- gsub("ssp", "SSP ", t[[1]])
t[[1]] <- gsub("126", "1-2.6", t[[1]])
t[[1]] <- gsub("585", "5-8.5", t[[1]])
cheadername <- names(t)
cnewname <- c("PWC percentile", "0.1", "0.5", "0.9", "0.1", "0.5", "0.9", "0.1", "0.5", "0.9")
cvalues <- setNames(cnewname, cheadername)

t_flex <- flextable(t) |> 
  set_header_labels(values = cvalues) |>
  add_header_row(colwidths = c(1, 3, 3, 3),
                 values = c("Emission scenario & period", "Annual", "Growing season", "Hottest period")) |> 
  
  theme_vanilla() |> 
  color(part = "footer", color = "#666666") |>
  align(align = "center", part = "header") 
t_flex
save_as_docx(t_flex, values = NULL, path = "tables/table5_avePWC_3types_NoSunDelta.docx")





