plot_series <- function(
    data,
    x_var,
    y_vars,
    colors = NULL,
    title,
    y_label,
    y_top,
    y_steps
) {
    # Convert data to long format if y_vars has multiple columns
    data_long <- data |>
        tidyr::pivot_longer(
            cols = dplyr::all_of(y_vars),
            names_to = "series",
            values_to = "value"
        )

    # Set colors if not provided
    if (is.null(colors)) {
        colors <- scales::hue_pal()(length(y_vars))  # Default color palette
    }

    # Obtain the range of x values
    years <- data[[x_var]] |> unique() |> sort()
    x_init <- years[1]
    x_end <- years[length(years)]

    # Create ggplot line plot
    p <- data_long |>
        ggplot2::ggplot(aes(x = .data[[x_var]], y = value, color = series)) +
        geom_line(size = 1.1) +
        geom_point(size = 4) +
        scale_color_manual(values = colors) +
        labs(title = title, x = " ", y = y_label) +
        theme_minimal() +
        theme(
            plot.title = element_text(
                hjust = 0.5,
                size = 24,
                face = "bold",
                margin = margin(b = 20)
            ),
            axis.title.x = element_text(
                size = 14,
                face = "bold"
            ),
            axis.title.y = element_text(
                size = 14,
                face = "bold"
            ),
            axis.text = element_text(size = 12),
            panel.grid.major = element_line(color = "grey80"),
            panel.grid.minor = element_blank(),
            axis.text.x = element_text(
                angle = 45,
                hjust = 1
            )
        ) +
        scale_x_continuous(breaks = seq(x_init, x_end, by = 1)) +
        scale_y_continuous(
            breaks = seq(0, y_top, by = y_steps),
            limits = c(0, y_top),
            expand = c(0, 0)
        )

    return(p)
}

plot_cumulative_flows <- function(data,
    x_var,
    y_vars,
    title,
    y_label,
    y_top,
    y_steps
) {
    # Convert data to long format if y_vars has multiple columns
    data_long <- data |>
        tidyr::pivot_longer(
            cols = dplyr::all_of(y_vars),
            names_to = "series",
            values_to = "value"
        )

    # Sort descending
    data_long <- data_long |>
        dplyr::group_by(!!sym(x_var)) |>
        dplyr::mutate(series = fct_reorder(series, value, .desc = TRUE))

    # Obtain the range of x values
    years <- data[[x_var]] |> unique() |> sort()
    x_init <- years[1]
    x_end <- years[length(years)]

    # Create ggplot line plot
    p <- data_long |>
        ggplot2::ggplot(aes(x = .data[[x_var]], y = value, fill = series)) +
        geom_area(position = "stack", alpha = 1) +
        labs(title = title, x = " ", y = y_label) +
        theme_minimal() +
        theme(
            plot.title = element_text(
                hjust = 0.5,
                size = 24,
                face = "bold",
                margin = margin(b = 20)
            ),
            axis.title.x = element_text(
                size = 14,
                face = "bold"
            ),
            axis.title.y = element_text(
                size = 14,
                face = "bold"
            ),
            axis.text = element_text(size = 12),
            panel.grid.major = element_line(color = "grey80"),
            panel.grid.minor = element_blank(),
            axis.text.x = element_text(
                angle = 45,
                hjust = 1
            )
        ) +
        scale_x_continuous(breaks = seq(x_init, x_end, by = 1)) +
        scale_y_continuous(
            breaks = seq(0, y_top, by = y_steps),
            limits = c(0, y_top),
            expand = c(0, 0)
        )

    return(p)
}
