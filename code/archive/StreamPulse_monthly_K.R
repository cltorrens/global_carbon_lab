##### The purpose of this script is to get monthly K values from the Bernhardt 
#     "high_quality_daily_metabolism_with_SP_covariates.rds" dataset
#
# Author: Christa Torrens
# Date: 02 December 2024



# load packages
library(tidyverse) # includes dplyr, forcats, ggplot2, lubridate, purrr, readr, stringr, tibble, tidyr
library(here)

# load data
df <- readRDS(here("data/aquatic/stream_pulse/AutotrophyProjectFiles/Supplemental Data/high_quality_daily_metabolism_with_SP_covariates.rds"))

# Calculate the average monthly K values for each site
monthly_df <- df %>%
  mutate(month = month(date)) %>%  # Extract the month from the date column
  group_by(site_name, year, month) %>%  # Group by site_name, year, and month
  summarize(
    avg_K600 = mean(K600, na.rm = TRUE), 
    avg_K600.lower = mean(K600.lower, na.rm = TRUE),
    avg_K600.upper = mean(K600.upper, na.rm = TRUE),
    .groups = "drop"  # Drops the grouping after summarizing
  )


write.csv(monthly_df, here("data/aquatic/stream_pulse/AutotrophyProjectFiles/StreamPulse_monthly_K.csv"), row.names = FALSE)
