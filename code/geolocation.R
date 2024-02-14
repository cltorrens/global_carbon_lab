closeAllConnections() # closes all file connections (like PDFs, PNGs, CSVs)
rm(list = ls()) # Clear variables
cat("\014") # Clear console

# Objective ---------------------------------------------------------------
# Synthesize datasets geographically


# Progress ----------------------------------------------------------------
# First pass on

# Libraries ---------------------------------------------------------------
setwd('~/flux/data/')
library(dplyr)
# library(tidyr)
library(sf)
library(ggplot2)
source('~/flux/code/project_functions.R')

# Import data -------------------------------------------------------------
site_info <- read.csv('aquatic/edi.643.5/siteInformation.csv', row.names = NULL)
lake_data <- read.csv('aquatic/edi.643.5/LakeData.csv', row.names = NULL)
holgerson_lake_data <- read.csv('aquatic/LakeMetabolismHolgerson.csv', row.names = NULL)

# Datasets with DOC -------------------------------------------------------
doc <- lake_data %>% 
  filter(Variable == 'doc')
doc_lakes <- semi_join(site_info, doc, by = "SiteID") # captures only SiteID's that match with doc
names(doc_lakes) <- c('site_ID', 'site_name', 'latitude', 'longitude', 'elevation', 'country', 'state') # I can't deal with capital letters

# Select lat/long coordinates for each location and label them by dataset
lat_long_holg <- holgerson_lake_data %>%
  select(latitude, longitude) %>% 
  distinct(latitude, longitude)%>%  # excludes multiple observations at one location (creates only one data point for mapping)
  mutate(dataset = 'holgerson')
lat_long_doc_lakes <- doc_lakes %>% 
  select(latitude, longitude) %>% 
  distinct(latitude, longitude) %>% # excludes multiple observations at one location (creates only one data point for mapping)
  mutate(dataset = 'lakes_1') # Non-holgerson lakes dataset
df_combined_lakes <- rbind(lat_long_holg, lat_long_doc_lakes) # Each coordinate will correspond to the dataset it was derived from


# Transform data frame into georeferenced point data -----------------------
geo_lakes <- st_as_sf(df_combined_lakes, coords = c("longitude", "latitude"), crs = 4326) # crs projection set to lat long
st_write(geo_lakes, 'geospatial/georeferenced_doc_lakes_williamson_holgerson.shp') # Write shapefile of points


# Flux data ---------------------------------------------------------------
data_terrestrial <- read.table("terrestrial/Fluxnet2015globalagesub.txt", header = TRUE, sep = "\t")
df_terrestrial <- data_terrestrial %>% 
  rename(latitude = LOCATION_LAT, longitude=LOCATION_LONG)%>% 
  select(latitude, longitude) %>% 
  distinct(latitude, longitude) %>% 
  mutate(dataset = 'flux_data')
geo_flux <- st_as_sf(df_terrestrial, coords = c("longitude", "latitude"), crs = 4326)
st_write(geo_flux, 'geospatial/georeferenced_flux_2015_dataset.shp')
# Aquatic and Terrestrial -------------------------------------------------
df_lakes_flux <- rbind(df_terrestrial, df_combined_lakes)
geo_lakes_flux <- st_as_sf(df_lakes_flux, coords = c("longitude", "latitude"), crs = 4326)
st_write(geo_lakes_flux, 'geospatial/georeferenced_doc_lakes_williamson_holgerson_flux.shp')


# Maps --------------------------------------------------------------------
library(rnaturalearth)
world <- ne_countries(scale = "medium", returnclass = "sf") # World basemap
# Aquatic only
ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") + # Base layer of world map
  geom_sf(data = geo_lakes, aes(color = dataset)) + 
  theme_minimal() +
  labs(title = "Aquatic DOC by dataset",
       x = "Longitude",
       y = "Latitude")

# Flux only
ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") + # Base layer of world map
  geom_sf(data = geo_flux, aes(color = dataset)) + 
  theme_minimal() +
  labs(title = "Flux Sites",
       x = "Longitude",
       y = "Latitude")

# Lakes and Flux
ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") + # Base layer of world map
  geom_sf(data = geo_lakes_flux, aes(color = dataset)) + 
  theme_minimal() +
  labs(title = "DOC Lake Data and Flux 2015 dataset",
       x = "Longitude",
       y = "Latitude")
