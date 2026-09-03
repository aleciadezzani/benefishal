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

#Loading the data
t_blocks <- read.table(here("Census_Data/raw_data", "temecula_blocks.txt"), 
                            header = TRUE, sep = ";")
t_blocks
