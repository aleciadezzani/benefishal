# Temecula Census Block Shapefile Cleaning
# Author: E MacLean
# Created: Sep 3, 2026
# Modified: October 21, 2026
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
t_blocks_raw <- read.table(here("Census_Data/raw_data", "t_blocks_raw.txt"), 
                            header = TRUE, sep = ";")
t_blocks_raw

#Importing Riverside County Census Blocks data

riverside_blocks_raw <- st_read(here("Census_data/raw_data/Riverside_Census_Blocks_2020_", 
                                        "Census_Blocks_2020_.shp"))
riverside_blocks_raw

#Clean the t_blocks data
#start with removing irrelevant data, cut down to only fullcode, tract, block, place
#and rename fullcode to geoid to match riverside_blocks data

t_blocks <- t_blocks_raw |>
  clean_names() |>
  dplyr::select(fullcode, tract, block) |>
  rename(geoid=fullcode)

#also have to pull the decimal point out of the geoid values, 
#as riverside_blocks has no decimal

t_blocks$geoid <- gsub("\\.", "", t_blocks$geoid)

#adding a leading zero to geoid_full so that it's usable w/ tidycensus
t_blocks <- t_blocks |>
  mutate(geoid = paste0("0", geoid))

#adding a block_group column
t_blocks <- t_blocks |>
  mutate(block_group = block %/% 1000)

str(t_blocks)

###
#pulling population data from tidycensus to add to t_blocks
library(tidycensus)

#pulling 2025 pop data by block for temecula

block_pop <- get_decennial(
  geography = "block",
  variables = "P1_001N",
  state = "CA",
  county = "Riverside",
  year = 2020,
  sumfile = "pl")

str(block_pop)

block_pop <- block_pop |>
  clean_names() |>
  dplyr::select(geoid, name, value) |>
  rename(population = value)

###
#combining t_blocks w/ block_pop to get a blocklist w/ population in it
t_blocks <- t_blocks |>
  inner_join(block_pop, join_by(geoid))

t_blocks <- t_blocks |>
  relocate(name, .after = geoid) |>
  relocate(block, .after = name) |>
  relocate(block_group, .after = block)


#confirming that geoid, tract, block, and place are formats of variables
#that match in riverside_blocks
#currently, tract is a num in t_blocks and an integer in riverside_blocks
#don't think this should be an issue but noting here just in case

#Clean riverside_blocks data
riverside_blocks <- riverside_blocks_raw |>
  clean_names() |>
  dplyr::select(geoid, shapest_are, shapest_len, geometry) |>
  rename(shape_area = shapest_are, shape_length = shapest_len)

str(riverside_blocks)

###
#Adding geometry to t_blocks dataframe

temecula_blocks_geom <- t_blocks |>
  inner_join(riverside_blocks, join_by(geoid==geoid))

#saving our new temecula only census blocks data as a shape file

st_write(temecula_blocks_geom, here("Census_Data/Temecula_2020_Census_Blocks_Geom/", 
                                    "temecula_blocks_geom.shp"))
