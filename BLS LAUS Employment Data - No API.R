library(dplyr)

# Pull the series that match these criteria:
# MSA (area_type_code = B) 
# Employment (measure_code = 5)
# Not Seasonally Adjusted (seasonal = U)
# Monthly Data (period != M13)

la.series <- read.delim('~/data/LAUS/la.series') %>%
  filter(area_type_code == "B", measure_code == 5, seasonal == "U")

la.series$msa.name <- gsub("Employment: ", "", as.character(la.series$series_title))
la.series$msa.name <- gsub("[(U)]", "", la.series$msa.name)
la.series$msa.name <- gsub(" Metropolitan Statistical Area ", "", la.series$msa.name)
la.series$msa.name <- gsub(" Metropolitan NECTA ", "", la.series$msa.name)
la.series[la.series$msa.name == "tica-Rome, NY",]$msa.name <- "Utica-Rome, NY"

la.series <- select(la.series, msa.name, series_id) %>%
  arrange(msa.name)


data <- read.delim('~/data/LAUS/la.data.0.CurrentU00-04') %>%
  filter(series_id %in% la.series$series_id, period != "M13")
data$value <- as.numeric(as.character(data$value))

temp <- read.delim('~/data/LAUS/la.data.0.CurrentU05-09') %>%
  filter(series_id %in% la.series$series_id, period != "M13")
temp$value <- as.numeric(as.character(temp$value))

# Append rows
data <- rbind(data, temp)

temp <- read.delim('~/data/LAUS/la.data.0.CurrentU10-14') %>%
  filter(series_id %in% la.series$series_id, period != "M13")
temp$value <- as.numeric(as.character(temp$value))

# Append rows
data <- rbind(data, temp)

data <- merge(data, la.series)

# Remove Temp and la.series Data Frames
rm(temp, la.series)

str.date <- paste0(substr(data$period, 2,3), "-01-", data$year)
data$date <- as.Date(str.date,format="%m-%d-%Y")
#data$p.date <- as.POSIXlt(data$date)

rm(str.date)

# 2000 Employment Levels
y2k <- select(data, series_id, value, period, year) %>%
  filter(period == "M01", year == 2000) %>%
  select(series_id, value) 
names(y2k) <- c('series_id', 'y2k.value')
data <- merge(data, y2k)
rm(y2k)

data$y2k.emp.indx <- (data$value / data$y2k)*100

# Pre Great Recession Employment Levels
pre.gr <- select(data, series_id, value, period, year) %>%
  filter(period == "M11", year == 2007) %>%
  select(series_id, value) 
names(pre.gr) <- c('series_id', 'pre.gr.value')

data <- merge(data, pre.gr)
rm(pre.gr)
data$emp.indx <- (data$value / data$pre.gr)*100

#data$keep <- 1
#data[data$year < 2008,]$keep <- 0
#data[data$year == 2007 && data$period == "M12"] <- 1
#data <- data[data$keep == 1,]

library(ggplot2)
library(scales)
ggplot(data, aes(x=date, y=y2k.emp.indx, group = series_id)) + stat_smooth( method="loess", se=F, color=alpha("#222222", .1)) + scale_x_date() + theme(axis.title.x = element_blank()) + ylab("Employment Index (Jan 2000 = 100)")

ggplot(data, aes(x=date, y=emp.indx, group = series_id)) + stat_smooth( method="loess", se=F, color=alpha("#222222", .1)) + scale_x_date() + theme(axis.title.x = element_blank()) + ylab("Employment Index (Nov 2007 = 100)")
