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

# Define the path to the data
preventie_data_path <- "testservice/total_samples_2023.csv"
csv_preventie_path <- file.path(
    paste(directory_path, preventie_data_path, sep = "/")
)

# Obtain data from drug testing facilities
test_dosering_datasets <- get_csv_files(
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

# Obtain the plots for the dosages, volatility, and prices
for (file in test_dosering_datasets) {
    testing_doses_plots(file, doses_y_axis_specs, directory_path)
}



## Number of drug samples submitted to the testing facilities.
total_samples <- plot_series(
    test_data[test_data$year >= 2000, ],
    "year",
    "total",
    colors = "deeppink",
    title = " ",
    y_label = "Samples",
    y_top = 6000,
    y_steps = 600
)

total <- grid.arrange(
    arrangeGrob(
        total_samples,
        ncol = 1
    )
)

ggsave(
    "results/figures/total.png",
    plot = total,
    width = 10,
    height = 10,
    dpi = 600
)

## Number of MDMA pill samples submitted to the testing facilities.
mdma_samples <- plot_series(
    test_data,
    "year",
    "mdma",
    colors = "deeppink",
    title = " ",
    y_label = "MDMA samples",
    y_top = 3600,
    y_steps = 360
)

mdma <- grid.arrange(
    arrangeGrob(
        mdma_samples,
        ncol = 1
    )
)

ggsave(
    "results/figures/mdma.png",
    plot = mdma,
    width = 10,
    height = 10,
    dpi = 600
)

## Number of cocaine samples submitted to the testing facilities.
cocaine_samples <- plot_series(
    test_data[test_data$year >= 2000, ],
    "year",
    "cocaine",
    colors = "deeppink",
    title = " ",
    y_label = "Cocaine samples",
    y_top = 600,
    y_steps = 60
)

cocaine <- grid.arrange(
    arrangeGrob(
        cocaine_samples,
        ncol = 1
    )
)

ggsave(
    "results/figures/cocaine.png",
    plot = cocaine,
    width = 10,
    height = 10,
    dpi = 600
)

## Number of other samples submitted to the testing facilities.
ketamine_samples <- plot_series(
    test_data[test_data$year >= 2000, ],
    "year",
    "ketamine",
    colors = "deeppink",
    title = "Ketamine",
    y_label = " ",
    y_top = 400,
    y_steps = 40,
    x_steps = 2
)

amphetamine_samples <- plot_series(
    test_data[test_data$year >= 2000, ],
    "year",
    "amphetamine",
    colors = "deeppink",
    title = "Amphetamine",
    y_label = " ",
    y_top = 400,
    y_steps = 40,
    x_steps = 2
)

twocb_samples <- plot_series(
    test_data[test_data$year >= 2000, ],
    "year",
    "X2cb",
    colors = "deeppink",
    title = "2C-B",
    y_label = " ",
    y_top = 400,
    y_steps = 40,
    x_steps = 2
)

threefourmmc_samples <- plot_series(
    test_data[test_data$year >= 2000, ],
    "year",
    "X3mmc4mmc",
    colors = "deeppink",
    title = "3MMC/4MMC",
    y_label = " ",
    y_top = 400,
    y_steps = 40,
    x_steps = 2
)

# Arrange the plots with the title
syn_drugs <- grid.arrange(
    arrangeGrob(
        ketamine_samples,
        amphetamine_samples,
        twocb_samples,
        threefourmmc_samples,
        ncol = 2
    )
)

ggsave(
    "results/figures/syn_drugs.png",
    plot = syn_drugs,
    width = 10,
    height = 10,
    dpi = 600
)


###
# Do the same for the Telegraaf data (CLEAN THIS MESS)
###
telegraaf_data_path <- "data/processed/red_alerts_news/telegraaf_yearly_aggregated.csv"
telegraaf_data_csv  <- file.path(
    paste(directory_path, telegraaf_data_path, sep = "/")
)
telegraaf_data  <- read.csv(telegraaf_data_csv)

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