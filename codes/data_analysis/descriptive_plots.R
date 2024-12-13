
# 1. Load Libraries ------------------------------------------------------------

library(tidyverse)
library(jsonlite)
library(gridExtra)
library(grid)
library(lintr)
library(showtext)

# 2. Load Functions -----------------------------------------------------------

# Obtain the path of the directory
current_path <- dirname(rstudioapi::getActiveDocumentContext()$path)
directory_path <- sub("/codes/data_analysis", "", current_path)

# Define the path to aux functions
plot_utils_path <- "codes/data_analysis/descriptive_plots_utils.R"

# Load utils
source(file.path(directory_path, plot_utils_path))

# 3. Define File Paths  --------------------------------------------------------

# From the Antenne Reports:
antenne_location <- "data/processed/antenne_reports/"
testservice_path <- file.path(
    directory_path,
    paste0(antenne_location, "testservice")
)
testservice_drugs_paths <- get_csv_files(
    testservice_path,
    "dosering"
)
testservice_total_paths <- get_csv_files(
    testservice_path,
    "total"
)

# From De Telegraaf:
telegraaf_news_location <- "data/processed/red_alerts_news/"
# From De Telegraaf:
telegraaf_news_path <- file.path(
    directory_path,
    paste0(telegraaf_news_location, "telegraaf_yearly_aggregated.csv")
)

# From EUDA:
euda_location <- "data/source/euda/"
euda_npss_path <- file.path(
    directory_path,
    paste0(euda_location, "euda_tables_1.csv") #?
)
euda_mdma_path <- file.path(
    directory_path,
    paste0(euda_location, "GPS-73.xlsx") #?
)

# From Google Trends:
google_trends_location <- "data/source/google_trends/"
google_trends_path <- file.path(
    directory_path,
    paste0(google_trends_location, "multiTimeline.csv")
)

# Results directory
results_location <- "results/figures/descriptives/"

# 4. Load Specifications -------------------------------------------------------

# Load the y-axis specifications for the doses
doses_y_axis_specs <- read_json(
    file.path(current_path, "aux_files/doses_y_axis.json"),
    simplifyVector = TRUE
)

# Load the y-axis specifications for the total samples
total_samples_y_axis_specs <- read_json(
    paste(current_path, "aux_files/total_samples_y_axis.json", sep = "/"),
    simplifyVector = TRUE
)

# 5. Load Data ----------------------------------------------------------------

# No need to load *testservice_drugs*, since the function *testing_doses_plots*
# will do it

# From the Antenne Reports:
testservice_total <- read.csv(testservice_total_paths)

# From De Telegraaf:
telegraaf_yearly_news <- read.csv(telegraaf_news_path)

# From EUDA:
euda_npss <- read.csv(euda_npss_path)
euda_mdma <- readxl::read_excel(euda_mdma_path, skip = 3, n_max = 29)

# From Google Trends:
google_trends <- read.csv(google_trends_path, skip = 2)


# 6. Data Preprocessing --------------------------------------------------------

# --- 6.1. Antenne reports -----------------------------------------------------

# Rename the columns to have more readable legends
testservice_total <- testservice_total |>
    dplyr::rename(
        "MDMA" = "mdma",
        "Cocaine" = "cocaine",
        "Amphetamine" = "amphetamine",
        "Ketamine" = "ketamine",
        "LSD" = "lsd",
        "2C-B" = "X2cb",
        "3MMC-4MMC" = "X3mmc4mmc",
        "4-FA" = "X4fa",
        "GHB" = "ghb",
        "Other" = "other",
        "Unknown" = "unknown"
    )

# Obtain a pivoted version of the data for the bar chart
testservice_total_pivoted <- testservice_total |>
    tidyr::pivot_longer(
        cols = -c(year),
        names_to = "drug",
        values_to = "count"
    )

# Create a new column to indicate which bar to highlight
testservice_total_pivoted$highlight <- ifelse(
    testservice_total_pivoted$drug == "MDMA",
    "highlight",
    "normal"
)

# Filter the data for the year of interest
testservice_total_pivoted_plot <- testservice_total_pivoted |>
    dplyr::filter(year == 2023) |>
    dplyr::filter(drug != "total")

# --- 6.2. De Telegraaf --------------------------------------------------------

# Select the words of interest
keywords <- c("XTC", "MDMA", "ecstasy", "cocaine", "cocaïne")
telegraaf_yearly_news <- telegraaf_yearly_news |>
    dplyr::filter(keyword %in% keywords)

# Get relative presence of the keywords
telegraaf_yearly_news <- telegraaf_yearly_news |>
    dplyr::mutate(n_per_articles = count / n_links)

# Aggregate the results at the month level by kind of drug
telegraaf_yearly_news <- telegraaf_yearly_news |>
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
telegraaf_yearly_news <- telegraaf_yearly_news |>
    dplyr::rename(
        "MDMA share" = "share_MDMA",
        "Cocaine share" = "share_Cocaine"
    )

# --- 6.3. EUDA ----------------------------------------------------------------

# Replace NA with zeros and convert all values to integers
euda_npss[is.na(euda_npss)] <- 0
euda_npss[] <- lapply(euda_npss, function(x) as.integer(x))

# Rename and aggregate the columns
euda_npss <- euda_npss |>
    dplyr::mutate(
        sum_others = rowSums(euda_npss[, !names(euda_npss) %in% "Year"])
    ) |>
    dplyr::rename(year = "Year")

# Drop Malta (empty row)
euda_mdma <- euda_mdma[euda_mdma$Country != "Malta", ]

# Create a new column to indicate which bar to highlight
euda_mdma$highlight <- ifelse(
    euda_mdma$Country == "Netherlands",
    "highlight",
    "normal"
)

# ---- 6.4. Google Trends ------------------------------------------------------

# Rename the columns
google_trends <- google_trends |>
    dplyr::rename(
        "year_month" = "Month",
        "MDMA" = "MDMA...Netherlands.",
        "Cocaine" = "Cocaine...Netherlands.",
        "Heroin" = "Heroin...Netherlands.",
        "Hashish" = "Hashish...Netherlands."
    )

# Create a new column with the date
google_trends$year_month_date <- as.Date(
    paste0(google_trends$year_month, "-01")
)


# 7. Load the font -------------------------------------------------------------

# Enable showtext
showtext_auto()

# Add Palatino font to showtext
font_add(
    family = "Palatino",
    regular = paste0(current_path, "/aux_files/Palatino Linotype.ttf")
)


# 8. Plotting ------------------------------------------------------------------

# --- 8.1. Antenne reports -----------------------------------------------------

# Dose range, volatility and prices plots
for (file in testservice_drugs_paths) {
    testing_doses_plots(file, doses_y_axis_specs, directory_path, slides = TRUE)
}

# Number of total samples for each substance
samples_plots_list <- list()
for (column in colnames(testservice_total)[2:ncol(testservice_total)]) {
    # Plot the number of samples submitted
    samples_plot <- plot_series(
        testservice_total[testservice_total$year >= 2000, ],
        "year",
        column,
        colors = "#565175",
        title = " ",
        y_label = "Samples",
        y_top = total_samples_y_axis_specs[[column]]$y_top,
        y_steps = total_samples_y_axis_specs[[column]]$y_steps,
        slides = TRUE
    )

    # Store the plot
    samples_plots_list[[column]] <- samples_plot

    # Save the plots
    ggsave(
        file.path(
            directory_path,
            paste0(results_location, "total_samples_", column, ".png")
        ),
        plot = samples_plot,
        width = 10,
        height = 8,
        dpi = 150
    )
}

# Other plots: 2014 Amsterdam incident
cocaine_plot_wline <- samples_plots_list$Cocaine + geom_vline(
    xintercept = 2014,
    linetype = "dashed",
    color = "#538a95",
    linewidth = 1.5
)

# Other plots: Substances comparison
compared_samples_plot <- plot_series(
    testservice_total[testservice_total$year >= 2000, ],
    "year",
    setdiff(colnames(testservice_total), c("year", "total")),
    colors = rep(
        c("#565175", "#538a95", "#67b79e", "#ffb727", "#e4491c"),
        length.out = length(
            setdiff(
                colnames(testservice_total),
                c("year", "total")
            )
        )
    ),
    title = " ",
    y_label = "Samples",
    y_top = total_samples_y_axis_specs[["MDMA"]]$y_top,
    y_steps = total_samples_y_axis_specs[["MDMA"]]$y_steps,
    slides = TRUE
)

# Other plots: Total number of samples submitted for each NPS
synt_plot <- plot_series(
    testservice_total[testservice_total$year >= 2000, ],
    "year",
    c("2C-B", "3MMC-4MMC", "4-FA"),
    colors = c("#565175", "#538a95", "#67b79e"),
    title = " ",
    y_label = "Samples",
    y_top = 440,
    y_steps = 40,
    legend_position = "top",
    slides = TRUE
)

# Other plots: Bar chart of the number of samples submitted in 2023
testservice_total_plot <- bar_chart_plot(
    testservice_total_pivoted_plot,
    "drug",
    "count",
    "highlight",
    colors = c("highlight" = "#538a95", "normal" = "#565175"),
    title,
    y_label = "Number of samples",
    y_top = 3500,
    y_steps = 500
)

# Save other plots
ggsave(
    file.path(
        directory_path,
        paste0(results_location, "total_samples_", "cocaine_wline", ".png")
    ),
    plot = cocaine_plot_wline,
    width = 10,
    height = 8,
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "total_samples_", "comparison", ".png")
    ),
    plot = compared_samples_plot,
    width = 10,
    height = 8,
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "total_samples_", "nps_synt", ".png")
    ),
    plot = synt_plot,
    width = 10,
    height = 8,
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "samples_submitted_2023.png")
    ),
    plot = testservice_total_plot,
    width = 10,
    height = 8,
    dpi = 150
)

# --- 8.2. De Telegraaf --------------------------------------------------------

# Plot the relative presence of MDMA and Cocaine in the news
telegraaf_presence <- plot_series(
    telegraaf_yearly_news[telegraaf_yearly_news$year >= 2012, ],
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

# Save the plot
ggsave(
    file.path(
        directory_path,
        paste0(results_location, "news_presence_yearly.png", sep = "/")
    ),
    plot = telegraaf_presence,
    width = 10,
    height = 8,
    dpi = 150
)

# --- 8.3. EUDA data -----------------------------------------------------------

# Number of detected NPS by year
euda_new_substances <- plot_series(
    euda_npss,
    x_var = "year",
    y_vars = "sum_others",
    colors = "#565175",
    title = " ",
    y_label = "Number of NPS",
    y_top = 450,
    y_steps = 50,
    slides = TRUE
)

# Last year prevalence of ecstasy use, 15-24 years old
euda_mdma_plot <- bar_chart_plot(
    euda_mdma,
    "Country",
    "Total",
    "highlight",
    colors = c("highlight" = "#538a95", "normal" = "#565175"),
    title,
    y_label = "Rate (%)",
    y_top = 11,
    y_steps = 1
)

# Save the plots
ggsave(
    file.path(
        directory_path,
        paste0(results_location, "euda_new_substances.png", sep = "/")
    ),
    plot = euda_new_substances,
    width = 10,
    height = 10,
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "euda_mdma_rates.png", sep = "/")
    ),
    plot = euda_mdma_plot,
    width = 10,
    height = 8,
    dpi = 150
)

# --- 8.4. Google Trends -------------------------------------------------------

# Google trends comparison
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
    linewidth = 1.5
)

# Save the plot
ggsave(
    file.path(
        directory_path,
        paste0(results_location, "google_trends.png", sep = "/")
    ),
    plot = google_trends_plot,
    width = 30,
    height = 16,
    dpi = 100
)
