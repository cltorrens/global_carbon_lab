closeAllConnections() # closes all file connections (like PDFs, PNGs, CSVs)
rm(list = ls()) # Clear variables
cat("\014") # Clear console

# Objective ---------------------------------------------------------------
# Site locations by watershed


# Progress ----------------------------------------------------------------
# First pass on
# These are the two data sets to merge for stream pulse: all_basic_site_data.csv and all_model_summary_data.csv

# Libraries ---------------------------------------------------------------
setwd('~/flux/data/')
library(dplyr)
# library(tidyr)
library(sf)
library(ggplot2)


# Import data -------------------------------------------------------------
# All USA watersheds
us_watersheds_huc06 <- st_read('geospatial/usa_huc_8.shp')
# Terrestrial
data_terrestrial <- read.table("terrestrial/Fluxnet2015globalagesub.txt", header = TRUE, sep = "\t")
# Lake
site_info_williamson <- read.csv('aquatic/edi.643.5/siteInformation.csv', row.names = NULL)
lake_data_williamson <- read.csv('aquatic/edi.643.5/LakeData.csv', row.names = NULL)
holgerson_lake_data <- read.csv('aquatic/LakeMetabolismHolgerson.csv', row.names = NULL)

# Stream
stream_pulse_sites <- read.csv('aquatic/stream_pulse/all_basic_site_data_location_completed.csv', row.names = NULL)
# stream_pulse_model_summary <- read.csv('aquatic/stream_pulse/all_model_summary_data.csv', row.names = NULL)
# stream_merged <- read.csv('aquatic/stream_pulse/site_merge_MTN_edited.csv')

lakes_flux_stream <- st_read('geospatial/georeferenced_doc_lakes_williamson_holgerson_flux_stream_pulse.shp')
# Maps --------------------------------------------------------------------
library(rnaturalearth)
world <- ne_countries(scale = "medium", returnclass = "sf") # World basemap

# Lakes and Flux and Streams
ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") + # Base layer of world map
  geom_sf(data = lakes_flux_stream, aes(color = dataset), size = 0.5) + # Adjust point size here
  theme_minimal() +
  labs(title = "DOC Lake Data and Flux 2015 dataset and Stream Pulse",
       x = "Longitude",
       y = "Latitude")
