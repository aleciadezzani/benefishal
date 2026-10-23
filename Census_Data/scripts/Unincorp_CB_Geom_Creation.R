# Unincorporated Census Blocks Shape File Creation
# Author: E MacLean
# Created: September 9, 2026
# Modified: October 22, 2026
##################
#Goal of this script is to create a shapefile that includes the census blocks relevant to
#our study area that are not within Fallbrook or Temecula. This will mean combining the shapefiles
#from San Diego and Riverside counties and then removing all non-relevant census tracts
#San Diego County tract map: https://www2.census.gov/geo/maps/DC2020/PL20/st06_ca/censustract_maps/c06073_san_diego/DC20CT_C06073.pdf
#Riverside County tract map: https://www2.census.gov/geo/maps/DC2020/PL20/st06_ca/censustract_maps/c06065_riverside/DC20CT_C06065.pdf
#10/22/26 note
  #in Riverside County want tracts 464.01, 432.72, 497.72, 512 (parts not already in Temec), and 432.54 (parts not already in Temec)
  #in SD County want tract 190.01

#Clear the enviro
rm(list=ls())

#Load libraries
library(here) #allows pointed file structure, essential for Mac to PC coding
library(tidyverse) #essential for everything we're going to do
library(janitor) #cleans things up, mainly names
library(sf) #we need to deal with shapefile data
library(tidycensus) #need to add pop data in

#load the data
#adding Fallbrook block list
f_blocks<- read_csv(here("Census_Data/clean_data", "f_blocks.csv"), 
                    col_types = cols(geoid = col_character()))
                    #have to add this otherwise R reads the geoid column as numbers, dropping leading zeros and adding a decimal point
str(f_blocks)

#adding all sd county block list
sd_blocks_raw <- read.table(here("Census_Data/raw_data", "sd_county_block_list.txt"), 
                            header = TRUE, sep = ";")

###

#clean the data
#there's an extra column in import f_blocks drop it
f_blocks <- f_blocks |>
  dplyr::select(geoid, name, block, block_group, tract, population)

#Cut down sd_blocks to only fullcode, tract, block, place, rename fullcode to geoid
sd_blocks <- sd_blocks_raw |>
  clean_names() |>
  dplyr::select(fullcode, tract, block)|>
  rename(geoid=fullcode)

#removing the period from tract, we need a string of numbers to use to make our geoid
sd_blocks$geoid <- gsub("\\.", "", sd_blocks$geoid)

#adding a leading zero to geoid so that it's usable w/ tidycensus
sd_blocks <- sd_blocks |>
  mutate(geoid = paste0("0", geoid))

#adding a block_group column
sd_blocks <- sd_blocks |>
  mutate(block_group = block %/% 1000) |>
  relocate(block_group, .before = block)

#filtering for just our relevant tract, 190.01
sd_blocks <- sd_blocks |>
  filter(tract == "190.01")

###
#adding census population data to those blocks

#make dataframe w/population for sd county blocks
block_pop <- get_decennial(
  geography = "block",
  variables = "P1_001N",
  state = "CA",
  county = "San Diego",
  year = 2020,
  sumfile = "pl")
#dropping irrelevant columns, renaming population column
block_pop <- block_pop |>
  clean_names() |>
  dplyr::select(geoid, name, value) |>
  rename(population = value)

#combining sd_blocks w/ block_pop to get sd_blocks w/ population column
sd_blocks <- sd_blocks |>
  inner_join(block_pop, join_by(geoid))

sd_blocks <- sd_blocks |>
  relocate(name, .after = geoid) |>
  relocate(block, .after = name) |>
  relocate(block_group, .after = block)

#removing fallbrook blocks from sd_blocks, to get  blocks in 190.01 not in fallbrook
sd_blocks <- sd_blocks |>
  anti_join(f_blocks, join_by(geoid))

###
#saving just the sd_blocks csv, no geometry
write.csv(sd_blocks, here("Census_Data/clean_data", 
                         "sd_blocks.csv"), row.names = FALSE)

###
#adding geometry to sd_blocks

#add San Diego County census block shapefile
sd_geom_raw <- st_read(here("Census_data/raw_data/SD_Census_Blocks_2020_shapefile", 
                              "Census_Blocks_2020.shp"))
str(sd_geom_raw)

#combining the two
sd_blocks_geom <- sd_blocks |>
  inner_join(sd_geom_raw, join_by(tract, block)) |>
  dplyr::select(-objectid, -globalid)

###
#save new unincorporated san diego county blocks as a shape file 

st_write(sd_blocks_geom, here("Census_Data/Unincorporated_Riverside_SD_2020_Census_Blocks", 
                                     "sd_blocks.shp"))

#######
#Do it all again for Riverside County
#reset environment
rm(list=ls())

#loading data
#adding Temecula block list
t_blocks<- read_csv(here("Census_Data/clean_data", "t_blocks.csv"), 
                    col_types = cols(geoid = col_character()))
                    #have to add this otherwise R reads the geoid column as numbers, dropping leading zeros and adding a decimal point
str(t_blocks)

#adding all riverside county block list
riverside_blocks_raw <- read.table(here("Census_Data/raw_data", "riverside_blocks_raw.txt"), 
                            header = TRUE, sep = ";")
str(riverside_blocks_raw)

#adding riverside county shapefiles
riverside_geom_raw <- st_read(here("Census_data/raw_data/Riverside_Census_Blocks_2020_", 
                                     "Census_Blocks_2020_.shp"))
str(riverside_blocks_raw)

###
#clean the data
#clean riverside_geom_raw
riverside_geom <- riverside_geom_raw |>
  clean_names() |>
  dplyr::select(geoid, shapest_are, shapest_len, geometry) |>
  rename(shape_area = shapest_are, shape_length = shapest_len)

#Cut down riverside_blocks to only fullcode, tract, block, place, rename fullcode to geoid
riverside_blocks <- riverside_blocks_raw |>
  clean_names() |>
  dplyr::select(fullcode, tract, block)|>
  rename(geoid=fullcode)

#removing the period from geoid, we need a string of numbers to use to make our geoid
riverside_blocks$geoid <- gsub("\\.", "", riverside_blocks$geoid)

#adding a leading zero to geoid so that it's usable w/ tidycensus
riverside_blocks <- riverside_blocks |>
  mutate(geoid = paste0("0", geoid))

#adding a block_group column
riverside_blocks <- riverside_blocks |>
  mutate(block_group = block %/% 1000) |>
  relocate(block_group, .before = block)

#filtering for only our relevant tracts,
  # 464.01, 432.72, 497.02, 512, and 432.54
riverside_blocks <- riverside_blocks |>
  filter(tract %in% c(464.01, 432.72, 497.02, 512, 432.54))

###
#adding population data to riverside_blocks

#make dataframe w/population for riverside county blocks
block_pop <- get_decennial(
  geography = "block",
  variables = "P1_001N",
  state = "CA",
  county = "Riverside",
  year = 2020,
  sumfile = "pl")
#dropping irrelevant columns, renaming population column
block_pop <- block_pop |>
  clean_names() |>
  dplyr::select(geoid, name, value) |>
  rename(population = value)

#combining riverside_blocks w/ block_pop to get riverside_blocks w/ population column
riverside_blocks <- riverside_blocks |>
  inner_join(block_pop, join_by(geoid))

riverside_blocks <- riverside_blocks |>
  relocate(name, .after = geoid) |>
  relocate(block, .after = name) |>
  relocate(block_group, .after = block)

#removing temecula blocks from riverside_blocks, so no overlap in mapping
riverside_blocks <- riverside_blocks |>
  anti_join(t_blocks, join_by(geoid))

###
#saving just the riverside_blocks csv, no geometry
write.csv(riverside_blocks, here("Census_Data/clean_data", 
                          "riverside_blocks.csv"), row.names = FALSE)

###
#adding geometry to riverside_blocks

#combining riverside_blocks w/ riverside_geom
riverside_blocks_geom <- riverside_blocks |>
  inner_join(riverside_geom, join_by(geoid))

###
#cutting irrelevant blocks from tract 432.54, correction after uploading to Arc
#need to remove: 1017, 1009, 1010, 1011, 1012, 2004, 2015, 2005, 2006, 2010,
#               2008, 2007, 2014, 2013
riverside_blocks_geom <- riverside_blocks_geom |>
  filter(!(geoid %in% c("060650432541017", "060650432541009", "060650432541010", 
                        "060650432541011", "060650432541012", "060650432542004",
                        "060650432542015", "060650432542005", "060650432542006",
                        "060650432542010", "060650432542008", "060650432542007",
                        "060650432542014", "060650432542013")))


###
#save new unincorporated riverside county blocks as a shape file 

st_write(riverside_blocks_geom, here("Census_Data/Unincorporated_Riverside_SD_2020_Census_Blocks", 
                              "riverside_blocks.shp"))

















