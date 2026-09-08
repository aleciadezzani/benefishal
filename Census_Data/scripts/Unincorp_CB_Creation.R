# Unincorporated Census Blocks Shape File Creation
# Author: E MacLean
# Created: September 9, 2026
# Modified: N/A
##################
#Goal of this script is to create a shapefile that includes the census blocks relevant to
#our study area that are not within Fallbrook or Temecula. This will mean combining the shapefiles
#from San Diego and Riverside counties and then removing all non-relevant census tracts

#Clear the enviro
rm(list=ls())

#Load libraries
library(here) #allows pointed file structure, essential for Mac to PC coding
library(tidyverse) #essential for everything we're going to do
library(janitor) #cleans things up, mainly names
library(sf) #we need to deal with shapefile data

#Load the data
#add Murrieta block list
m_blocks_raw <- read.table(here("Census_Data/raw_data", "murrieta_blocklist_raw.txt"), 
                           header = TRUE, sep = ";")
m_blocks_raw

#add Temecula block list
t_blocks_raw <- read.table(here("Census_Data/raw_data", "t_blocks_raw.txt"), 
                           header = TRUE, sep = ";")
t_blocks_raw

#add Riverside County census block shapefile
riverside_blocks_raw <- st_read(here("Census_data/raw_data/Riverside_Census_Blocks_2020_", 
                                     "Census_Blocks_2020_.shp"))
riverside_blocks_raw
str(riverside_blocks_raw)

#add San Diego County census block shapefile
sd_blocks_raw <- st_read(here("Census_data/raw_data/SD_Census_Blocks_2020_shapefile", 
                              "Census_Blocks_2020.shp"))
str(sd_blocks_raw)

#Filtering the data
  ##start with Riverside, then do SD, then combine the shapefiles into one?
#Riverside County
  ##reference maps from Census Bureau indicate that tracts 512, 497.02, and 432.54
  ##are only relevant tracts for us. filter for those first within the shapefile
riverside_blocks <- riverside_blocks_raw |>
  clean_names()
#removing the leading zero from the geoid so that join works aka geoids match between datasets
riverside_blocks$geoid <- sub("^0+", "", riverside_blocks$geoid)
str(riverside_blocks)
#filtering for just our relevant tracts
riverside_blocks <- riverside_blocks |>
  filter(tract %in% c("51200", "49702", "43254"))







