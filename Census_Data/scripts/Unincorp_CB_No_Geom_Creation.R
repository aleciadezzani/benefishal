#Unincorporated Census Blocks Data, No Geometry
# Author: E MacLean
# Created: Sep 8, 20226
# Modified: Sep 9, 2026
#####################
#Script Purpose
# This script is intended to create a single dataset of the census blocks in our unincorporated
#area of interest. This dataset will not have mapping geometries attached, as it's for use with
#the tidycensus package, which can pull relevant geometric data as needed. The idea is to create
#an easy to use list of all relevant census blocks with matching variables regardless of county

#clear enviro
rm(list=ls())

#load relevant libraries
library(here) #allows pointed file structure, essential for Mac to PC coding
library(tidyverse) #essential for everything we're going to do
library(janitor) #cleans things up, mainly names
library(sf)

#load our datasets, created in Unincorp_CB_Geom_Creation.R
unincorp_sd_blocks_raw <-st_read(here("Census_Data/Unincorporated_Riverside_SD_2020_Census_Blocks/", 
                  "unincorp_sd_blocks.shp"))
unincorp_riverside_blocks_raw <- st_read(here("Census_Data/Unincorporated_Riverside_SD_2020_Census_Blocks/", 
                                                      "unincorp_riverside_blocks.shp"))
view(unincorp_sd_blocks_raw)
str(unincorp_sd_blocks_raw)
  #we have seven variables, of which we really only need tract (num) and block (int)
  #we want to add in a geoid variable, which should have a leading zero to match tidycensus ACS data

view(unincorp_riverside_blocks_raw)
str(unincorp_riverside_blocks_raw)
  #we have 16 variables, of which we really only need geoid (chr), tract (int), block (int),
  #and blkgrp (int)
  #we need to add a leading zero to geoid to get it to match
  #because ACS operates at block group level, the geoid's it generates won't match the distinct geoid's we have
  #per census block. to get to matching exactly, consider making the blkgrp value not a single value like exists
  #in this dataset, but the full geoid associated with the block group?
    #ex: the geoid for block 3030 in tract 49702 is "60650497023030"
    #the geoid for block group 3 in tract 49702 is "60650497023", or the same thing minus the final three digits
    #adding the block group geoid into this dataset would allow for seamless data integration with ACS

#Editing Riverside data
#removing geometry
no_geom_riverside_blocks <- st_drop_geometry(unincorp_riverside_blocks_raw)

riverside_blocks <- no_geom_riverside_blocks |>
  select(geoid, tract, block, blkgrp)

#Editing SD data
#removing geometry
no_geom_sd_blocks <- st_drop_geometry(unincorp_sd_blocks_raw)

sd_blocks <- no_geom_sd_blocks |>
  select(tract, block)
#removing the period from tract, we need a string of numbers to use to make our geoid
sd_blocks$tract <- gsub("\\.", "", sd_blocks$tract)
#adding a full geoid column. want to call it geoid_full, to differentiate it from geoid_blkgrp
sd_blocks <- sd_blocks |>
  mutate(geoid_full = paste0("060650", tract, block))
#adding the geoid_blkgrp

######this script has been saved to my computer but not synced to github yet! do that tmrw?
