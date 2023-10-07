
this <- system('hostname', TRUE)
library(terra)
terraOptions(verbose = TRUE)
this <- system('hostname', TRUE)
if (grepl("Mac", this, fixed=TRUE)) terraOptions(verbose = TRUE, memfrac = 0.8) # only used if on a Mac
}
path <- "data-raw/ISIMIP/pwc_agg3"

dir.create("plots", F, F)

library(data.table)
cval <- 100 # used to convert from percent to ratio
crps <- rast("data-raw/crops/total_crop_area.tif") |> 
  aggregate(6, sum, na.rm = TRUE) |> crop(c(-180, 180, -60, 67)) |>  round()

w <- geodata::world(path = "data-raw", version="3.6")

ff <- list.files(path, pattern = ".*_mean.tif$", full = TRUE)
s <- sds(ff)
z <- lapply(s, \(r) zonal(r, w, mean, na.rm = TRUE))
zz <- do.call(cbind, z)
names(zz) <- gsub("mean_", "", gsub("pwc_", "", paste0(rep(names(s), each=5), "_", names(zz))))
zz <- cbind(values(w), zz) # annual, growing season and hot window for all countries
zz[,-c(1:2)] <- round(zz[,-c(1:2)], 0)
names(zz)[1:2] <- c("ISO3", "Name")
x <- zz[complete.cases(zz), ] # remove rows with NAs
x[,3:ncol(x)] <- x[,3:ncol(x)] / cval # convert percent to ratio
x <- x[, -1]
write.csv(x, "tables/SM_table_1_all_countries.csv", row.names = FALSE)

library(flextable)
library(officer)
library(stringr)
set_flextable_defaults(font.family = "Times New Roman")

# directions - https://stackoverflow.com/questions/71661066/is-there-a-function-in-flextable-to-group-a-few-rows-in-a-table-together-under-a
set_flextable_defaults(font.color = "#333333", border.color = "#999999", padding = 4)
col_labels <- str_replace(names(x), "_ssp126_", " SSP1-2.6, ") |> 
  str_replace("_ssp585_", " SSP5-8.5, ") |>
  str_replace("_historical_", " Historical, ") |>
  str_replace("annual ", "") |> 
  str_replace("hot90 ", "") |> 
  str_replace("season ", "")

shortNames <- gsub("2041-2060", "2041-60", names(x))
names_list <-  as.list(setNames(col_labels, names(x)))

sect_properties <- prop_section(
  page_size = page_size(
    orient = "landscape", width = 8.3, height = 11.7
  ),
  type = "continuous",
  page_margins = page_mar(
    bottom = .5, top = .5, right = .5, left = .5,
    header = 0.5,
    footer = 0.5,
    gutter = 0.5
  )
)
t_flex <- flextable(x)  |>
  set_header_labels(values = names_list) |>
  add_header_row(colwidths = c(2, 5, 5, 5), values = c(" ", "Annual", "Growing season", "Hottest period")) |>
  theme_vanilla() |> 
  color(part = "footer", color = "#666666") |>
  align(align = "center", part = "header") 

print(t_flex, preview = "docx", pr_section = sect_properties)

save_as_docx(t_flex, values = NULL, path = "tables/SM_table_1_all_countries.docx", pr_section = sect_properties)

