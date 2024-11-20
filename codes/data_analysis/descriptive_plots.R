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
telegraaf_data_path <- "data/processed/red_alerts_news/telegraaf_yearly_aggregated.csv"
telegraaf_data_csv  <- file.path(
    paste(directory_path, telegraaf_data_path, sep = "/")
)
telegraaf_data  <- read.csv(telegraaf_data_csv)
telegraaf_data

# telegraaf_data <- telegraaf_data |>
#     dplyr::group_by(year) |>
#     dplyr::summarise(n_articles = sum(n_links), n_count = sum(count))

# Calculate the relative presence of the keywords
telegraaf_data <- telegraaf_data |>
    dplyr::mutate(n_per_article = count / n_links)





# Filter the data for the keywords of interest
telegraaf_data_xtc <- telegraaf_data |>
    dplyr::filter(
        (keyword == "XTC") | (keyword == "MDMA") | (keyword == "ecstasy")
    )

telegraaf_data_cocaine <- telegraaf_data |>
    dplyr::filter(
        (keyword == "cocaine") | (keyword == "cocaïne")
    )

# Calculate the number of articles and the number of mentions
telegraaf_data_xtc <- telegraaf_data_xtc |>
    dplyr::group_by(year) |>
    dplyr::summarise(n_articles = sum(n_links), n_count = sum(count))

telegraaf_data_cocaine <- telegraaf_data_cocaine |>
    dplyr::group_by(year) |>
    dplyr::summarise(n_articles = sum(n_links), n_count = sum(count))

# Calculate the relative presence of the keywords
telegraaf_data_xtc <- telegraaf_data_xtc |>
    dplyr::mutate(n_per_article = n_count / n_articles)

telegraaf_data_cocaine <- telegraaf_data_cocaine |>
    dplyr::mutate(n_per_article = n_count / n_articles)

# Join the data
joined_data <- telegraaf_data_xtc |>
    dplyr::inner_join(telegraaf_data_cocaine, by = "year") |>
    dplyr::mutate(
        n_per_article_xtc = n_per_article.x,
        n_per_article_cocaine = n_per_article.y
    ) |>
    dplyr::select(year, n_per_article_xtc, n_per_article_cocaine)

## Share of news titles mentioning MDMA or cocaine, conditional on being mentioned.
joined_data <- joined_data |>
    dplyr::rename(
        "MDMA" = "n_per_article_xtc",
        "Cocaine" = "n_per_article_cocaine"
    )

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