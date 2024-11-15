plot_series <- function(
    data,
    x_var,
    y_vars,
    colors = NULL,
    title,
    y_label,
    y_top,
    y_steps,
    x_steps = 1,
    legend_position = "none"
) {
    # Convert data to long format if y_vars has multiple columns
    data_long <- data_long(data, y_vars)

    # Set colors if not provided
    if (is.null(colors)) {
        colors <- scales::hue_pal()(length(y_vars))  # Default color palette
    }

    # Obtain the range of x values
    years <- x_axis_custom_range(data, x_var)

    # Create ggplot line plot
    p <- data_long |>
        ggplot2::ggplot(aes(x = .data[[x_var]], y = value, color = series)) +
        geom_line(linewidth = 1.1) +
        geom_point(size = 4) +
        scale_color_manual(values = colors) +
        labs(title = title, x = " ", y = y_label, col = NULL) +
        dims_theme(legend_position) +
        scale_x_continuous(
            breaks = seq(years[1], years[2], by = x_steps),
            limits = c(years[1], years[2]),
            expand = c(0, 0.5)
        ) +
        scale_y_continuous(
            breaks = seq(0, y_top, by = y_steps),
            limits = c(0, y_top),
            expand = c(0, 0)
        )

    return(p)
}

dims_theme <- function(legend_position) {

    theme_minimal() +
    theme(
        plot.title = element_text(
            hjust = 0.5,
            size = 18,
            face = "bold",
            margin = margin(b = 20)
        ),
        axis.title.x = element_text(
            size = 14,
            face = "bold"
        ),
        axis.title.y = element_text(
            size = 14,
            #face = "bold"
            margin = margin(r = 20)
        ),
        axis.text = element_text(size = 12),
        panel.grid.major = element_line(color = "grey80"),
        panel.grid.minor = element_blank(),
        axis.text.x = element_text(
            angle = 45,
            hjust = 1
        ),
        legend.position = legend_position,
        text = element_text(size = 12, family = "sans"),
        legend.text = element_text(size = 12),
        legend.key.size = unit(1.5, "lines")
    )

}

data_long <- function(data, y_vars) {

    data_long <- data |>
        tidyr::pivot_longer(
            cols = dplyr::all_of(y_vars),
            names_to = "series",
            values_to = "value"
        )

    return(data_long)
}

x_axis_custom_range <- function(data, x_var) {

    years <- data[[x_var]] |> unique() |> sort()
    x_init <- years[1]
    x_end <- years[length(years)]

    return(c(x_init, x_end))
}