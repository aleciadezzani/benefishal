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

#getting an API to access ACS data
census_api_key("ffc02f1479739003d35f48bc2902b2a7be14b154", install = TRUE)















