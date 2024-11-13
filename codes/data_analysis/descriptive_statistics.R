library(tidyverse)
library(lintr)

# Read the CSV file
# Obtain the path of the directory and join it with the path of the CSV
directory_path <- dirname(rstudioapi::getActiveDocumentContext()$path)
directory_path <- sub("codes/data_analysis", "", directory_path)
preventie_data_path <- "data/processed/preventie_indicatoren_mdma.csv"
csv_path <- file.path(paste(directory_path, preventie_data_path, sep = "/"))
data <- read.csv(csv_path)

# Display the first few rows of the data
head(data)


# Source the external R script containing the function
source(file.path(directory_path, "codes/data_analysis/descriptive_statistics_utils.R"))

plot_series(
    data,
    "year",
    "n_reports",
    colors = "deeppink2",
    title = "Number of Samples (1994-2023)",
    y_label = "Number of Samples",
    y_top = 2500,
    y_steps = 500
)

plot_series(
    data,
    "year",
    c("dose_min", "dose_max", "dose_mean"),
    colors = c("darkorchid", "deeppink2", "deepskyblue2"),
    title = "XTC pills containing exclusively or mainly MDMA -- Dosage in milligrams",
    y_label = "Mgs",
    y_top = 350,
    y_steps = 50
)

plot_series(
    data,
    "year",
    "adj_volatility",
    colors = "deeppink2",
    title = "XTC pills containing exclusively or mainly MDMA -- Dosage volatility in milligrams",
    y_label = "Volatility (Mgs)",
    y_top = 2200,
    y_steps = 220
)

plot_series(
    data[data["year"] >= 2002, ],
    "year",
    "price_per_pill",
    colors = "chartreuse3",
    title = "XTC pills containing exclusively or mainly MDMA -- Price per pill",
    y_label = "Price (€)",
    y_top = 6,
    y_steps = 1
)

plot_series(
    data[data["year"] >= 2002, ],
    "year",
    "price_per_mg",
    colors = "chartreuse3",
    title = "XTC pills containing exclusively or mainly MDMA -- Price per milligram",
    y_label = "Price (€)",
    y_top = 0.05,
    y_steps = 0.01
)

test_data_path <- "data/processed/225_0.csv"
csv_test_path <- file.path(paste(directory_path, test_data_path, sep = "/"))
test_data <- read.csv(csv_test_path)

plot_cumulative_flows(
    test_data,
    "year",
    colnames(test_data[, 2:(length(test_data) - 1)]),
    title = "",
    y_label = "Value",
    y_top = 6000,
    y_steps = 500
)

plot_cumulative_flows(
    test_data,
    "year",
    colnames(test_data[, 3:5]),
    title = "",
    y_label = "Value",
    y_top = 1200,
    y_steps = 120
)

# High spike in coicaine after 2014
# Check visits per consumption rates

# Regional and national warnings not considered
# MDI: 2009 onwards

# Before: a mistery
# 2012: No mention of Red Alert
# 2013: No Red Alert took place
# 2014: Red Alert in Amsterdam (GGD): white heroin sold as cocaine
# 2015: 2014's Red Alert was still in the news
# 2016: National Red Alert: PMMA sold as MDMA
# 2017: No mention of Red Alert
# 2018: Regional Red Alert in Rotterdam - atropine in cocaine and ketamine
# 2019: No Red Alert took place
# 2020: Limited Red Alert: sythetic weed
# 2021: Red Alert: DOC sold as 2C-B
# 2022: Red Alert: Drinks containing liquid MDMA
# 2023: Red Alert: Over 300mg MDMA pills

# https://www.lisbonaddictions.eu/lisbon-addictions-2024/presentations/mdma-misinformation-what-dealers-claim-versus-actual-mdma-content-ecstasy-pills