import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt

netherlands = gpd.read_file(r'./data/source/polygons/wijkenbuurten_2024_v1.gpkg', layer='buurten')
netherlands = netherlands.to_crs(4326)
netherlands_nowater = netherlands[netherlands['water'] != 'JA']

test_fac = pd.read_csv(r'./data/source/testing_facilities/drug_testing_facilities.csv')
test_fac = gpd.GeoDataFrame(
    test_fac,
    geometry = gpd.points_from_xy(
        x = test_fac.longitude,
        y = test_fac.latitude,
        crs = 'EPSG:4326',
    )
)

fig, ax = plt.subplots()
netherlands_nowater.plot(ax=ax, color='#538a95', edgecolor='white', linewidth=0.15)
test_fac.plot(ax=ax, color='#565175', markersize=20)

plt.axis('off')
plt.savefig(r'./results/figures/descriptives/drug_testing_facilities_map.png', dpi=600, bbox_inches='tight')