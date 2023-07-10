
this <- system('hostname', TRUE)
if (this == "LAPTOP-IVSPBGCA") {
  setwd("G:/.shortcut-targets-by-id/1mfeEftF_LgRcxOT98CBIaBbYN4ZHkBr_/share/pwc")
} else {
  setwd('/Users/gcn/Google Drive/My Drive/pwc')
}

path <- "data-raw/ISIMIP/pwc_agg3"

dir.create("figures", F, F)

library(terra)

crps <- rast("data-raw/crops/total_crop_area.tif", win = ext(-180, 180, -60, 67)) |> 
  aggregate(6, sum, na.rm=TRUE) |> round()

fig_cumul <- function(avar="annual", legend=TRUE) {
  
  ff <- list.files(path, pattern = paste0(avar, ".*_mean.tif$"), full=TRUE)
  
  r <- rast(ff)
  names(r) <- gsub("^pwc_", "", names(r))
  names(r) <- gsub("; ", "", names(r))
  
  # r <- r[[names(r) != "ssp126_2081-2100"]] # drop end century ssp126
  n <- nlyr(r)
  
  r <- c(crps, r) |> round(1) |> mask(crps, maskvalue=0)
  #	r <- round(r,1)
  #	r <- mask(r, crps, maskvalue=0)
  
  d <- as.data.frame(r)
  
  x <- lapply(1:n, \(i) {
    a <- aggregate(d[,1,drop=FALSE], d[,i+1,drop=FALSE], sum) 
    a[,2] <- cumsum(a[,2] / sum(a[,2]))
    a
  })
  
  names(x) <- names(d)[-1]
  capt <- gsub("_", ", ", names(x))
  
  y <- lapply(x, \(i) {
    c(i[which.min(abs(i[,2]-0.25)), 1],
      i[which.min(abs(i[,2]-0.50)), 1],
      i[which.min(abs(i[,2]-0.75)), 1])
  })
  y <- do.call(rbind, y)
  colnames(y) <- paste0(avar, c("_.25", "_.50", "_.75"))
  
  cols <- RColorBrewer::brewer.pal(n, "Set1")
  
  plot(x[[1]][,1], x[[1]][,2], col=cols[1], lwd=2, type="l", xlim=c(40,100), 
       las=1, xlab="PWC (%)", ylab="Fraction of global crop land", axes=FALSE,  
       yaxs="i",  xaxs="i")
  for (i in 2:n) {
    lines(x[[i]][,1], x[[i]][,2], col=cols[i], lwd=2, lty=i)
  }
  
  grid(NULL, 4)
  
  if (legend) {
    legend(42, .9, capt, lty=1:5, col=cols, cex=.8, lwd=3, bg="white")
  } 
  axis(1, xlab="PWC (%)", cex.axis=.9)
  axis(2, at=seq(0,1,.25), las=1, cex.axis=.9, labels=legend)
  
  i <- match(avar, c("annual", "season", "hot90"))
  text(42, 1, c("(A) Annual", "(B) Seasonal", "(C) Summer")[i], pos=4, xpd=TRUE) 
  y
}

outf <- "figures/pwc_cum_3types.png"
png(outf, units="in", width=12, height=4, res=300, pointsize=18)

par(mfrow=c(1,3))
par(mar=c(4,4,1,0))
ya <- fig_cumul("annual")
par(mar=c(4,2,1,2))
yb <- fig_cumul("season", F)
par(mar=c(4,0,1,4))
yc <- fig_cumul("hot90", F)

dev.off()

tab1 <- data.frame(ssp=rownames(ya), ya, yb, yc)
rownames(tab1) <- NULL
colnames(tab1) <- gsub("hot90", "Hottest period", colnames(tab1))
tab1
write.csv(tab1, "tables/table1_avePWC_3types.csv", row.names=FALSE)

# convert csv to nice table
library(flextable)
library(officer)
library(data.table)
t <- as.data.table(tab1)
names(t) = gsub("_.", "", names(t))

t[[1]] <- gsub("_", ", ", t[[1]])
t[[1]] <- gsub("ssp", "SSP ", t[[1]])
t[[1]] <- gsub("126", "1-2.6", t[[1]])
t[[1]] <- gsub("585", "5-8.5", t[[1]])
cheadername <- names(t)
cnewname <- c(" ", "(25%)", "(50%)", "(75%)", "(25%", "(50%)", "(75%)", "(25%", "(50%)", "(75%)")
cvalues <- setNames(cnewname, cheadername)

t_flex <- flextable(t) |> 
  set_header_labels(values = cvalues) |>
  add_header_row(colwidths = c(1, 3, 3, 3),
                 values = c("SSP & period", "Annual", "Growing season", "Hottest period")) |> 
  
  theme_vanilla() |> 
  color(part = "footer", color = "#666666") |>
  align(align = "center", part = "header") 
t_flex
save_as_docx(t_flex, values = NULL, path = "tables/table1_avePWC_3types.docx")





