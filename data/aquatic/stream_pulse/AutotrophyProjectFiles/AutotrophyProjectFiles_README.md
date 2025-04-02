# Autotrophy in Rivers dataset

This Project is to study rivers that are exceptions to the long-standing dogma in stream ecology that streams tend to be heterotrophic, respiring organic carbon that they receive from upstream ecosystems.  that includes metabolism estimates for 356 streams throughout the United States. 

Link to published paper: 
https://link.springer.com/article/10.1007/s10021-024-00933-w


**Contents**
  
1. [Data Sets](#data-sets-description)  
    - [Working Datasets](#working-datasets)  
    - [Supplemental Data (356 Rivers)](#data-356-rivers)  

<!-- Data Sets description -->
## Data Sets Description

1.  [USGS Powell Center Synthesis](https://www.sciencebase.gov/catalog/item/59eb9c0ae4b0026a55ffe389) - Oxygen data from 356 USGS sites with metabolism estimates based on StreamMetabolizer [(Appling et al 2018)](https://www.nature.com/articles/sdata2018292). 
2. [StreamPulse data release](https://figshare.com/articles/software/Code_and_RDS_data_for_Bernhardt_et_al_2022_PNAS_/19074140?backTo=/collections/Data_and_code_for_Bernhardt_et_al_2022_PNAS_/5812160) and associated publication [Bernhardt et al 2022](https://www.pnas.org/doi/abs/10.1073/pnas.2121976119). We follow the workflow in this paper for filtering the Powell Center Metabolism data and for gap-filling site years for annual synthesis. Data for watershed terrestrial NPP are from this data release.
3. National Hydrography Dataset [(NHDplusHR)](https://www.usgs.gov/national-hydrography/nhdplus-high-resolution) - Each site is paired to a location on a river network in this database in order to extract covariates and delineate watersheds. 
4. [StreamCat data](https://www.epa.gov/national-aquatic-resource-surveys/streamcat-dataset) - Land use and geologic characteristics summarized over the contributing watershed areas. 
5. [Global River Dissolved Oxygen Dataset](https://www.sciencebase.gov/catalog/item/606f60afd34ef99870188ee5) - includes covariates for landuse and watershed characteristics from Hydroatlas and NLCD.

<!-- Working data -->
### Working datasets
**1. across_sites_model_data.csv**  -  summary data from all site years with a minimum of 60% annual coverage with high quality days (see above). Summary metabolism values are calculated from gap-filled data using the workflow from [Bernhardt et al 2022](https://www.pnas.org/doi/abs/10.1073/pnas.2121976119). Watershed data from NHD and streamcat are also included; .  NB: K600 values not incuded; see "high_quality_daily_metabolism_with_SP_covariates.rds"  (Supplemental Data #1) for **daily** K600 values, would need to calculate summary values.
**2. StreamPulse_monthly_K.csv** - summary K600 data from all site years with a minimum of 60% annual coverage with high quality days (see above). Summary K600 values are the na-removed averages of each month's daily data. 


<!-- Supplemental Data (356 Rivers) -->
### Supplemental Data (356 Rivers)

**1. annual_summary_data.csv**  -  Annual summaries for all Powell Center Synthesis and StreamPulse sites; includes full site names, lat-long coords, and summaries of all NHD and StreamCat data.  Includes all sites used in 'across_sites_model_data.csv'.
**2. high_quality_daily_metabolism_with_SP_covariates.rds**  -  Daily metabolism estimates only for sites that meet the quality filtering requirements: 1) days with poor fits for GPP, ER, or K600 are removed, 2) site years with a high correlation between K600 and ER are removed. 3) site years with less than 60% coverage of high quality days were removed. Includes raw metabolism values, filtered values, and gap-filled values according to the Bernhardt 2022 workflow. 
**3. site_data.tsv**  -  Metadata for Powell Center and StreamPulse sites. 
**4. streamcat_variablelist_quickreference.csv**  -  Reference list for streamcat variable names (columns in across_sites_model_data.csv and watershed_summary_data.csv).  
**5. watershed_summary_data.csv**  -  NHD and StreamCat data summarized for all Powell Center Synthesis and StreamPulse sites.  Slightly different sites than in 'across_sites_model_data.csv'; this may be from an early stage of the analyses. 


