#Census Data Test Pull
# Author: E MacLean
# Created: Sep 8, 2026
# Modified: None
######################
#Learning to use the tidycensus package to pull results from the American Community Survey (ACS)!

#Clear the enviro
rm(list=ls())

#install packages
install.packages("tidycensus")

#load libraries
library(here)
library(tidyverse)
library(tidycensus)
library(janitor)
library(sf)

#getting an API to access ACS data
census_api_key("ffc02f1479739003d35f48bc2902b2a7be14b154", install = TRUE)
#run below code to get R to recognize this as my API
readRenviron("~/.Renviron")

#searching for variables w/in ACS, use code below to create a searchable table of all ACS variables
vars<- load_variables(2023, "acs1", cache = TRUE)
view(vars)
vars_decennial <- load_variables(2010, "pl")
view(vars_decennial)

#testing w/ home value
median_home_value_county <- get_acs(
  geography = "county",
  state = "CA",
  year = 2023,
  survey = "acs1",
  variables = "B25077_001")

#testing to block group level
#can't do anything smaller than block group for ACS
median_income <- get_acs(
  geography = "block_group",
  variables = "B19013_001",
  state = "CA",
  county = "Riverside",
  year = 2023,
  geometry = TRUE)
  #this dataset has geoid, which matches my riverside data, but my sd data doesn't have geoid...
  #the block group geoid is all but the final three values of the geoid from my riverside block group datasets
  #so theoretically I can filter this median_income dataset for just the block groups in my relevant tracts...
unincorp_riverside_median_income <- median_income |>
  filter(GEOID %in% c("060650497023", "060650512001", "060650512003" ))
  #this worked, but I had to manually add a leading zero back into my unincorp_riverside geocode values,
  #and I manually chose the relevant geoid's based on my familiarity with the unincorp_riverside
  #dataset. This manual selection also means I didn't include the block groups for which only a block or two
  #show up in our selection of census blocks relevant to our work
  #this data is correct, and we can use it get means/medians! but it's not tidy... 

#load my riverside county relevant tracts & blocks for comparison to my median_income dataset
unincorp_riverside_geom <- st_read(here("Census_data/Unincorporated_Riverside_SD_2020_Census_Blocks", 
                              "unincorp_riverside_blocks.shp"))
#blockgroup geoid's match the all but the final three values for the geoid's in my unincorporated
#Riverside county dataset











