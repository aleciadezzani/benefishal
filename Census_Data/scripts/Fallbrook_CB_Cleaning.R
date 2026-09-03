# Fallbrook Census Block Data Cleaning
# Author: E MacLean
# Created: Sep 3, 2026
# Modified: None
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

