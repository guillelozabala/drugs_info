
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

# Limit output size in terminal
options(max.print = 200)

# 3. Define File Paths  --------------------------------------------------------

# From Simulations:
simulations_location <- "data/processed/simulations/"
simulations_path_1 <- file.path(
    directory_path,
    paste0(
        simulations_location,
        "simulated_data_simple_1.csv"
    )
)

# 4. Load Specifications -------------------------------------------------------

# 5. Load Data ----------------------------------------------------------------

# From the simulations:
simul_1 <- read.csv(simulations_path_1)

# 6. Data Preprocessing --------------------------------------------------------

mean_sd_hosps <- simul_1 |>
    group_by(cluster_treated, time) |>
    summarize(
        mean_hosps = mean(hospitalizations_per_capita, na.rm = TRUE),
        sd_hosps = sd(hospitalizations_per_capita, na.rm = TRUE),
        count_hosps = n()
    )

mean_sd_hosps <- mean_sd_hosps |>
    pivot_wider(
        names_from = cluster_treated,
        values_from = c(mean_hosps, sd_hosps, count_hosps),
        names_prefix = "cluster_"
    )

mean_sd_hosps <- mean_sd_hosps |>
    mutate(
        ci_l_c0 = mean_hosps_cluster_0 - 1.96 * sd_hosps_cluster_0/sqrt(count_hosps_cluster_0),
        ci_u_c0  = mean_hosps_cluster_0 + 1.96 * sd_hosps_cluster_0/sqrt(count_hosps_cluster_0),
        ci_l_c1 = mean_hosps_cluster_1 - 1.96 * sd_hosps_cluster_1/sqrt(count_hosps_cluster_1),
        ci_u_c1 = mean_hosps_cluster_1 + 1.96 * sd_hosps_cluster_1/sqrt(count_hosps_cluster_1)
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

simulated_1 <- plot_series(
    mean_sd_hosps,
    x_var = "time",
    y_vars = c("mean_hosps_cluster_0", "mean_hosps_cluster_1"),
    colors = c("#565175", "#67b79e"),
    title = " ",
    y_label = "ala",
    y_top = 0.004,
    y_min = 0,
    y_steps = 0.00025,
    slides = TRUE
    ) +
    geom_errorbar(
        aes(ymin = ci_l_c0, ymax = ci_u_c0), 
        width = 0.4,
        linewidth = 1,
        alpha = 0.4,
        color = "#565175"
    ) +
    geom_errorbar(
        aes(ymin = ci_l_c1, ymax = ci_u_c1),
        width = 0.4,
        linewidth = 1,
        alpha = 0.4,
        color = "#67b79e"
    )
