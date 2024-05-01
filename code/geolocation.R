closeAllConnections() # closes all file connections (like PDFs, PNGs, CSVs)
rm(list = ls()) # Clear variables
cat("\014") # Clear console

# Objective ---------------------------------------------------------------
# Synthesize datasets geographically
# Note: the Williamson dataset is just DOC 
# This needs to be cleaned up a bit.

# IMPORTANT: MARZOLF RIO MARIA SITES DID NOT HAVE LAT LONG, I LOOKED
# UP THE PAPER BUT IT DIDN'T INCLUDE COORDINATES, MAY BE ABLE TO 
# FIGURE OUT LATER BUT THEY HAVE BEEN REMOVED FROM THE SHAPEFILE
# and caribean site only had latitude


# Progress ----------------------------------------------------------------
# Added map for metabolism only
# Libraries ---------------------------------------------------------------
setwd('~/flux/data/')
library(dplyr)
library(tidyr)
library(sf)
library(ggplot2)
source('~/flux/code/project_functions.R')

# Import data -------------------------------------------------------------
williamson_site_info <- read.csv('aquatic/edi.643.5/siteInformation.csv', row.names = NULL)
williamson_lake_data <- read.csv('aquatic/edi.643.5/LakeData.csv', row.names = NULL)
holgerson_lake_data <- read.csv('aquatic/LakeMetabolismHolgerson.csv', row.names = NULL)
# stream_pulse_sites <- read.csv('aquatic/stream_pulse/all_basic_site_data.csv', row.names = NULL)
# Updated locations:
stream_pulse_sites <- read.csv('aquatic/stream_pulse/all_basic_site_data_location_completed.csv', row.names = NULL)
marzolf_streams <- read.csv('aquatic/marzolf_data.csv', row.names = NULL)
data_terrestrial <- read.table("terrestrial/Fluxnet2015globalagesub.txt", header = TRUE, sep = "\t")

# Stream pulse fix missing lat/long in PR site -----------------------------------------
# Only run this the first time
stream_pulse_sites[is.na(stream_pulse_sites$latitude), ]
# Field Site Information (from NEON website)
# Latitude/Longitude for rio cupeyes (doesn't differentiate between Rio Cupeyes Upstream", "Rio Cupeyes Downstream")
# 18.11352, -66.98676

# Identify rows where latitude is NA and update them
na_latitude_rows <- is.na(stream_pulse_sites$latitude)
stream_pulse_sites$latitude[na_latitude_rows] <- 18.11352

# Identify rows where longitude is NA and update them
na_longitude_rows <- is.na(stream_pulse_sites$longitude)
stream_pulse_sites$longitude[na_longitude_rows] <- -66.98676

stream_pulse_sites[is.na(stream_pulse_sites$latitude), ] # All lat/longs filled
write.csv(stream_pulse_sites, 'aquatic/stream_pulse/all_basic_site_data_location_completed.csv', row.names=F)

# Datasets with DOC -------------------------------------------------------
doc <- lake_data %>% 
  filter(Variable == 'doc')
doc_lakes <- semi_join(site_info, doc, by = "SiteID") # captures only SiteID's that match with doc
names(doc_lakes) <- c('site_ID', 'site_name', 'latitude', 'longitude', 'elevation', 'country', 'state') # I can't deal with capital letters


# Marzolf -----------------------------------------------------------------
df_converted <- as.data.frame(lapply(marzolf_streams, as.character), stringsAsFactors = FALSE)
new_marzolf <- df_converted[1,] %>% 
  pivot_longer(cols = 1:41) %>% 
  mutate(across(everything(), ~if_else(. == "" | is.na(.), NA_character_, .)))
write.csv(new_marzolf, 'aquatic/marzolf_variables_units.csv')

df_marzolf_streams <- marzolf_streams[2:203,] %>% 
  rename(latitude = Latitude, longitude=Longitude) %>% 
  filter(!is.na(latitude)) %>% # removes rio maria panama 2 observations
  filter(!is.na(longitude))  # 21 other observations removed from the carribean site
  
shp_marzolf_streams <- st_as_sf(df_marzolf_streams, coords = c("longitude", "latitude"), crs = 4326)
st_write(shp_marzolf_streams, 'geospatial/marzolf_streams_panama_carribean_data_removed.shp')
df_marzolf_locations_only <- df_marzolf_streams %>% 
  select(latitude, longitude) %>% 
  distinct(latitude, longitude) %>% 
  mutate(dataset = 'marzolf') %>% 
  mutate(type = 'Streams')
shp_marzolf_locations_only <- st_as_sf(df_marzolf_locations_only, coords = c("longitude", "latitude"), crs = 4326)

# Holgerson ---------------------------------------------------------------
shp_holgerson <- st_as_sf(holgerson_lake_data, coords = c("longitude", "latitude"), crs = 4326)
st_write(shp_holgerson, 'geospatial/holgerson.shp')
# Combined datasets -------------------------------------------------------
# Select lat/long coordinates for each location and label them by dataset
lat_long_holg <- holgerson_lake_data %>%
  select(latitude, longitude) %>% 
  distinct(latitude, longitude)%>%  # excludes multiple observations at one location 
  mutate(dataset = 'holgerson')
df_holgerson <- holgerson_lake_data %>%
  select(latitude, longitude) %>% 
  distinct(latitude, longitude)%>%  # excludes multiple observations at one location 
  mutate(dataset = 'holgerson') %>% 
  mutate(type = 'Lakes')
  
lat_long_doc_lakes <- doc_lakes %>% 
  select(latitude, longitude) %>% 
  distinct(latitude, longitude) %>% 
  mutate(dataset = 'lakes_1') # Non-holgerson lakes dataset
df_combined_lakes <- rbind(lat_long_holg, lat_long_doc_lakes) # Each coordinate will correspond to the dataset it was derived from


# Transform data frame into georeferenced point data -----------------------
geo_lakes <- st_as_sf(df_combined_lakes, coords = c("longitude", "latitude"), crs = 4326) 
st_write(geo_lakes, 'geospatial/georeferenced_doc_lakes_williamson_holgerson.shp') 


# Flux data ---------------------------------------------------------------
data_terrestrial <- read.table("terrestrial/Fluxnet2015globalagesub.txt", header = TRUE, sep = "\t")
df_terrestrial <- data_terrestrial %>% 
  rename(latitude = LOCATION_LAT, longitude=LOCATION_LONG)%>% 
  select(latitude, longitude) %>% 
  distinct(latitude, longitude) %>% 
  mutate(dataset = 'flux_data') %>% 
  mutate(type = 'Terrestrial')
geo_flux <- st_as_sf(df_terrestrial, coords = c("longitude", "latitude"), crs = 4326)
st_write(geo_flux, 'geospatial/georeferenced_flux_2015_dataset.shp')
# Lakes and Terrestrial -------------------------------------------------
df_lakes_flux <- rbind(df_terrestrial, df_combined_lakes)
geo_lakes_flux <- st_as_sf(df_lakes_flux, coords = c("longitude", "latitude"), crs = 4326)
st_write(geo_lakes_flux, 'geospatial/georeferenced_doc_lakes_williamson_holgerson_flux.shp')
geo_lakes_flux <- st_read('geospatial/georeferenced_doc_lakes_williamson_holgerson_flux.shp')

# Stream pulse ------------------------------------------------------------
df_stream_pulse <- stream_pulse_sites %>% 
  select(latitude, longitude) %>% 
  distinct(latitude, longitude) %>% 
  mutate(dataset = 'stream_pulse') %>% 
  mutate(type = 'Streams') %>% 
  filter(!is.na(latitude))

geo_stream <- st_as_sf(df_stream_pulse, coords = c("longitude", "latitude"), crs = 4326)
# I should have named these "df's" to geo, sort of confusing since they do not contain data only points
df_lakes_flux_stream <- rbind(geo_lakes_flux, geo_stream) 
st_write(df_lakes_flux_stream, 'geospatial/georeferenced_doc_lakes_williamson_holgerson_flux_stream_pulse.shp')
df_lakes_flux_stream <- st_read('geospatial/georeferenced_doc_lakes_williamson_holgerson_flux_stream_pulse.shp')

# Combined with Marzolf ---------------------------------------------------
geo_lakes_flux_stream_marzolf <- rbind(df_lakes_flux_stream, shp_marzolf_locations_only)
st_write(geo_lakes_flux_stream_marzolf, 'geospatial/geo_lakes_flux_stream_pulse_marzolf.shp')


# Holgerson, Stream pulse, Flux, Marzolf ----------------------------------
metabolism_lakes_streams_terrestrial <- rbind(df_holgerson, df_stream_pulse, df_terrestrial, df_marzolf_locations_only)
geo_metabolism_lakes_streams_terrestrial <- st_as_sf(metabolism_lakes_streams_terrestrial, coords = c("longitude", "latitude"), crs = 4326)
st_write(geo_metabolism_lakes_streams_terrestrial, 'geospatial/geo_metabolism_lakes_streams_terrestrial.shp')

# Maps --------------------------------------------------------------------
library(rnaturalearth)
world <- ne_countries(scale = "medium", returnclass = "sf") # World basemap

# Lakes data, stream pulse, holgerson, Marzolf
ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") + 
  geom_sf(data = geo_lakes_flux_stream_marzolf, aes(color = dataset), size = 0.5) + 
  labs(title = "Lakes data, stream pulse, holgerson, Marzolf",
       x = "Longitude",
       y = "Latitude")

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
  geom_sf(data = world, fill = "lightgray", color = "white") + 
  geom_sf(data = geo_flux, aes(color = dataset)) + 
  theme_minimal() +
  labs(title = "Flux Sites",
       x = "Longitude",
       y = "Latitude")

# Lakes and Flux
ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") + 
  geom_sf(data = df_lakes_flux_stream, aes(color = dataset)) + 
  theme_minimal() +
  labs(title = "DOC Lake Data and Flux 2015 dataset",
       x = "Longitude",
       y = "Latitude")

# Lakes and Flux and Streams
ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white") + 
  geom_sf(data = df_lakes_flux_stream, aes(color = dataset), size = 0.5) + 
  labs(title = "DOC Lake Data and Flux 2015 dataset and Stream Pulse",
       x = "Longitude",
       y = "Latitude")


# Metabolism --------------------------------------------------------------
# Does not include Williamsons data
geo_metabolism_lakes_streams_terrestrial$type <- factor(geo_metabolism_lakes_streams_terrestrial$type,levels = c('Streams', 'Lakes', 'Terrestrial'))
c_palette <- c("#0072B2",  "#CC79A7", "#009E73")
ggplot() +
  geom_sf(data = world, fill = "white", color = "black") + 
  geom_sf(data = geo_metabolism_lakes_streams_terrestrial, aes(color = type), 
          size = 0.75) + 
  scale_color_manual(values = c_palette) + 
  labs(x = "Longitude",
       y = "Latitude")+
  theme_minimal()+
  theme(axis.text = element_text(size=18),
        legend.text = element_text(size = 12),
        legend.title = element_blank())

