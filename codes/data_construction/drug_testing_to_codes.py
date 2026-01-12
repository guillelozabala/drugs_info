import pandas as pd
import geopandas as gpd
from shapely.geometry import Point

# Load CSV
df_csv = pd.read_csv("data/source/testing_facilities/drug_testing_facilities.csv")

# Load GPKG
gdf = gpd.read_file("data/source/polygons/wijkenbuurten_2024_v1.gpkg")

points = gpd.GeoDataFrame(
    df_csv,
    geometry=gpd.points_from_xy(df_csv.longitude, df_csv.latitude),
    crs="EPSG:4326"    # WGS84
)


gdf.crs # <Projected CRS: EPSG:28992>


points = points.to_crs(gdf.crs)


joined = gpd.sjoin(points, gdf, how="left", predicate="within")
joined = joined[
    ['name','type','organization','city','address','latitude','longitude',
     'constant_adress','date','mail','phone_number','geometry','index_right',
     'buurtcode','buurtnaam','wijkcode','gemeentecode','gemeentenaam',
     'jrstatcode','jaar']
]




joined.to_csv("data/intermediate/other/joined_output.csv", index=False)