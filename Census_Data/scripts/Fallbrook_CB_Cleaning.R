# Fallbrook Census Block Data Cleaning
# Author: E MacLean
# Created: Sep 3, 2026
# Modified: October 21, 2026
##############################
#Clear the enviro
rm(list=ls())

#load libraries
library(here) #allows pointed file structure, essential for Mac to PC coding
library(tidyverse) #essential for everything we're going to do
library(janitor) #cleans things up, mainly names
library(sf) #we need to deal with shapefile data
  #didn't acutally need that raster file before!

#Importing Fallbrook block list as a dataframe
#raw data is directly from US Census Bureau, access here: https://www2.census.gov/geo/maps/DC2020/DC20BLK/st06_ca/place/p0623462_fallbrook/DC20BLK_P0623462_BLK2MS.txt
#first use R to make a text file, and paste the data directly into it, called it "f_blocks_list_raw.txt" and saved it to raw_data folder
f_blocks_raw <- read.table(here("Census_Data/raw_data", "f_blocks_list_raw.txt"), 
                           header = TRUE, sep = ";")
str(f_blocks_raw)

#Cleaning the f_blocks data
#start with removing irrelevant data, cut down to only fullcode, tract, block, place
f_blocks <- f_blocks_raw |>
  clean_names() |>
  dplyr::select(fullcode, tract, block)|>
  rename(geoid=fullcode)
  #renamed fullcode to geoid_full to match naming conventions for using tidycensus

#removing the period from tract, we need a string of numbers to use to make our geoid
f_blocks$geoid <- gsub("\\.", "", f_blocks$geoid)

#adding a leading zero to geoid so that it's usable w/ tidycensus
f_blocks <- f_blocks |>
  mutate(geoid = paste0("0", geoid))

#adding a block_group column
f_blocks <- f_blocks |>
  mutate(block_group = block %/% 1000) |>
  relocate(block_group, .before = block)

###
#need to add in population data to this now!
#use tidycensus for that
library(tidycensus)
vars_decennial <- load_variables(2020, "pl")
view(vars_decennial)

#pulling 2025 pop data by block for fallbrook...

block_pop <- get_decennial(
  geography = "block",
  variables = "P1_001N",
  state = "CA",
  county = "San Diego",
  year = 2020,
  sumfile = "pl")

str(block_pop)

block_pop <- block_pop |>
  clean_names() |>
  dplyr::select(geoid, name, value) |>
  rename(population = value)

###
#combining f_blocks w/ block_pop to get a blocklist w/ population in it
f_blocks <- f_blocks |>
  inner_join(block_pop, join_by(geoid))

f_blocks <- f_blocks |>
  relocate(name, .after = geoid) |>
  relocate(block, .after = name) |>
  relocate(block_group, .after = block)


#add in shapefile data only after making sure that I have population, and block group columns in f_blocks dataframe
#Importing SD County census block data
sd_blocks_raw <- st_read(here("Census_data/raw_data/SD_Census_Blocks_2020_shapefile", 
                                     "Census_Blocks_2020.shp"))
str(sd_blocks_raw)
str(f_blocks)

#this SD county data doesn't have handy one to one geoid data like Riverside County, can I do a join
#that keeps only the rows that meet both the tract and block values of my f_blocks dataset?
#seems like yes...
#Filter joining the datasets

fallbrook_blocks_geom <- f_blocks |>
  inner_join(sd_blocks_raw, join_by(tract, block)) |>
  dplyr::select(-objectid, -globalid)

#saving our new fallbrook only census blocks data as a shape file

st_write(fallbrook_blocks_geom, here("Census_Data/Fallbrook_2020_Census_Blocks_Geom/", 
                                    "fallbrook_blocks_geom.shp"))






