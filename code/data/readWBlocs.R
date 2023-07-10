library(tidyverse)
library(ggmap)
library(openxlsx)

projects <- read.csv("wbprojects/WB_projects.csv")

projects <- filter(projects, location != "NA")

projects <- mutate_geocode(projects,location)

#google_key()

geocode("Oriniquia, Colombia")

geocode("St George,Grenada")

write.csv(projects, "wbprojects/WBprojinfo.csv")
