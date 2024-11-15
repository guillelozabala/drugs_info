library(tidyverse)
library(lintr)
library(gridExtra)
library(grid)

# Source the external R script containing the function
source(
    file.path(
        directory_path,
        "codes/data_analysis/descriptive_statistics_utils.R"
    )
)

# Obtain the path of the directory 
directory_path <- dirname(rstudioapi::getActiveDocumentContext()$path)
directory_path <- sub("codes/data_analysis", "", directory_path)

# Define the path to the data
preventie_data_path <- "data/processed/preventie_indicatoren_mdma.csv"
csv_preventie_path <- file.path(
    paste(directory_path, preventie_data_path, sep = "/")
)

test_data_path <- "data/processed/225_0.csv"
csv_test_path <- file.path(paste(directory_path, test_data_path, sep = "/"))

# Read the CSVs files
preventie_data <- read.csv(csv_path)
test_data <- read.csv(csv_test_path)


## XTC pills containing exclusively or mainly MDMA -- Dosage in milligrams
data_labels <- preventie_data |>
    dplyr::rename(
        "Minimum dosis" = "dose_min",
        "Maximum dosis" = "dose_max",
        "Mean dosis" = "dose_mean"
    )

mdma_miligrams <- plot_series(
    data_labels,
    "year",
    c("Minimum dosis", "Maximum dosis", "Mean dosis"),
    colors = c("darkorchid", "deeppink", "deepskyblue2"),
    title = " ",
    y_label = "Milligrams",
    y_top = 350,
    y_steps = 50,
    legend_position = "top"
)

m_milligrams <- grid.arrange(
    arrangeGrob(
        mdma_miligrams,
        ncol = 1
    )
)

ggsave(
    "results/figures/mdma_milligrams.png",
    plot = m_milligrams,
    width = 10,
    height = 10,
    dpi = 600
)

## XTC pills containing exclusively or mainly MDMA -- Dosage volatility in milligrams
adjusted_volatility <- plot_series(
    data,
    "year",
    "adj_volatility",
    colors = "darkslategray",
    title = " ",
    y_label = "Volatility (mg)",
    y_top = 2200,
    y_steps = 220
)

adj_volatility <- grid.arrange(
    arrangeGrob(
        adjusted_volatility,
        ncol = 1
    )
)

ggsave(
    "results/figures/adjusted_volatility.png",
    plot = adj_volatility,
    width = 10,
    height = 10,
    dpi = 600
)

## XTC pills containing exclusively or mainly MDMA -- Price per pill
## and per milligram
pill_price <- plot_series(
    data[data["year"] >= 2002, ],
    "year",
    "price_per_pill",
    colors = "chartreuse3",
    title = "Price per pill",
    y_label = "€",
    y_top = 6,
    y_steps = 1,
    x_steps = 2
)

milligram_price <- plot_series(
    data[data["year"] >= 2002, ],
    "year",
    "price_per_mg",
    colors = "chartreuse3",
    title = "Price per milligram",
    y_label = "€/mg",
    y_top = 0.06,
    y_steps = 0.01,
    x_steps = 2
)

prices <- grid.arrange(
    arrangeGrob(
        pill_price,
        milligram_price,
        ncol = 2
    )
)

ggsave(
    "results/figures/prices.png",
    plot = prices,
    width = 10,
    height = 10,
    dpi = 600
)

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
telegraaf_data_path <- "data/processed/telegraaf_yearly_aggregated.csv"
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