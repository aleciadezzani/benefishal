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




#Riverside County
#add Riverside County census block shapefile
riverside_blocks_raw <- st_read(here("Census_data/raw_data/Riverside_Census_Blocks_2020_", 
                                     "Census_Blocks_2020_.shp"))
riverside_blocks_raw
str(riverside_blocks_raw)

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

#add Temecula block list
t_blocks_raw <- read.table(here("Census_Data/raw_data", "t_blocks_raw.txt"), 
                           header = TRUE, sep = ";")
t_blocks_raw

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

#Now for SD County 

#add San Diego County census block shapefile
sd_blocks_raw <- st_read(here("Census_data/raw_data/SD_Census_Blocks_2020_shapefile", 
                              "Census_Blocks_2020.shp"))
str(sd_blocks_raw)

#Cleaning Fallbrook list for just blocks in the 190.01 tract
f_blocks <- f_blocks_raw |>
  clean_names() |>
  dplyr::select(fullcode, tract, block, place) |>
  filter(tract == "190.01")

#filtering for only sd county blocks in 190.01 tract
sd_blocks <- sd_blocks_raw |>
  clean_names() |>
  filter(tract == "190.01")


#joining the datasets together to get only the census blocks in 190.01 that are not
#within the CDP of Fallbrook

unincorp_sd_blocks <- sd_blocks |> 
  anti_join(f_blocks, join_by(tract, block))

#I don't think I can join the two different shapefiles together unfortunately
#But I think I can zip the outputs together and then upload them into Arc in one version...

#Saving new shapefiles for our unincorporated census blocks in Riverside and SD counties

st_write(unincorp_sd_blocks, here("Census_Data/Unincorporated_Riverside_SD_2020_Census_Blocks/", 
                                     "unincorp_sd_blocks.shp"))
st_write(unincorp_riverside_blocks, here("Census_Data/Unincorporated_Riverside_SD_2020_Census_Blocks/", 
                                         "unincorp_riverside_blocks.shp"))















