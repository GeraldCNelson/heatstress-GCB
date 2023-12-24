# machinery as adaptation

library(terra)
library(data.table)
path <- "compute_pwc/output"

# ERS data
# mech_labor_ratio is the horsepower per worker in 2020
temp <- as.data.table(read.csv("data-raw/machines/ERSmach_land_labor.csv"))
max(temp$mech_labor_ratio, na.rm = TRUE)
temp <- temp[year > 2019, ] # get just 2020 data
hpmax <- 70
temp[, adj := 1 - (.8 * (mech_labor_ratio) / hpmax)]
temp <- temp[!adj < 0, ]
temp[, adj_workers := ERSvalue_labor * adj]

hist(temp$adj)
hist(temp$adj_workers)
hist(temp$mech_labor_ratio, breaks = c(min(temp$mech_labor_ratio), 2, 4, 6, 8, 10, 12, max(temp$mech_labor_ratio)))

#
# adj_workers_i = workers_i * adj_i]
# adj_i <- 1 - 0.8 * (mech_labor_ratio) / hpmax
# adj_workers_i = workers_i * adj_i
