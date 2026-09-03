# Temecula Census Block Shapefile Cleaning
# Author: E MacLean
# Created: Sep 3, 2026
# Modified: None
################

#Clear the enviro
rm(list=ls())

#Load libraries
library(here) #allows pointed file structure, essential for Mac to PC coding
library(tidyverse) #essential for everything we're going to do
library(janitor) #cleans things up, mainly names

#Import the data
#raw data is directly from US Census Bureau, access here: https://www2.census.gov/geo/maps/DC2020/DC20BLK/st06_ca/place/p0678120_temecula/
t_blocks_raw <- read.table(here("Census_Data/raw_data", "temecula_blocks.txt"), 
                            header = TRUE, sep = ";")
t_blocks_raw

#Save the data
