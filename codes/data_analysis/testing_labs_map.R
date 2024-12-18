library(sf)

# Load the Netherlands shapefile and set CRS
netherlands <- st_read(
    "./data/source/polygons/wijkenbuurten_2024_v1.gpkg",
    layer = "buurten"
)
netherlands <- st_transform(netherlands, crs = 4326)

# Filter out water areas
netherlands_nowater <- netherlands |> filter(water != "JA")

# Load the testing facilities data and convert to sf object
test_fac <- read.csv(
    "./data/source/testing_facilities/drug_testing_facilities.csv"
)

test_fac <- st_as_sf(
    test_fac,
    coords = c("longitude", "latitude"),
    crs = 4326
)

# Plot the data
dutch_map <- ggplot() +
    geom_sf(
        data = netherlands_nowater,
        fill = "#538a95",
        color = "white",
        size = 0.05
    ) +
    geom_sf(
        data = test_fac,
        color = "#565175",
        size = 5
    ) +
    theme_void()

ggsave(
    filename = "results/figures/descriptives/drug_testing_facilities_map.png",
    plot = dutch_map,
    dpi = 600,
    height = 8,
    width = 8
)
