library(sf)
library(dplyr)
library(stringr)
library(ggplot2)
library(raster)
library(sp)
library(plotbiomes)
library(dplyr)

# function to convert data to sf
to_sf <- function(df, lat = "lat", lon = "lon", crs = 4326) {
  st_as_sf(df, coords = c(lon, lat), crs = crs, remove = FALSE)
}
df1 <- read.csv("~/Downloads/mon_mergeflux.csv")
df2 <- read.csv("~/Downloads/streampulse_monthly_trimmed.csv")

df1$lon <- df1$Longitude..degrees.
df1$lat <- df1$Latitude..degrees.


gdf1 <- st_as_sf(df1, coords = c("Longitude..degrees.", "Latitude..degrees."), crs = 4326)
gdf2 <- st_as_sf(df2, coords = c("lon", "lat"), crs = 4326)

### whittaker plot
path <- system.file("extdata", "temp_pp.tif", package = "plotbiomes")
temp_pp <- raster::stack(path)
names(temp_pp) <- c("temperature", "precipitation")

extract_climate <- function(df, raster_stack) {
  df <- df[!duplicated(df[, c("lon", "lat")]),]
  
  # Convert to spatial object
  spdf <- sp::SpatialPointsDataFrame(
    coords = df[, c("lon", "lat")],
    data   = df,
    proj4string = CRS("+proj=longlat +datum=WGS84")
  )
  
  # Extract values from raster stack
  vals <- raster::extract(raster_stack, spdf, df = TRUE)
  
  # Combine extracted values with original df
  out <- bind_cols(df, vals[-1])  # remove ID column
  
  # Adjust scaling (WorldClim conventions)
  out <- out %>%
    mutate(
      temperature = temperature / 10,     # from 0.1°C to °C
      precipitation = precipitation / 10  # mm to cm
    )
  
  return(out)
}
df1_clim <- extract_climate(df1, temp_pp)
df2_clim <- extract_climate(df2, temp_pp)

df1_clim$dataset <- "Ameriflux sites"
df2_clim$dataset <- "Streampulse sites"

combined <- bind_rows(df1_clim, df2_clim)

plotbiomes::whittaker_base_plot() +
  geom_point(
    data = combined,
    aes(x = temperature, y = precipitation, color = dataset),
    size = 3,
    alpha = 0.4
  ) +
  scale_color_manual(values = c("Ameriflux sites" = "purple", 
                                "Streampulse sites" = "black")) + 
  theme_classic(base_size = 20)



# Bound your area of interest
bb <- st_bbox(gdf1)
# Optionally buffer slightly so you capture edges
bb_poly <- st_as_sfc(bb) %>% st_buffer(0.1)

sf_use_s2(FALSE)
# read huc2
wbd_huc8 <- st_read("~/Downloads/huc2_watersheds.geojson")
wbd_huc8 <- st_simplify(wbd_huc8, preserveTopology = FALSE, dTolerance = 0.05)

# spatial joining stuff
wbd_huc8 <- st_transform(wbd_huc8, st_crs(gdf1))
gdf1_huc <- st_join(gdf1, wbd_huc8, join = st_intersects)
gdf2_huc <- st_join(gdf2, wbd_huc8, join = st_intersects)
library(rnaturalearth)
us <- ne_states(country = "United States of America", returnclass = "sf")
conus <- us %>% 
  filter(!name %in% c("Alaska", "Hawaii", "Puerto Rico"))
conus_poly <- st_union(conus)
huc2 <- st_transform(wbd_huc8, st_crs(conus_poly))
wbd_huc8 <- st_intersection(wbd_huc8, conus_poly)



# parse timestamp in df1
gdf1_huc <- gdf1_huc %>%
  mutate(
    timestamp = as.character(TIMESTAMP),
    year = as.integer(str_sub(timestamp, 1, 4)),
    month = as.integer(str_sub(timestamp, 5, 6))
  )

# aggregate monthly by watershed
agg1 <- gdf1_huc %>%
  st_drop_geometry() %>%
  dplyr::group_by(HUC2 = huc2, month) %>%
  dplyr::summarise(across(where(is.numeric), mean, na.rm = TRUE), .groups = "drop")

agg2 <- gdf2_huc %>%
  st_drop_geometry() %>%
  dplyr::group_by(HUC2 = huc2, month) %>%
  dplyr::summarise(across(where(is.numeric), mean, na.rm = TRUE), .groups = "drop")

# Merge for comparison
comparison <- agg1 %>%
  left_join(agg2, by = c("HUC2", "month"), suffix = c("_df1", "_df2"))

#comparison <- comparison[comparison$ndays_GPP>50,]

wbd_huc8 <- wbd_huc8[wbd_huc8$huc2 %in% comparison$HUC2,]


ggplot(comparison) + 
  geom_point(aes(x = GPP_NT_VUT_REF_mean, y = ER_monthly_scaled)) + 
  stat_smooth(aes(x = GPP_NT_VUT_REF_mean, y = ER_monthly_scaled), method = "gam") + 
  facet_wrap(.~HUC2, scales = "free") + 
  theme_classic()

ggplot(comparison) + 
  geom_point(aes(x = GPP_NT_VUT_REF_mean, y = ER_monthly_scaled)) + 
  stat_smooth(aes(x = GPP_NT_VUT_REF_mean, y = ER_monthly_scaled), method = "lm") + 
  facet_wrap(.~month, scales = "free") + 
  theme_classic()

variables <- c("GPP_NT_VUT_REF_mean", "RECO_NT_VUT_REF_mean", "NEE_VUT_REF_mean",
               "GPP_monthly_scaled","ER_monthly_scaled", "NEP_monthly_scaled")
df <- comparison
# make aquatic ER positive
df$ER_monthly_scaled <- -1*df$ER_monthly_scaled

# define all net exchange values as GPP-ER - positive = auto, neg=hetero
df$NEE_VUT_REF_mean = df$GPP_NT_VUT_REF_mean-df$RECO_NT_VUT_REF_mean
df$NEP_monthly_scaled = df$GPP_monthly_scaled-df$ER_monthly_scaled

write.csv(df, "terrestrial_aquatic_metab_huc2.csv")