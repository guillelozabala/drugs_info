from pytrends.request import TrendReq
import pandas as pd
import time

pytrends = TrendReq(hl='en-US', tz=360)

keywords = ["MDMA", "Cocaine", "Weed"]  # adjust keywords as you wish
timeframe = '2004-01-01 ' + pd.Timestamp.today().strftime('%Y-%m-%d')
geo = 'NL'  # Netherlands

# 1. Interest over time for NL
pytrends.build_payload(kw_list=keywords, timeframe=timeframe, geo=geo, gprop='')
df_time = pytrends.interest_over_time()
# df_time.to_csv("trends_nl_drugs_time.csv")

# 2. Interest by sub-region (provinces / regions) — note: may need to loop over keywords individually
regional_dfs = {}
for kw in keywords:
    pytrends.build_payload(kw_list=[kw], timeframe=timeframe, geo=geo, gprop='')
    df_region = pytrends.interest_by_region(resolution='REGION', inc_low_vol=True, inc_geo_code=True)
    regional_dfs[kw] = df_region
    # optionally save
    df_region.to_csv(f"trends_nl_{kw}_by_region.csv")
    time.sleep(1)  # polite delay
