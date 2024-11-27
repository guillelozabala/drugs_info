library(tidyverse)
library(jsonlite)
library(gridExtra)
library(grid)
library(lintr)

# Obtain the path of the directory
current_path <- dirname(rstudioapi::getActiveDocumentContext()$path)
directory_path <- sub("codes/data_analysis", "", current_path)

# Define the path to the data
antenne_reports_path <- "data/processed/antenne_reports/"

# Define the path to aux functions
plot_utils_path <- "codes/data_analysis/descriptive_plots_utils.R"

# Load utils
source(file.path(directory_path, plot_utils_path))


### Dose range, volatility and prices plots ###

# Obtain data from drug testing facilities
test_dosering_paths <- get_csv_files(
    file.path(
        directory_path,
        paste(antenne_reports_path, "testservice", sep = "/")
    ),
    "dosering"
)

# Load the y-axis specifications for each substance
doses_y_axis_specs <- read_json(
    paste(current_path, "aux_files/doses_y_axis.json", sep = "/"),
    simplifyVector = TRUE
)

# Obtain the plots 
for (file in test_dosering_paths) {
    testing_doses_plots(file, doses_y_axis_specs, directory_path)
}


### Number of total samples plots ###

# Define the path to the data
total_samples_path <- file.path(
    directory_path,
    paste(antenne_reports_path, "testservice/total_samples_2023.csv", sep = "/")
)

# Load the data
total_samples <- read.csv(total_samples_path)

# Load the y-axis specifications for each substance
total_samples_y_axis_specs <- read_json(
    paste(current_path, "aux_files/total_samples_y_axis.json", sep = "/"),
    simplifyVector = TRUE
)

# Define the path to save the results
total_samples_results <- "results/figures/descriptives/"

for (column in colnames(total_samples)[2:ncol(total_samples)]) {
    # Plot the number of samples submitted
    samples_plot <- plot_series(
        total_samples,
        "year",
        column,
        colors = "deeppink",
        title = " ",
        y_label = "Samples",
        y_top = total_samples_y_axis_specs[[column]]$y_top,
        y_steps = total_samples_y_axis_specs[[column]]$y_steps
    )

    # Save the plots
    ggsave(
        file.path(
            directory_path,
            paste0(total_samples_results, "total_samples_", column, ".png")
        ),
        plot = samples_plot,
        width = 10,
        height = 10,
        dpi = 600
    )
}

###
# Do the same for the Telegraaf data (CLEAN THIS MESS)
###

# Define the path to the data
red_alerts_loc <- "data/processed/red_alerts_news/"
red_alerts_path <- paste(directory_path, red_alerts_loc, sep = "/")

# Load the data
telegraaf_monthly <- read.csv(
    paste(red_alerts_path, "telegraaf_monthly_aggregated.csv", sep = "/")
)

# Select the words of interest
keywords <- c("XTC", "MDMA", "ecstasy", "cocaine", "cocaïne")
telegraaf_monthly <- telegraaf_monthly |>
    dplyr::filter(keyword %in% keywords)

# Get relative presence of the keywords
telegraaf_monthly <- telegraaf_monthly |>
    dplyr::mutate(n_per_articles = count / n_links)

# Aggregate the results at the month level by kind of drug
telegraaf_monthly <- telegraaf_monthly |>
    dplyr::mutate(
        drug = dplyr::case_when(
            keyword %in% c("XTC", "MDMA", "ecstasy") ~ "MDMA",
            keyword %in% c("cocaine", "cocaïne") ~ "Cocaine",
            TRUE ~ NA_character_
        )
    ) |>
    dplyr::group_by(year_month, drug, n_links) |>
    dplyr::summarise(
        n_count = sum(count),
        share = sum(n_per_articles),
        .groups = "drop"
    ) |>
    tidyr::pivot_wider(
        names_from = drug,
        values_from = c(n_count, share),
        values_fill = list(n_count = 0, share = 0)
    )


telegraaf_monthly$year_month_date <- as.Date(paste0(telegraaf_monthly$year_month, "-01"))
telegraaf_monthly

plot_series(
    telegraaf_monthly[telegraaf_monthly$year_month_date >= "2013-01-01", ],
    "year_month_date",
    c("share_MDMA", "share_Cocaine"),
    colors = c("deeppink2", "darkorchid"),
    title = " ",
    y_label = "Relative presence",
    y_top = 0.003,
    y_steps = 0.0005,
    x_steps = 6,
    legend_position = "top",
    years_custom_range = FALSE
)




data_long(telegraaf_monthly, "share") |> head()


news_presence <- plot_series(
    joined_data,
    "year",
    c("MDMA", "Cocaine"),
    colors = c("deeppink2", "darkorchid"),
    title = " ",
    y_label = "Relative presence",
    y_top = 0.01,
    y_steps = 0.0005,
    legend_position = "top"
)

news_presence_grob <- grid.arrange(
    arrangeGrob(
        news_presence,
        ncol = 1
    )
)

ggsave(
    "results/figures/news_presence.png",
    plot = news_presence_grob,
    width = 10,
    height = 10,
    dpi = 600
)


# Load the data
telegraaf_yearly <- read.csv(
    paste(red_alerts_path, "telegraaf_yearly_aggregated.csv", sep = "/")
)

# Select the words of interest
keywords <- c("XTC", "MDMA", "ecstasy", "cocaine", "cocaïne")
telegraaf_yearly <- telegraaf_yearly |>
    dplyr::filter(keyword %in% keywords)

# Get relative presence of the keywords
telegraaf_yearly <- telegraaf_yearly |>
    dplyr::mutate(n_per_articles = count / n_links)

# Aggregate the results at the month level by kind of drug
telegraaf_yearly <- telegraaf_yearly |>
    dplyr::mutate(
        drug = dplyr::case_when(
            keyword %in% c("XTC", "MDMA", "ecstasy") ~ "MDMA",
            keyword %in% c("cocaine", "cocaïne") ~ "Cocaine",
            TRUE ~ NA_character_
        )
    ) |>
    dplyr::group_by(year, drug, n_links) |>
    dplyr::summarise(
        n_count = sum(count),
        share = sum(n_per_articles),
        .groups = "drop"
    ) |>
    tidyr::pivot_wider(
        names_from = drug,
        values_from = c(n_count, share),
        values_fill = list(n_count = 0, share = 0)
    )


plot_series(
    telegraaf_yearly[telegraaf_yearly$year >= 2012, ],
    "year",
    c("share_MDMA", "share_Cocaine"),
    colors = c("deeppink2", "darkorchid"),
    title = " ",
    y_label = "Relative presence",
    y_top = 0.0015,
    y_steps = 0.0003,
    legend_position = "top",
    years_custom_range = FALSE
)

###

# Define the path to the data
euda_path <- "data/processed/euda/"

# Define the path to the data
total_euda_path <- file.path(
    directory_path,
    paste(euda_path, "euda_tables_1.csv", sep = "/")
)

# Load the data
total_euda <- read.csv(total_euda_path)

# Replace NA with zeros and convert all values to integers
total_euda[is.na(total_euda)] <- 0  # Replace NA with zeros
total_euda[] <- lapply(total_euda, function(x) as.integer(x))  # Convert all columns to integers

# Create a new column that is the sum of all columns but the first one, replacing NAs with 0
total_euda <- total_euda |>
    dplyr::rename(year = "Year")

total_euda$sum_others <- rowSums(total_euda[, !names(total_euda) %in% "year"])

total_euda


data_long(total_euda, "sum_others")$value

library(showtext)

# Enable showtext
showtext_auto()

# Add Palatino font to showtext
font_add(family = "Palatino", regular = "C:/Users/g-mart36/Downloads/Palatino Linotype.ttf") # Adjust the file path if needed

euda_new_substances <- plot_series(
    total_euda,
    x_var = "year",
    y_vars = "sum_others",
    colors = "#565175",
    title = " ",
    y_label = "#",
    y_top = 450,
    y_steps = 50,
    # legend_position = "top",
    # years_custom_range = FALSE,
    slides = TRUE
)

ggsave(
    "results/figures/descriptives/euda_new_substances.png",
    plot = euda_new_substances,
    width = 10,
    height = 10,
    dpi = 600
)
