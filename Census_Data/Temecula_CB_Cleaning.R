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
t_blocks_raw <- read.table(here("Census_Data/raw_data", "t_blocks.txt"), 
                            header = TRUE, sep = ";")
t_blocks_raw

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

str(t_blocks)
#confirming that geoid, tract, block, and place are formats of variables
#that match in riverside_blocks
#currently, tract is a num in t_blocks and an integer in riverside_blocks
#don't think this should be an issue but noting here just in case

#Clean riverside_blocks data
#I'm hesitant to remove any columns as idk what I'll need for mapping
riverside_blocks <- riverside_blocks_raw |>
  clean_names()
#removing the leading zero from the geoid so that join works aka geoids match between datasets
riverside_blocks$geoid <- sub("^0+", "", riverside_blocks$geoid)
str(riverside_blocks)

#Checking keys before joining
#pretty sure geoid is the primary key in both datasets, but want to make sure
t_blocks |>
  count(geoid) |>
  filter(n >1)
  #pulled zero rows where n>1, indicating it is a key
t_blocks |>
  filter(is.na(geoid))
  #pulled zero rows with NA, indicating we don't have any rows missing a geoid

riverside_blocks |>
  count(geoid) |>
  filter(n > 1)
  #pulled zero rows where n>1, indicating that it's a key

riverside_blocks |>
  filter(is.na(geoid))
  #pulled zero, think this indicates we're not missing anything

#Now to use a filtering join (semi-join) to keep only the rows in riverside_blocks
#that have a match in t_blocks
#new data frame should be called temecula_blocks_geom, as it's all the blocks for Temecula
#within the existing shapefile data!

temecula_blocks_geom <- riverside_blocks |>
  semi_join(t_blocks, join_by(geoid==geoid))
  #this is giving me a data frame with no values, what's the issue?
  #leading zeros! the riverside_blocks data has a leading zero in the geoid...
  #need to go back in and use gsub again to cut that from the riverside_blocks dataset

#saving our new temecula only census blocks data as a shape file

st_write(temecula_blocks_geom, here("Census_Data/raw_data/", 
                                    "temecula_blocks_geom.shp"))
