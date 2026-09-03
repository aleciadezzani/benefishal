# Temecula Census Block Shapefile Cleaning
# Author: E MacLean
# Created: Sep 3, 2026
# Modified: None
################

#Clear the enviro
rm(list=ls())

#install packages
install.packages("raster")

#Load libraries
library(here) #allows pointed file structure, essential for Mac to PC coding
library(tidyverse) #essential for everything we're going to do
library(janitor) #cleans things up, mainly names
library(sf) #we need to deal with shapefile data
library(raster) #we need to deal with metadata/attributes of raster/polygon data

#Importing the Temecula census blocks list data
#raw data is directly from US Census Bureau, access here: https://www2.census.gov/geo/maps/DC2020/DC20BLK/st06_ca/place/p0678120_temecula/
t_blocks_raw <- read.table(here("Census_Data/raw_data", "temecula_blocks.txt"), 
                            header = TRUE, sep = ";")
t_blocks_raw

#Save the data
write.csv(t_blocks_raw, here("Census_data/raw_data", "temecula_blocks_raw"))

#Importing Riverside County Census Blocks data

riverside_blocks_raw <- st_read(here("Census_data/raw_data/Riverside_Census_Blocks_2020_", 
                                        "Census_Blocks_2020_.shp"))
riverside_blocks_raw

#Saving the data
write.csv(riverside_blocks_raw, here("Census_data/raw_data", "riverside_blocks_raw"))

#Clean the t_blocks data
#start with removing irrelevant data, cut down to only fullcode, tract, block, place
#and rename fullcode to geoid to match riverside_blocks data

t_blocks <- t_blocks_raw |>
  clean_names() |>
  dplyr::select(fullcode, tract, block, place) |>
  rename(geoid=fullcode)
t_blocks

#also have to pull the decimal point out of the geoid values, 
#as riverside_blocks has no decimal

t_blocks$geoid <- gsub("\\.", "", t_blocks$geoid)



riverside_blocks <- riverside_blocks_raw |>
  clean_names()


##The t_blocks data has the GEOID as "fullcode", and listed with a decimal point
##I want to figure out how to remove that decimal point so that 
##I can match it to the GEOID column in my Riverside County full blocks dataset











