# code to estimate the differences in using daily averages versus hourly values for 
# The mean temperature is about 2C colder than the mean temperature during the day
library(meteor)
temps <- function(tmin, tmax, doy, lat) {
  tmp <- hourlyFromDailyTemp(tmin, tmax, doy, lat)
  hp <- photoperiod(doy, lat) / 2
  day <- round((12 - hp) :(12 + hp))
  morn <- round((12 - hp) : 12)
  ampm <- round(c((12 - hp):12, 16:(12 + hp)))
  
  round(c(mean=mean(tmp), morning=mean(tmp[morn]), day=mean(tmp[day]), ampm=mean(tmp[ampm])), 1)
}

temps(10, 30, doy=1, lat=0)
temps(10, 30, doy=1, lat=50)
temps(10, 30, doy=180, lat=50)

# pwc by hour 
pwc_hr <- function(tmin, tmax, rhum, doy, lat) {
  rh <- hourlyFromDailyRelh(rhum, tmin, tmax, doy, lat) |> as.vector()
  tmp <- hourlyFromDailyTemp(tmin, tmax, doy, lat) |> as.vector()
  wind <- 10
  srad <- 100
  date <- fromDoy(doy, 2000)
  d <- data.frame(temp=tmp, rhum=rh, wind=wind, srad=srad, date=date)
  phr <- pwc(WBGT(d, lat)) # hourly PWC
  hp <- photoperiod(doy, lat) / 2
  day <- round((12 - hp):(12 + hp))
  pday <- mean(phr[day])
  phrmean <- mean(phr)
  d <- data.frame(temp=mean(tmp), rhum=rhum, wind=10, srad=100, date=date)
  pmean <- pwc(WBGT(d, lat))
  list(phr, pday, phrmean, pmean)	
}

# blue line is the pwc computed with the daily values
# green line is the mean pwc computed with hourly values
# red line is the mean pwc during the day computed with hourly values

p <- pwc_hr(10, 30, 80, 180, 50)
plot(1:24, p[[1]], las = 1, main = "Compare PWC estimates with \ndaily and hourly input values", 
     sub = "Circles indicate hourly PWC values with hourly input values.\nLines are the daily mean PWC value with different variable inputs.", xlab="", ylab="PWC", cex.sub=.9, mgp=c(3,1,0))
title(xlab="hours", line=2, cex.lab=0.8)
abline(h=p[[2]], col="red", lwd=2)
abline(h=p[[3]], col="blue", lwd=2)
abline(h=p[[4]], col="green", lwd=2)
legend("topright", legend = c("- hourly values during the day", "- daily values", "- hourly values"), cex=0.8, title = "Mean PWC using inputs...", 
       col = c("red", "blue", "green"), lty = 1)
