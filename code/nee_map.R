closeAllConnections() # closes all file connections (like PDFs, PNGs, CSVs)
rm(list = ls()) # Clear variables
cat("\014") # Clear console

# Objective ---------------------------------------------------------------
# Synthesize NEE data

# Progress ----------------------------------------------------------------
# Just did mean NEE over all years, next up monthly then mean annual
# Libraries ---------------------------------------------------------------
setwd('~/flux/data/')
library(raster)
library(ggplot2)
source('~/flux/code/project_functions.R')

# Import data -------------------------------------------------------------
nee_inversion <- stack('~/flux/data/terrestrial/inversion_ensemble_NEE_monthly_mean_1976_2017.tif')
crs(nee_inversion)
res(nee_inversion)
summary(nee_inversion$inversion_ensemble_NEE_monthly_mean_1976_2017_1)
plot(nee_inversion$inversion_ensemble_NEE_monthly_mean_1976_2017_1)

# I think NA values are just 0
NAvalue(nee_inversion) <- 0
summary(nee_inversion$inversion_ensemble_NEE_monthly_mean_1976_2017_1)
plot(nee_inversion$inversion_ensemble_NEE_monthly_mean_1976_2017_1)

nee_inversion_mean <- calc(nee_inversion, fun = mean, na.rm = TRUE)
plot(nee_inversion_mean)
summary(nee_inversion_mean)



# Figures -----------------------------------------------------------------
# 9 categories, maybe not the best spacing
breaks <- c(-0.213, -0.1, -0.05, -0.01, 0, 0.01, 0.05, 0.1, 0.2, 0.291)

# Reclassify raster into 9 categories
nee_categorized <- cut(nee_inversion_mean[], breaks = breaks, labels = FALSE)

# Create a new raster with the categorized values
nee_categorized_raster <- raster(nee_inversion_mean)
nee_categorized_raster[] <- nee_categorized

# Data frame for ggplot
nee_df <- as.data.frame(nee_categorized_raster, xy = TRUE, na.rm = TRUE)

#  blue for negative (uptake), grey for near zero, red for positive
custom_colors <- c("#313695", "#4575b4", "#74add1", "#abd9e9", 
                   "#f0f0f0", 
                   "#fdae61", "#f46d43", "#d73027", "#a50026")

# Figure with country outlines
p <- ggplot() +
  geom_raster(data = nee_df, aes(x = x, y = y, fill = as.factor(layer))) +
  scale_fill_manual(values = custom_colors, name = NULL, 
                    labels = c("-0.213 to -0.1", 
                               "-0.1 to -0.05", 
                               "-0.05 to -0.01", 
                               "-0.01 to 0", 
                               "0", 
                               "0 to 0.01", 
                               "0.01 to 0.05", 
                               "0.05 to 0.1", 
                               "0.1 to 0.291")) +
  scale_x_continuous(breaks = seq(-180, 180, by = 30)) +  
  scale_y_continuous(breaks = seq(-90, 90, by = 15)) +  
  coord_fixed() +
  borders("world", colour = "black", size = 0.3) +  # Add country borders
  theme_minimal() +
  labs(title = "Mean NEE (1986-2017) inversion dataset",
       x = "Longitude", y = "Latitude")
p


# Summed ------------------------------------------------------------------
NAvalue(nee_inversion) <- 0
nee_inversion_sum <- calc(nee_inversion, fun = sum, na.rm = TRUE)
writeRaster(nee_inversion_sum, 'terrestrial/nee_inversion_sum.tif')
