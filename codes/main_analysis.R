# 1. Load Libraries and set options --------------------------------------------

renv::activate()
renv::restore()

library(tidyverse)
library(rstudioapi)
library(jsonlite)
library(gridExtra)
library(lintr)
library(showtext)

# Set options
options(max.print = 200)

# 2. Load Functions -----------------------------------------------------------

# Obtain the paths
file_location <- dirname(rstudioapi::getActiveDocumentContext()$path)
analysis_path <- file.path(file_location, "/codes/data_analysis")
directory_path <- sub("/codes", "", file_location)

# 3. Load the font -------------------------------------------------------------

# Enable showtext
showtext::showtext_auto()

# Add Palatino font to showtext
sysfonts::font_add(
    family = "Palatino",
    regular = paste0(analysis_path, "/aux_files/Palatino Linotype.ttf")
)

# 4. Run the analysis ----------------------------------------------------------

source(file.path(analysis_path, "/descriptive_plots_utils.R"))
source(file.path(analysis_path, "/descriptive_plots.R"))
