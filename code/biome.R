closeAllConnections() # closes all file connections (like PDFs, PNGs, CSVs)
rm(list = ls()) # Clear variables
cat("\014") # Clear console

# Objective ---------------------------------------------------------------
# Categorize datasets by biome


# Progress ----------------------------------------------------------------

# Libraries ---------------------------------------------------------------
setwd('~/flux/data/')
library('raster')
library(sf)
library(dplyr)
library(tidyr)
library(ggplot2)
source('~/flux/code/project_functions.R')


# Import data -------------------------------------------------------------
land_cover <- raster('geospatial/LCType_1d.tif')
# I think making this into polygons might be a better approach.
# all_sites <- st_read('geospatial/georeferenced_doc_lakes_williamson_holgerson_flux_stream_pulse.shp')
all_sites <- st_read('geospatial/geo_lakes_flux_stream_pulse_marzolf.shp')


# Process -----------------------------------------------------------------
# Merging might be okay but I'm going to leave it for now
land_cover_polygons <- rasterToPolygons(land_cover, dissolve = F) # Set dissolve=TRUE to merge adjacent cells with the same value
land_cover_polygons <- st_as_sf(land_cover_polygons)
all_sites <- st_set_crs(all_sites, 4326)
all_sites <- st_make_valid(all_sites)
land_cover_polygons <- st_set_crs(land_cover_polygons, 4326)
land_cover_polygons <- st_make_valid(land_cover_polygons)
land_cover_polygons <- land_cover_polygons %>% 
  rename(biome = LCType_1d) 

sites_with_biome <- st_join(all_sites, land_cover_polygons, join = st_within)

summary_df <- sites_with_biome %>%
  group_by(biome, dataset) %>%
  summarise(number_of_sites = n(), .groups = 'drop')
summary_df <- st_make_valid(summary_df)
# st_write(summary_df, 'geospatial/sites_by_biomes.shp') 
st_write(summary_df, 'geospatial/sites_by_biomes_with_marzolf.shp') 

# Biome labels
land_cover_types <- c(
  "0" = "Water",
  "1" = "Evergreen Needle leaf Forest",
  "2" = "Evergreen Broadleaf Forest",
  "3" = "Deciduous Needle leaf Forest",
  "4" = "Deciduous Broadleaf Forest",
  "5" = "Mixed Forests",
  "6" = "Closed Shrublands",
  "7" = "Open Shrublands",
  "8" = "Woody Savannas",
  "9" = "Savannas",
  "10" = "Grasslands",
  "11" = "Permanent Wetland",
  "12" = "Croplands",
  "13" = "Urban and Built-Up",
  "14" = "Cropland/Natural Vegetation Mosaic",
  "15" = "Snow and Ice",
  "16" = "Barren or Sparsely Vegetated")
df <- summary_df
df <- df %>%
  mutate(land_cover_type = land_cover_types[as.character(biome)])

st_write(df, 'geospatial/sites_by_biomes_with_marzolf_with_biome_label.shp')
