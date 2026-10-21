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
  dplyr::select(fullcode, tract, block, place)|>
  rename(geoid_full=fullcode)
  #renamed fullcode to geoid_full to match naming conventions for using tidycensus

#Importing SD County census block data
sd_blocks_raw <- st_read(here("Census_data/raw_data/SD_Census_Blocks_2020_shapefile", 
                                     "Census_Blocks_2020.shp"))
str(sd_blocks_raw)
str(f_blocks)

#this SD county data doesn't have handy one to one geoid data like Riverside County, can I do a join
#that keeps only the rows that meet both the tract and block values of my f_blocks dataset?
#seems like yes...

#making changes to code to make it usable w/ tidycensus
#removing the period from tract, we need a string of numbers to use to make our geoid
f_blocks$fullcode <- gsub("\\.", "", f_blocks$fullcode)

#have to add in a leading zero to make it match the tidycensus geoid column, 
#also need to rename to geoid_full



#want to add in 


#Filter joining the datasets

fallbrook_blocks_geom <- sd_blocks_raw |>
  semi_join(f_blocks, join_by(tract, block))

str(fallbrook_blocks_geom)

#saving our new fallbrook only census blocks data as a shape file

st_write(fallbrook_blocks_geom, here("Census_Data/raw_data/", 
                                    "fallbrook_blocks_geom.shp"))






