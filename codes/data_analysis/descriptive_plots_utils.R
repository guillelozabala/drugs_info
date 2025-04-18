
# Plot results of the doses (range, volatility and prices)
testing_doses_plots <- function(
    file,
    y_axis_values,
    directory_path,
    slides = FALSE
) {

    # Read the data
    df <- read.csv(file)

    # Extract the name of the drug
    substance <- extract_name(file)

    # Rename the columns for the legends
    df_plots <- df |>
        dplyr::rename(
            "Minimum dosis" = "dose_min",
            "Maximum dosis" = "dose_max",
            "Mean dosis" = "dose_mean"
        )

    # Path to save the results
    save_path <- "results/figures/descriptives/"

    # Initialize the list to store the plots
    plots <- list()

    # Initialize the list to store the results
    results_paths <- list()

    # Extract the y-axis specifications
    y_specs_range <- y_axis_values[["doses_range"]][[substance]]

    # Plot the range of doses (maximum, minimum and mean)
    plots[[1]] <- plot_series(
        df_plots,
        y_vars = c("Minimum dosis", "Maximum dosis", "Mean dosis"),
        colors = c("#538a95", "#565175", "#67b79e"),
        title = " ",
        y_label = "Milligrams",
        y_top = y_specs_range$y_top,
        y_steps = y_specs_range$y_steps,
        legend_position = "top",
        slides = slides,
        slides_setts = c(26, 22, 20)
    )

    # Set the path to save the results
    results_paths[[1]] <- paste0(save_path, "range_doses_", substance, ".png")

    # Extract the y-axis specifications
    y_specs_sd <-  y_axis_values[["doses_sd"]][[substance]]

    # Plot the volatility of the doses
    plots[[2]] <- plot_series(
        df_plots,
        y_vars = "dose_sd", # "adj_volatility" 
        colors = "#538a95",
        title = " ",
        y_label = "Standard deviation (mg)", # "Volatility (mg)"
        y_top = y_specs_sd$y_top, # y_specs_volatility$y_top,
        y_steps = y_specs_sd$y_steps, #y_specs_volatility$y_steps,
        slides = slides,
        slides_setts = c(26, 22, 20)
    )

    # Set the path to save the results
    results_paths[[2]] <- paste0(save_path, "sd_", substance, ".png")

    # Check if the data contains price information
    price_tags <- c("price_per_gram", "price_per_pill", "price_per_tab")

    if (any(price_tags %in% colnames(df_plots))) {

        # Extract the price tag
        price_tag <- price_tags[price_tags %in% colnames(df_plots)]

        # Extract the y-axis specifications
        y_specs_prices_unit <- y_axis_values[["doses_prices"]][[substance]]

        # Extract the starting point of the data
        start_data <- which(!is.na(df_plots[[price_tag]])) |> min()

        # Plot the price per unit of the doses
        plots[[3]] <- plot_series(
            df_plots[start_data:nrow(df_plots), ],
            y_vars = price_tag,
            colors = "#67b79e",
            title = " ",
            y_label = "€",
            y_top = y_specs_prices_unit$y_top,
            y_steps = y_specs_prices_unit$y_steps,
            slides = slides,
            slides_setts = c(26, 22, 20)
        )

        # Set the path to save the results
        results_paths[[3]] <- paste0(save_path, "unit_p_", substance, ".png")

    }

    # Check if the data contains price per milligram information
    if ("price_per_mg" %in% colnames(df_plots)) {

        # Extract the y-axis specifications
        y_specs_prices_mgs <- y_axis_values[["doses_prices_mgs"]][[substance]]

        # Extract the starting point of the data
        start_data_mg <- which(!is.na(df_plots[["price_per_mg"]])) |> min()

        # Plot the price per milligram of the doses
        plots[[4]] <- plot_series(
            df_plots[start_data_mg:nrow(df_plots), ],
            y_vars = "price_per_mg",
            colors = "#67b79e",
            title = " ",
            y_label = "€/mg",
            y_top = y_specs_prices_mgs$y_top,
            y_steps = y_specs_prices_mgs$y_steps,
            slides = slides,
            slides_setts = c(26, 22, 20)
        )

        # Set the path to save the results
        results_paths[[4]] <- paste0(save_path, "mg_p_", substance, ".png")

    }

    # Save the plots
    for (figure in seq_along(plots)) {
        ggsave(
            file.path(directory_path, results_paths[[figure]]),
            plot = plots[[figure]],
            width = 15,
            height = 8,
            dpi = 150
        )
    }
}

# Obtain line plots
plot_series <- function(
    data,
    x_var = "year",
    y_vars,
    colors = NULL,
    title,
    y_label,
    y_top,
    y_min = 0,
    y_steps,
    x_steps = 1,
    legend_position = "none",
    years_custom_range = TRUE,
    slides = FALSE,
    slides_setts = c(16, 11, 16)
) {
    # Convert data to long format if y_vars has multiple columns
    data_long <- data_long(data, y_vars)

    # Set colors if not provided
    if (is.null(colors)) {
        colors <- scales::hue_pal()(length(y_vars))  # Default color palette
    }

    # Obtain the range of x values
    years <- x_axis_custom_range(data, x_var)

    if (years_custom_range) {
        # Obtain the range of x values
        years_custom <- scale_x_continuous(
            breaks = seq(years[1], years[2], by = x_steps),
            limits = c(years[1], years[2]),
            expand = c(0, 0.5)
        )
    } else {
        years_custom <- NULL
    }

    # Obtain the range of x values
    years <- x_axis_custom_range(data, x_var)

    # Create ggplot line plot
    p <- data_long |>
        ggplot2::ggplot(
            aes(x = .data[[x_var]], y = value, color = series)
        ) +
        geom_line(linewidth = 1.1) +
        geom_point(size = 4) +
        scale_color_manual(values = colors) +
        labs(title = title, x = " ", y = y_label, col = NULL) +
        dims_theme(legend_position, slides, slides_setts) +
        years_custom +
        scale_y_continuous(
            breaks = seq(y_min, y_top, by = y_steps),
            limits = c(y_min, y_top),
            expand = c(0, 0)
        )

    return(p)
}

# Common features for the plots
dims_theme <- function(legend_position, slides, slides_setts) {

    if (slides == TRUE) {
        font_plot <- "Palatino"
    } else {
        font_plot <- "sans"
    }

    theme_minimal() +
    theme(
        plot.title = element_text(
            hjust = 0.5,
            size = 18,
            face = "bold",
            margin = margin(b = 20)
        ),
        axis.title.x = element_text(
            #size = 14,
            size = slides_setts[1] * (slides) + 18,
            face = "bold"
        ),
        axis.title.y = element_text(
            size = slides_setts[1] * (slides) + 18,
            margin = margin(r = 20)
        ),
        axis.text = element_text(size = slides_setts[2] * (slides) + 16),
        panel.grid.major = element_line(color = "grey80"),
        panel.grid.minor = element_blank(),
        axis.text.x = element_text(
            angle = 45,
            hjust = 1
        ),
        legend.position = legend_position,
        text = element_text(size = 16, family = font_plot),
        legend.text = element_text(size = slides_setts[3] * (slides) + 16),
        legend.key.size = unit(1.5, "lines")
    )

}

# Obtain bar charts
bar_chart_plot <- function(
    data,
    x_var,
    y_var,
    highlight,
    colors = NULL,
    title,
    y_label,
    y_top,
    y_steps,
    slides_setts = c(25, 25, 12)
) {

    bar_chart <- data |>
        ggplot(
            ggplot2::aes(
                x = reorder(!!rlang::sym(x_var), -!!rlang::sym(y_var)),
                y = !!rlang::sym(y_var),
                fill = highlight
            )
        ) +
        geom_bar(stat = "identity") +
        scale_fill_manual(
            values = colors
        ) +
        theme_minimal() +
        theme(
            plot.title = element_text(
                hjust = 0.5,
                size = 18,
                face = "bold",
                margin = margin(b = 20)
            ),
            axis.title.x = element_text(
                size = 18,
                face = "bold"
            ),
            axis.title.y = element_text(
                size = slides_setts[1],
                margin = margin(r = 20)
            ),
            axis.text = element_text(size = slides_setts[2]),
            panel.grid.major = element_line(color = "grey80"),
            panel.grid.minor = element_blank(),
            axis.text.x = element_text(
                angle = 45,
                hjust = 1
            ),
            legend.position = "none",
            text = element_text(size = slides_setts[3], family ="Palatino"),
            legend.text = element_text(size = 12),
            legend.key.size = unit(1.5, "lines")
        ) +
        labs(
            title = " ",
            x = "",
            y = y_label
        ) +
        scale_y_continuous(
            breaks = seq(0, y_top, by = y_steps),
            limits = c(0, y_top),
            expand = c(0, 0)
        )

    return(bar_chart)
}

# Convert data to long format
data_long <- function(data, y_vars) {

    data_long <- data |>
        tidyr::pivot_longer(
            cols = dplyr::all_of(y_vars),
            names_to = "series",
            values_to = "value"
        )

    return(data_long)
}

# Obtain the range of x values
x_axis_custom_range <- function(data, x_var) {

    years <- data[[x_var]] |> unique() |> sort()
    x_init <- years[1]
    x_end <- years[length(years)]

    return(c(x_init, x_end))
}

# Obtain the list of CSV files in a directory that contain a keyword
get_csv_files <- function(directory, keyword) {
    files <- list.files(
        directory,
        pattern = paste0(".*", keyword, ".*\\.csv$"),
        full.names = TRUE
    )
    return(files)
}

# Extract the name from the file path
extract_name <- function(file_path) {
    pattern <- ".*/(.*)_dosering_2023\\.csv"
    name <- sub(pattern, "\\1", file_path)
    return(name)
}