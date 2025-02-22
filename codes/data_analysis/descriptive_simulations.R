
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



# 9. Create Dataset ------------------------------------------------------------

options(max.print = 1000)

df_a <- tibble(
    t = -50:50,
    baseline = 1,
    area = "A"
)

df_b <- tibble(
    t = -50:50,
    baseline = 1/2,
    area = "B"
)

# Add the 'faulty' variable
df_a <- df_a |>
    mutate(faulty = case_when(
        t < -20 ~ baseline,
        t >= -20 & t <= 0 ~ baseline + (t + 20) * 0.025,
        t > 0 & t <= 10 ~ baseline + 20 * 0.025 - t * 0.075,
        t > 10 ~ baseline + 20 * 0.025 - 10 * 0.075
    ))

df_b <- df_b |>
    mutate(faulty = baseline) |>
    mutate(under_assumptions = ifelse(
        between(t, -20, 0), baseline + (t + 20)*0.025, NA)
    ) |>
    mutate(under_assumptions_b = ifelse(
        between(t, -15, 0), baseline + (t + 15)*0.025, NA)
    )

# Combine the two datasets
df <- bind_rows(df_a, df_b)
# df <- merge(df_a, df_b, by = "t")


df <- df |>
    mutate(faulty_noisy = faulty + rnorm(n(), 0, 0.05))

library(ocp)
# view the data
ocpd1 <- onlineCPD(df[df$area == "A", ]$faulty_noisy)
# view results
ocpd1

plot_1 <- df |> ggplot() +
    geom_line(aes(x = t, y = faulty_noisy, color = area), linewidth = 1.1) +
    dims_theme("none", TRUE, c(26, 22, 16)) +
    # theme_minimal() +
    # theme(legend.position = "none") +
    labs(
        title = " ",
        x = "t",
        y = "Hospitalizations"
    ) +
    scale_color_manual(values = c("#565175", "#67b79e")) +
    scale_x_continuous(breaks = seq(-50, 50, 10)) +
    scale_y_continuous(limits = c(0, 2), breaks = seq(0, 2, 0.5)) +
    geom_vline(
        xintercept = 0,
        linetype = "dashed",
        color = "black",
        linewidth = 1.1
    )

plot_2 <- df |> ggplot() +
    geom_line(aes(x = t, y = faulty_noisy, color = area), linewidth = 1.1, show.legend = FALSE) +
    dims_theme("none", TRUE, c(26, 22, 16)) +
    theme(legend.position = "top") +
    labs(
        title = " ",
        x = "t",
        y = "Hospitalizations",
        linetype = "Changepoints"
    ) +
    scale_color_manual(values = c("#565175", "#67b79e")) +
    scale_x_continuous(breaks = seq(-50, 50, 10)) +
    scale_y_continuous(limits = c(0, 2), breaks = seq(0, 2, 0.5)) +
    
    # First vertical line (excluded from legend)
    geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 1.1) +
    
    # Last two vertical lines mapped to linetype
    geom_vline(aes(xintercept = ocpd1$changepoint_lists$maxCPs[[1]][2] - 50, linetype = "Prediction"),
               color = "#e4491c", linewidth = 1.1) +
    geom_vline(aes(xintercept = -20, linetype = "Actual"),
               color = "#ffb727", linewidth = 1.1) +
    
    # Define linetype scale to create the legend
    scale_linetype_manual(values = c("Prediction" = "dashed", "Actual" = "dashed")) +
    theme(legend.title=element_blank())

plot_3 <- df |> ggplot() +
    geom_line(
        aes(x = t, y = under_assumptions, color = area),
        linewidth = 1.1,
        linetype = "dashed", show.legend = FALSE) +
    geom_line(
        aes(x = t, y = under_assumptions_b, color = area,),
        linewidth = 1.1,
        linetype = "dashed", show.legend = FALSE) +
    geom_line(aes(x = t, y = faulty_noisy, color = area), linewidth = 1.1, show.legend = FALSE) +
    dims_theme("none", TRUE, c(26, 22, 16)) +
    theme(legend.position = "top") +
    labs(
        title = " ",
        x = "t",
        y = "Hospitalizations",
        linetype = "Changepoints"
    ) +
    scale_color_manual(values = c("#565175", "#67b79e")) +
    scale_x_continuous(breaks = seq(-50, 50, 10)) +
    scale_y_continuous(limits = c(0, 2), breaks = seq(0, 2, 0.5)) +
    
    # First vertical line (excluded from legend)
    geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 1.1) +
    
    # Last two vertical lines mapped to linetype
    geom_vline(aes(xintercept = ocpd1$changepoint_lists$maxCPs[[1]][2] - 50, linetype = "Prediction"),
               color = "#e4491c", linewidth = 1.1) +
    geom_vline(aes(xintercept = -20, linetype = "Actual"),
               color = "#ffb727", linewidth = 1.1) +
    
    # Define linetype scale to create the legend
    scale_linetype_manual(values = c("Prediction" = "dashed", "Actual" = "dashed")) +
    theme(legend.title=element_blank())

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "simulation_1.png", sep = "/")
    ),
    plot = plot_1,
    width = 15,
    height = 8,
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "simulation_2.png", sep = "/")
    ),
    plot = plot_2,
    width = 15,
    height = 8,
    dpi = 150
)

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "simulation_3.png", sep = "/")
    ),
    plot = plot_3,
    width = 15,
    height = 8,
    dpi = 150
)



dg_a <- tibble(
    t = -50:50,
    baseline = 1,
    area = "A"
)

dg_b <- tibble(
    t = -50:50,
    baseline = 1/2,
    area = "B"
)

# Add the 'faulty' variable
dg_a <- dg_a |>
    mutate(faulty = case_when(
        t <= 0 ~ baseline,
        t > 0 & t <= 5 ~ baseline - t * 0.075,
        t > 5 ~ baseline - 5 * 0.075
    ))

dg_b <- dg_b |>
    mutate(faulty = baseline)

# Combine the two datasets
dg <- bind_rows(dg_a, dg_b)

dg <- dg |> mutate(faulty_noisy = faulty + rnorm(n(), 0, 0.05))

plot_a_1 <- dg |> ggplot() +
    geom_line(aes(x = t, y = faulty_noisy, color = area), linewidth = 1.1) +
    dims_theme("none", TRUE, c(26, 22, 16)) +
    # theme_minimal() +
    # theme(legend.position = "none") +
    labs(
        title = " ",
        x = "t",
        y = "Hospitalizations"
    ) +
    scale_color_manual(values = c("#565175", "#67b79e")) +
    scale_x_continuous(breaks = seq(-50, 50, 10)) +
    scale_y_continuous(limits = c(0, 2), breaks = seq(0, 2, 0.5)) +
    geom_vline(
        xintercept = 0,
        linetype = "dashed",
        color = "black",
        linewidth = 1.1
    )

ggsave(
    file.path(
        directory_path,
        paste0(results_location, "simulation_1a.png", sep = "/")
    ),
    plot = plot_a_1,
    width = 15,
    height = 8,
    dpi = 150
)


df_c <- df_a

df_c <- df_c |>
    mutate(area = "C") |>
    mutate(baseline = 0.75) |>
    mutate(faulty = case_when(
        t < 30 ~ baseline,
        t >= 30 & t <= 50 ~ baseline + (t - 30) * 0.01,
        t > 50 & t <= 75 ~ baseline + 20 * 0.01 - (t - 50) * 0.01,
        t > 75 ~ baseline + 20 * 0.01 - (75 - 50) * 0.01
        )
    ) |>
    mutate(faulty_noisy = faulty + rnorm(n(), 0, 0.05))

df_new <- bind_rows(df, df_c)

df_new |> ggplot() +
    geom_line(
        aes(x = t, y = under_assumptions, color = area),
        linewidth = 1.1,
        linetype = "dashed") +
    geom_line(aes(x = t, y = faulty_noisy, color = area), linewidth = 1.1) +
    theme_minimal() +
    theme(legend.position = "none") +
    labs(
        title = " ",
        x = "Time",
        y = "Hospitalizations"
    ) +
    scale_color_manual(values = c("#565175", "#67b79e", "blue")) +
    scale_x_continuous(breaks = seq(0, 100, 10)) +
    scale_y_continuous(limits = c(0, 2), breaks = seq(0, 2, 0.5)) +
    geom_vline(
        xintercept = 50,
        linetype = "dashed",
        color = "black",
        linewidth = 1.1
    ) +
    geom_vline(
        xintercept = 30,
        linetype = "dashed",
        color = "red",
        linewidth = 1.1
    )


library(ocp)
# view the data
ocpd1 <- onlineCPD(df[df$area == "A", ]$faulty_noisy)
# view results
ocpd1

ocpd1$changepoint_lists$maxCPs[[1]]


plot(df[df$area == "A", ]$faulty_noisy)
