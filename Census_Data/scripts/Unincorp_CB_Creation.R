# Unincorporated Census Blocks Shape File Creation
# Author: E MacLean
# Created: September 9, 2026
# Modified: N/A
##################
#Goal of this script is to create a shapefile that includes the census blocks relevant to
#our study area that are not within Fallbrook or Temecula. This will mean combining the shapefiles
#from San Diego and Riverside counties and then removing all non-relevant census tracts
#In Riverside county the relevant tracts are 51200 (all except Temecula labeled blocks), 
#49702 (all except Murrieta labeled blocks), and 43254 (all except Temecula labeled blocks).
#In SD county, its all blocks within 190.01. 
#Reference maps used to define relevant blocks came from Census Bureau and are accessible in
#Week 10 of Ellie Summer Notes within Benefishal Google Drive. 

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

#Murrieta blocks cleaning
m_blocks <- m_blocks_raw |>
  clean_names() |>
  dplyr::select(fullcode, tract, block,place)
#also have to pull the decimal point out of the fullcode values, as riverside_blocks has no decimal
m_blocks$fullcode <- gsub("\\.", "", m_blocks$fullcode)
#do the same for tracts
m_blocks$tract <- gsub("\\.", "", m_blocks$tract)
#adding two trailing zeros to the 512 tract values to match riverside_blocks tract values
m_blocks$tract <- gsub("^512$", "51200", m_blocks$tract)
#pulling block list for tracts 49702 and 512
m_blocks <- m_blocks |>
  filter(tract %in% c("49702", "51200"))

#Temecula blocks cleaning
t_blocks <- t_blocks_raw |>
  clean_names() |>
  dplyr::select(fullcode, tract, block, place)
#removing decimals from fullcode/geoid and tract values
t_blocks$fullcode <- gsub("\\.", "", t_blocks$fullcode)
t_blocks$tract <- gsub("\\.", "", t_blocks$tract)
#adding two trailing zeros to the 512 tract values to match riverside_blocks tract values
t_blocks$tract <- gsub("^512$", "51200", t_blocks$tract)
#filtering to just block list for tracts 512 and 43254
t_blocks <- t_blocks |>
  filter(tract %in% c("51200", "43254"))
  
#Joining Temecula and Murrieta block lists into one set of incorporated blocks
tm_blocks <- bind_rows(t_blocks, m_blocks)

#Keeping Riverside blocks excluding those from tm_blocks 
  #there are irrelevant blocks in 43254 from the riverside_blocks list, 
  #found after uploading into ArcGIS. Remove blocks 1017, 1009, 1010, 1011,
  #2004, 1012, 2015, 2005, 2006, 2010, 2007, 2008, 2014, 2013.
unincorp_riverside_blocks <- riverside_blocks |>
  anti_join(tm_blocks, join_by(geoid == fullcode)) |>
  filter(!(tract == "43254" & block %in% c(1017, 1009, 1010, 1011, 2004,
                                           1012, 2015, 2005, 2006, 2010, 
                                           2007, 2008, 2014, 2013)))

str(unincorp_riverside_blocks)

#Now for SD County filtering
unincorp_sd_blocks <- sd_blocks_raw |>
  clean_names() |>
  filter(tract == "190.01")

#I don't think I can join the two different shapefiles together unfortunately
#But I think I can zip the outputs together and then upload them into Arc in one version...

#Saving new shapefiles for our unincorporated census blocks in Riverside and SD counties

st_write(unincorp_sd_blocks, here("Census_Data/Unincorporated_Riverside_SD_2020_Census_Blocks/", 
                                     "unincorp_sd_blocks.shp"))
st_write(unincorp_riverside_blocks, here("Census_Data/Unincorporated_Riverside_SD_2020_Census_Blocks/", 
                                         "unincorp_riverside_blocks.shp"))















