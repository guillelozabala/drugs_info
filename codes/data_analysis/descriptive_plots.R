library(tidyverse)
library(jsonlite)
library(gridExtra)
library(grid)
library(lintr)
library(showtext)

# Obtain the path of the directory
current_path <- dirname(rstudioapi::getActiveDocumentContext()$path)
directory_path <- sub("codes/data_analysis", "", current_path)

# Define the paths to the data
antenne_reports_loc <- "data/processed/antenne_reports/"
red_alerts_loc <- "data/processed/red_alerts_news/"
euda_loc <- "data/source/euda/"
google_trends_loc <- "data/source/google_trends/"

# Define the path to aux functions
plot_utils_path <- "codes/data_analysis/descriptive_plots_utils.R"

# Load utils
source(file.path(directory_path, plot_utils_path))

# Enable showtext
showtext_auto()

# Add Palatino font to showtext
font_add(
    family = "Palatino",
    regular = paste0(current_path, "/aux_files/Palatino Linotype.ttf")
)


### Dose range, volatility and prices plots ###

# Obtain data from drug testing facilities
test_dosering_paths <- get_csv_files(
    file.path(
        directory_path,
        paste(antenne_reports_loc, "testservice", sep = "/")
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
    testing_doses_plots(file, doses_y_axis_specs, directory_path, slides = TRUE)
}

### Number of total samples plots ###

# Define the path to the data
total_samples_path <- file.path(
    directory_path,
    paste(antenne_reports_loc, "testservice/total_samples_2023.csv", sep = "/")
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

# Plot the total number of samples submitted for each substance
for (column in colnames(total_samples)[2:ncol(total_samples)]) {
    # Plot the number of samples submitted
    samples_plot <- plot_series(
        total_samples[total_samples$year >= 2000, ],
        "year",
        column,
        colors = "#565175",
        title = " ",
        y_label = "Samples",
        y_top = total_samples_y_axis_specs[[column]]$y_top,
        y_steps = total_samples_y_axis_specs[[column]]$y_steps,
        slides = TRUE
    )

    # Save the plots
    ggsave(
        file.path(
            directory_path,
            paste0(total_samples_results, "total_samples_", column, ".png")
        ),
        plot = samples_plot,
        width = 10,
        height = 8,
        dpi = 150
    )
}

# Between-substances comparisons

# Rename the columns to have more readable legends
total_samples <- total_samples |> 
    dplyr::rename(
        "MDMA" = "mdma",
        "Cocaine" = "cocaine",
        "Amphetamine" = "amphetamine",
        "Ketamine" = "ketamine",
        "LSD" = "lsd",
        "2C-B" = "X2cb",
        "3/4MMC" = "X3mmc4mmc",
        "4-FA" = "X4fa",
        "GHB" = "ghb",
        "Other" = "other",
        "Unknown" = "unknown"
    )

# Plot the total number of samples submitted for each substance
compared_samples_plot <- plot_series(
    total_samples[total_samples$year >= 2000, ],
    "year",
    setdiff(colnames(total_samples), c("year", "total")),
    colors = rep(
        c("#565175", "#538a95", "#67b79e", "#ffb727", "#e4491c"),
        length.out = length(
            setdiff(
                colnames(total_samples),
                c("year", "total")
            )
        )
    ),
    title = " ",
    y_label = "Samples",
    y_top = total_samples_y_axis_specs[["mdma"]]$y_top,
    y_steps = total_samples_y_axis_specs[["mdma"]]$y_steps,
    slides = TRUE
)

# Save the plots
ggsave(
    file.path(
        directory_path,
        paste0(total_samples_results, "total_samples_", "comparison", ".png")
    ),
    plot = compared_samples_plot,
    width = 10,
    height = 8,
    dpi = 150
)

# Plot the total number of samples submitted for each NPS
synt_plot <- plot_series(
    total_samples[total_samples$year >= 2000, ],
    "year",
    c("2C-B", "3/4MMC", "4-FA"),
    colors = c("#565175", "#538a95", "#67b79e"),
    title = " ",
    y_label = "Samples",
    y_top = 440,
    y_steps = 40,
    legend_position = "top",
    slides = TRUE
)

# Save the plots
ggsave(
    file.path(
        directory_path,
        paste0(total_samples_results, "total_samples_", "nps_synt", ".png")
    ),
    plot = synt_plot,
    width = 10,
    height = 8,
    dpi = 150
)

# Substances histogram

# Pivot the data to long format
total_samples_pivoted <- total_samples |>
    tidyr::pivot_longer(
        cols = -c(year),
        names_to = "drug",
        values_to = "count"
    )

# Create a new column to indicate which bar to highlight
highlight_drug <- "MDMA"
total_samples_pivoted$highlight <- ifelse(
    total_samples_pivoted$drug == highlight_drug,
    "highlight",
    "normal"
)

# Filter the data for the year of interest
total_samples_pivoted_plot <- total_samples_pivoted |>
    dplyr::filter(year == 2023) |>
    dplyr::filter(drug != "total")

# Plot the histogram
histogram_plot(
    total_samples_pivoted_plot,
    "drug",
    "count",
    "highlight",
    colors = c("highlight" = "#538a95", "normal" = "#565175"),
    title,
    y_label = "Number of samples",
    y_top = 3500,
    y_steps = 500
)

# Save the plot
ggsave(
    file.path(
        directory_path,
        paste0(total_samples_results, "samples_submitted_2023.png")
    ),
    plot = total_samples_plot,
    width = 10,
    height = 8,
    dpi = 150
)

### Telegraaf data ###

# Define the path to the data
red_alerts_path <- paste(directory_path, red_alerts_loc, sep = "/")

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

# Rename the columns for the legend
telegraaf_yearly <- telegraaf_yearly |>
    dplyr::rename(
        "MDMA share" = "share_MDMA",
        "Cocaine share" = "share_Cocaine"
    )

telegraaf_presence <- plot_series(
    telegraaf_yearly[telegraaf_yearly$year >= 2012, ],
    "year",
    c("MDMA share", "Cocaine share"),
    colors = c("#538a95", "#565175"),
    title = " ",
    y_label = "Relative presence",
    y_top = 0.0015,
    y_steps = 0.0003,
    legend_position = "top",
    slides = TRUE
)

ggsave(
    file.path(
        directory_path,
        paste0(total_samples_results, "news_presence_yearly.png", sep = "/")
    ),
    plot = telegraaf_presence,
    width = 10,
    height = 8,
    dpi = 150
)


### EUDA data ###

# Define the path to the data
total_euda_loc <- file.path(
    directory_path,
    paste(euda_loc, "euda_tables_1.csv", sep = "/")
)

# Load the data
total_euda <- read.csv(total_euda_loc)

# Replace NA with zeros and convert all values to integers
total_euda[is.na(total_euda)] <- 0
total_euda[] <- lapply(total_euda, function(x) as.integer(x))

# Rename and aggregate the columns
total_euda <- total_euda |>
    dplyr::mutate(
        sum_others = rowSums(total_euda[, !names(total_euda) %in% "Year"])
    ) |>
    dplyr::rename(year = "Year")

# Plot the number of detected NPS
euda_new_substances <- plot_series(
    total_euda,
    x_var = "year",
    y_vars = "sum_others",
    colors = "#565175",
    title = " ",
    y_label = "Number of NPS",
    y_top = 450,
    y_steps = 50,
    slides = TRUE
)

ggsave(
    file.path(
        directory_path,
        paste0(total_samples_results, "euda_new_substances.png", sep = "/")
    ),
    plot = euda_new_substances,
    width = 10,
    height = 10,
    dpi = 150
)


### EUDA Histogram ###

# Define the path to the data
mdma_euda_loc <- file.path(
    directory_path,
    paste(euda_loc, "GPS-73.xlsx", sep = "/")
)

# Load the data
mdma_euda_rates <- readxl::read_excel(mdma_euda_loc, skip = 3, n_max = 29)

# Drop Malta (empty row )
mdma_euda_rates <- mdma_euda_rates[mdma_euda_rates$Country != "Malta", ]

# Create a new column to indicate which bar to highlight
highlight_country <- "Netherlands"
mdma_euda_rates$highlight <- ifelse(
    mdma_euda_rates$Country == highlight_country,
    "highlight",
    "normal"
)

# Last year prevalence of ecstasy use, 15-24 years old
euda_mdma_plot <- histogram_plot(
    mdma_euda_rates,
    "Country",
    "Total",
    "highlight",
    colors = c("highlight" = "#538a95", "normal" = "#565175"),
    title,
    y_label = "Rate (%)",
    y_top = 11,
    y_steps = 1
)

# Save the plot
ggsave(
    file.path(
        directory_path,
        paste0(total_samples_results, "euda_mdma_rates.png", sep = "/")
    ),
    plot = euda_mdma_plot,
    width = 10,
    height = 8,
    dpi = 150
)








cocaine_plot <- plot_series(
    total_samples[total_samples$year >= 2000, ],
    "year",
    "cocaine",
    colors = "#565175",
    title = " ",
    y_label = "Samples",
    y_top = total_samples_y_axis_specs[["cocaine"]]$y_top,
    y_steps = total_samples_y_axis_specs[["cocaine"]]$y_steps,
    slides = TRUE
)

cocaine_plot

cocaine_plot_wline <- cocaine_plot + geom_vline(
    xintercept = 2014,
    linetype = "dashed",
    color = "#538a95",
    size = 1.5
)

# Save the plots
ggsave(
    file.path(
        directory_path,
        paste0(total_samples_results, "total_samples_", "cocaine_wline", ".png")
    ),
    plot = cocaine_plot_wline,
    width = 10,
    height = 8,
    dpi = 150
)





















google_trends_path <- paste(directory_path, google_trends_loc, sep = "/")

# Load the data
google_trends <- read.csv(
    paste(google_trends_path, "multiTimeline.csv", sep = "/"),
    skip = 2
)

google_trends <- google_trends |>
    dplyr::rename(
        "year_month" = "Month",
        "MDMA" = "MDMA...Netherlands.",
        "Cocaine" = "Cocaine...Netherlands.",
        "Heroin" = "Heroin...Netherlands.",
        "Hashish" = "Hashish...Netherlands."
    )

google_trends$year_month_date <- as.Date(
    paste0(google_trends$year_month, "-01")
)


google_trends_plot <- plot_series(
    google_trends,
    "year_month_date",
    c("MDMA", "Cocaine", "Heroin", "Hashish"),
    colors = c("#565175", "#e4491c", "#ffb727", "#67b79e"),
    title = " ",
    y_label = "Trend index",
    y_top = 110,
    y_steps = 10,
    x_steps = 128,
    slides = TRUE,
    years_custom_range = FALSE,
    legend_position = "top"
) + geom_vline(
    xintercept = as.Date("2016-10-01"),
    linetype = "dashed",
    color = "black",
    size = 1.5
)

ggsave(
    file.path(
        directory_path,
        paste0(total_samples_results, "google_trends.png", sep = "/")
    ),
    plot = google_trends_plot,
    width = 30,
    height = 16,
    dpi = 100
)