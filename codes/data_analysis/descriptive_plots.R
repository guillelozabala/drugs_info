
# 1. Define File Paths  --------------------------------------------------------

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

# From the National Reports:
national_location <- "data/processed/national_reports/"
incidents_path <- file.path(
    directory_path,
    paste0(national_location, "incidents/joint_incidents.csv")
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
    paste0(euda_location, "edr2025-nps-table2025_en.csv")
) # "edr2024-nps-table-2_en.csv") #?

euda_mdma_path <- file.path(
    directory_path,
    paste0(euda_location, "GPS-73.xlsx")
)

euda_mdma_trend_path <- file.path(
    directory_path,
    paste0(euda_location, "GPS-272.xlsx")
)

# From Google Trends:
google_trends_location <- "data/source/google_trends/"
google_trends_path <- file.path(
    directory_path,
    paste0(google_trends_location, "multiTimeline.csv")
)

# Results directory
results_location <- "results/figures/descriptives/"

# 2. Load Specifications -------------------------------------------------------

# Load the y-axis specifications for the doses
doses_y_axis_specs <- jsonlite::read_json(
    file.path(analysis_path, "aux_files/doses_y_axis.json"),
    simplifyVector = TRUE
)

# Load the y-axis specifications for the total samples
total_samples_y_axis_specs <- jsonlite::read_json(
    paste(analysis_path, "aux_files/total_samples_y_axis.json", sep = "/"),
    simplifyVector = TRUE
)

# Load the y-axis specifications for hospitalizations
hospitalizations_y_axis_specs <- jsonlite::read_json(
    paste(analysis_path, "aux_files/hospitalizations_y_axis.json", sep = "/"),
    simplifyVector = TRUE
)

# 3. Load Data ----------------------------------------------------------------

# No need to load *testservice_drugs*, since the function *testing_doses_plots*
# will do it

# From the Antenne Reports:
testservice_total <- read.csv(testservice_total_paths)

# From the National Reports:
incidents <- read.csv(incidents_path)

# From De Telegraaf:
telegraaf_yearly_news <- read.csv(telegraaf_news_path)

# From EUDA:
euda_npss <- read.csv(euda_npss_path)
euda_mdma <- readxl::read_excel(euda_mdma_path, skip = 3, n_max = 29)
euda_mdma_trend <- readxl::read_excel(
    euda_mdma_trend_path,
    skip = 3,
    n_max = 29
)

# From Google Trends:
google_trends <- read.csv(google_trends_path, skip = 2)


# 4. Data Preprocessing --------------------------------------------------------

# --- 4.1. Antenne reports -----------------------------------------------------

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

# --- 4.2. National reports ----------------------------------------------------

# Filter and rename the columns
incidents_plots <- incidents |>
    dplyr::filter(year >= 2012) |>
    dplyr::rename(
        "Light" = "light_incidents",
        "Moderate" = "moderate_incidents",
        "Severe" = "severe_incidents"
    )

# Keep data from hospitals
incidents_hospitals <- incidents_plots |>
    dplyr::filter(origin == "SEH-MDI-ziekenhuizen")

# --- 4.3. De Telegraaf --------------------------------------------------------

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

# --- 4.4. EUDA ----------------------------------------------------------------

# Replace NA with zeros and convert all values to integers
euda_npss[is.na(euda_npss)] <- 0
euda_npss[] <- lapply(euda_npss, function(x) as.integer(x))

# Rename and aggregate the columns
euda_npss <- euda_npss |>
    dplyr::mutate(
        sum_others = rowSums(euda_npss[, !names(euda_npss) %in% "Year"]),
        cumulative_sum_others = cumsum(sum_others)
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

# Pick only the data for the Netherlands
euda_mdma_trend <- euda_mdma_trend[euda_mdma_trend$Country == "Netherlands", ]

# Drop the first two columns
euda_mdma_trend <- euda_mdma_trend |>
    dplyr::select(-Country, -`Geographical Area`) |>
    tidyr::pivot_longer(
        cols = everything(),
        names_to = "year",
        values_to = "rates"
    )

# Convert years to integer
euda_mdma_trend$year <- as.integer(euda_mdma_trend$year)

# Filter the data for the years of interest
euda_mdma_trend_recent <- euda_mdma_trend[
    (euda_mdma_trend$year >= 2015) & (euda_mdma_trend$year <= 2022),
]

# ---- 4.5. Google Trends ------------------------------------------------------

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

# Filter the data for the years of interest
google_trends_restricted <- google_trends |>
    dplyr::filter(
        year_month >= "2015-01" & year_month <= "2019-01"
    )

# 5. Plotting ------------------------------------------------------------------

# --- 5.1. Antenne reports -----------------------------------------------------

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
        slides = TRUE,
        slides_setts = c(26, 22, 16)
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
        width = 15,
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

# mdma_plot_wline <- samples_plots_list$MDMA + annotate(
#     "rect",
#     xmin = 2014,
#     xmax = 2016,
#     ymin = 0,
#     ymax = 3600,
#     alpha = .1,
#     fill = "#538a95"
# )

mdma_plot_wline <- samples_plots_list$MDMA + geom_vline(
    xintercept = 2015,
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
    slides = TRUE,
    slides_setts = c(26, 22, 16)
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
    slides = TRUE,
    slides_setts = c(26, 22, 16)
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
    y_steps = 500,
    slides_setts = c(36, 32, 16)
)

# Save other plots
ggsave(
    file.path(
        directory_path,
        paste0(results_location, "total_samples_", "cocaine_wline", ".png")
    ),
    plot = cocaine_plot_wline,
    width = 15,
    height = 8,
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "total_samples_", "mdma_wline", ".png")
    ),
    plot = mdma_plot_wline,
    width = 15,
    height = 8,
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "total_samples_", "comparison", ".png")
    ),
    plot = compared_samples_plot,
    width = 15,
    height = 8,
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "total_samples_", "nps_synt", ".png")
    ),
    plot = synt_plot,
    width = 15,
    height = 8,
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "samples_submitted_2023.png")
    ),
    plot = testservice_total_plot,
    width = 15,
    height = 8,
    dpi = 150
)

# --- 5.2. National reports ----------------------------------------------------

# Select the substances to plot
unique_names <- unique(incidents_hospitals$drug)
dropped_substances <- c("Ketamine", "Gas", "34MMC", "Opioids (synthetic)")
complete_substances <- unique_names[!unique_names %in% dropped_substances]

# Create lists to store the plots
hosp_plots_list <- list()
hosp_plots_severity_list <- list()

for (substance in complete_substances) {
    # Plot the of hospitalizations per drug
    hospitalizations_plot <- plot_series(
        incidents_hospitals[incidents_hospitals$drug == substance, ],
        "year",
        "incidents",
        colors = "#565175",
        title = " ",
        y_label = "Hospitalizations",
        y_top = hospitalizations_y_axis_specs[[substance]]$y_top,
        y_steps = hospitalizations_y_axis_specs[[substance]]$y_steps,
        slides = TRUE,
        slides_setts = c(26, 22, 16)
    )

    # Plot the severity of hospitalizations per drug
    hospitalizations_severity_plot <- plot_series(
        incidents_hospitals[incidents_hospitals$drug == substance, ],
        "year",
        c("Light", "Moderate", "Severe"),
        colors = c("#565175", "#67b79e", "#ffb727"),
        title = " ",
        y_label = "Hospitalizations",
        y_top = hospitalizations_y_axis_specs[[substance]]$y_top,
        y_steps = hospitalizations_y_axis_specs[[substance]]$y_steps,
        legend_position = "top",
        slides = TRUE,
        slides_setts = c(26, 22, 16)
    )

    # Store the plot
    hosp_plots_list[[substance]] <- hospitalizations_plot
    hosp_plots_severity_list[[substance]] <- hospitalizations_severity_plot

    # Save the plots
    ggsave(
        file.path(
            directory_path,
            paste0(results_location, "hosps_", substance, ".png")
        ),
        plot = hospitalizations_plot,
        width = 15,
        height = 8,
        dpi = 150
    )

    ggsave(
        file.path(
            directory_path,
            paste0(results_location, "hosps_", substance, "_severity.png")
        ),
        plot = hospitalizations_severity_plot,
        width = 15,
        height = 8,
        dpi = 150
    )

}

# --- 5.3. De Telegraaf --------------------------------------------------------

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
    slides = TRUE,
    slides_setts = c(26, 22, 20)
)

# Save the plot
ggsave(
    file.path(
        directory_path,
        paste0(results_location, "news_presence_yearly.png", sep = "/")
    ),
    plot = telegraaf_presence,
    width = 15,
    height = 8,
    dpi = 150
)

# --- 5.4. EUDA data -----------------------------------------------------------

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
    slides = TRUE,
    slides_setts = c(26, 22, 16)
)

# Number of detected NPS by year, cumulative
euda_new_substances_cum <- plot_series(
    euda_npss,
    x_var = "year",
    y_vars = "cumulative_sum_others",
    colors = "#565175",
    title = " ",
    y_label = "Number of NPS",
    y_top = 5000,
    y_steps = 500,
    slides = TRUE,
    slides_setts = c(26, 22, 16)
)

# Last year prevalence of ecstasy use, 15-24 years old
euda_mdma_plot <- bar_chart_plot(
    euda_mdma,
    "Country",
    "Total",
    "highlight",
    colors = c("highlight" = "#538a95", "normal" = "#565175"),
    title,
    y_label = "Share (%)",
    y_top = 11,
    y_steps = 1,
    slides_setts = c(36, 32, 16)
)

euda_mdma_trend <- plot_series(
    euda_mdma_trend_recent,
    x_var = "year",
    y_vars = "rates",
    colors = "#565175",
    title = " ",
    y_label = "Last year prevalence (%)",
    y_top = 10,
    y_steps = 1,
    slides = TRUE
)

# Save the plots
ggsave(
    file.path(
        directory_path,
        paste0(results_location, "euda_new_substances.png", sep = "/")
    ),
    plot = euda_new_substances,
    width = 12,
    height = 9, #
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "euda_new_substances_cum.png", sep = "/")
    ),
    plot = euda_new_substances_cum,
    width = 12,
    height = 9, #
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "euda_mdma_rates.png", sep = "/")
    ),
    plot = euda_mdma_plot,
    width = 15,
    height = 8,
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "euda_mdma_rates_trend.png", sep = "/")
    ),
    plot = euda_mdma_trend,
    width = 15,
    height = 8,
    dpi = 150
)

# --- 5.5. Google Trends -------------------------------------------------------

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
    legend_position = "top",
    slides_setts = c(26, 22, 16)
) + geom_vline(
    xintercept = as.Date("2016-10-01"),
    linetype = "dashed",
    color = "black",
    linewidth = 1.5
)

google_trends_plot_restricted <- plot_series(
    google_trends_restricted,
    "year_month_date",
    c("MDMA", "Cocaine", "Heroin", "Hashish"),
    colors = c("#67b79e", "#e4491c", "#ffb727", "#565175"),
    title = " ",
    y_label = "Trend index",
    y_top = 100,
    y_steps = 10,
    x_steps = 128,
    slides = TRUE,
    slides_setts = c(26, 22, 20),
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

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "google_trends_restricted.png", sep = "/")
    ),
    plot = google_trends_plot_restricted,
    width = 15,
    height = 8,
    dpi = 150
)