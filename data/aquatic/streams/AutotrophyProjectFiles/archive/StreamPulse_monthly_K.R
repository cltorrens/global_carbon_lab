##### The purpose of this script is to get monthly K values from the Bernhardt et al. 2018
#     "high_quality_daily_metabolism_with_SP_covariates.rds" dataset
#
# Author: Christa Torrens
# Date: 02 December 2024



# load packages
library(tidyverse) # includes dplyr, forcats, ggplot2, lubridate, purrr, readr, stringr, tibble, tidyr
library(here)
library(leaflet)


# load data
df <- readRDS(here("data/aquatic/streams/AutotrophyProjectFiles/SupplementalData/high_quality_daily_metabolism_with_SP_covariates.rds"))

# Calculate the average monthly K values for each site
monthly_df <- df %>%
  mutate(month = month(date)) %>%  # Extract the month from the date column
  group_by(site_name, long_name, year, month) %>%  # Group by site_name, year, and month
  summarize(
    avg_K600 = mean(K600, na.rm = TRUE), 
    avg_K600.lower = mean(K600.lower, na.rm = TRUE),
    avg_K600.upper = mean(K600.upper, na.rm = TRUE),
    .groups = "drop"  # Drops the grouping after summarizing
  )


write.csv(monthly_df, here("data/aquatic/streams/AutotrophyProjectFiles/StreamPulse_monthly_K.csv"), row.names = FALSE)

## where are these sites?
df2 <- read_csv(here('data/aquatic/streams/AutotrophyProjectFiles/20210902_streampulse_synthesis_statset.csv'))
  
map_df <- df2 %>%
  select(sitecode, Name, Lat, Lon, COMID) %>%
  # Create a popup column
  mutate(popup = paste0(
    "<b>Site:</b> ", sitecode, "<br/>",
    "<b>Name:</b> ", Name, "<br/>",
    "<b>COMID:</b> ", COMID
  ))


# Create interactive map with OpenStreetMap tiles
leaflet(map_df) %>%
  addTiles() %>%  # default is OpenStreetMap
  addMarkers(lng = ~Lon, lat = ~Lat, popup = ~popup) %>%
  fitBounds(lng1 = min(map_df$Lon), lat1 = min(map_df$Lat),
            lng2 = max(map_df$Lon), lat2 = max(map_df$Lat))  
  

  
