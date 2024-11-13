
'''
preventie_indicatoren_dict = {
    '2003': list(range(289, 294)),
    '2004': list(range(189, 194)),
    '2005': list(range(256, 262)),
    '2006': list(range(216, 222)),
    '2007': list(range(297, 303)),
    '2008': list(range(226, 233)), 
    '2009': list(range(206, 213)),
    '2010': list(range(255, 263)),
    '2011': list(range(305, 312)),
    '2012': list(range(189, 195)),
    '2013': list(range(215, 219)),
    '2014': list(range(225, 227)),
    '2015': list(range(239, 242)),
    '2016': list(range(259, 261)),
    '2017': list(range(293, 297)),
    '2018': list(range(258, 271)),
    '2019': list(range(236, 246)),
    '2020': list(range(279, 285)),
    '2021': list(range(246, 252)),
    '2022': list(range(266, 277)),
    '2023': list(range(225, 236))
}

'''

# CHECK HISTORIC RECORDS

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load the CSV file
preventie_indicatoren = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/mdma_1.csv')
preventie_indicatoren

preventie_indicatoren[['dose_min', 'dose_max']] = preventie_indicatoren['dosering (min-max)'].str.split('-', expand=True)
preventie_indicatoren[['dose_mean', 'dose_sd']] = preventie_indicatoren['dosering (gemiddeld (sd))'].str.split(' ', expand=True)
preventie_indicatoren['dose_sd'] = preventie_indicatoren['dose_sd'].str.replace(r'[\(\)]', '', regex=True)
preventie_indicatoren['prijs per pil (gemiddeld)'] = preventie_indicatoren['prijs per pil (gemiddeld)'].str.replace(r'[€]', '', regex=True)
# Drop redundant columns
preventie_indicatoren.drop(columns=['dosering (min-max)', 'dosering (gemiddeld (sd))'], inplace=True)
# Rename the columns (N_pricing missing)
preventie_indicatoren.rename(columns={
    'jaar': 'year',
    'aantal': 'n_reports',
    'prijs per pil (gemiddeld)': 'price_per_pill'
    }, inplace=True)
    # Convert columns to numeric
preventie_indicatoren['dose_min'] = pd.to_numeric(preventie_indicatoren['dose_min'], errors='coerce')
preventie_indicatoren['dose_max'] = pd.to_numeric(preventie_indicatoren['dose_max'], errors='coerce')
preventie_indicatoren['dose_mean'] = pd.to_numeric(preventie_indicatoren['dose_mean'], errors='coerce')
preventie_indicatoren['dose_sd'] = pd.to_numeric(preventie_indicatoren['dose_sd'], errors='coerce')
preventie_indicatoren['price_per_pill'] = pd.to_numeric(preventie_indicatoren['price_per_pill'], errors='coerce')
preventie_indicatoren['adj_volatility'] = preventie_indicatoren['dose_sd'] * np.sqrt(preventie_indicatoren['n_reports'])
preventie_indicatoren['price_per_mg'] = preventie_indicatoren['price_per_pill'] / preventie_indicatoren['dose_mean']
preventie_indicatoren.to_csv(r'./data/processed/preventie_indicatoren_mdma.csv', index=False)


testservice = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2023/225_0.csv')
rows_to_drop = [0, 4, 16, 28] 
testservice = testservice.drop(index=rows_to_drop).reset_index(drop=True)
# Change the value of a specific cell using .iloc
# For example, change the value in the cell at row 2, column index 3 to 'new_value'
testservice.iloc[10, 2] = 35
testservice.iloc[6, 3] = 6
testservice.iloc[10, 3] = 39
testservice.iloc[17, 3] = 66
testservice.iloc[21, 3] = 138
testservice.iloc[28, 3] = 291

testservice.rename(columns={
    'Unnamed: 0': 'year',
    'Unnamed: 1': 'mdma',
    'Unnamed: 2': 'cocaine',
    'overig': 'amphetamine',
    'Unnamed: 3': 'ketamine',
    'Unnamed: 4': '2cb',
    'Unnamed: 5': '3mmc4mmc',
    'Unnamed: 6': '4fa',
    'Unnamed: 7': 'lsd',
    'Unnamed: 8': 'ghb',
    'Unnamed: 9': 'other',
    'Unnamed: 10': 'unknown',
    'Unnamed: 11': 'total'
    }, inplace=True)

# Define the threshold
threshold = 10
testservice['mdma'] = testservice['mdma'].apply(lambda x: x * 1000 if x < threshold else x)
testservice['total'] = testservice['total'].apply(lambda x: x * 1000 if x < threshold else x)
testservice = testservice.fillna(0).astype(int)
testservice.to_csv(r'./data/processed/225_0.csv', index=False)

xtc_profile_2003 = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2003/245_0.csv')
xtc_profile_2004 = "not available"
xtc_profile_2005 = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2005/231_0.csv')
xtc_profile_2006 = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2006/205_1.csv')
xtc_profile_2007 = "not available (2019)"
xtc_profile_2008 = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2008/200_0.csv')
xtc_profile_2009 = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2009/189_0.csv')
xtc_profile_2010 = "available, couldn't read it"
xtc_profile_2011 = "not available -> pooled stimulants"
xtc_profile_2012 = "not available -> pooled stimulants"
xtc_profile_2013 = "available, couldn't read it (204), pooled consumption"
xtc_profile_2014 = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2014/198_0.csv')
xtc_profile_2015 = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2015/209_0.csv')
xtc_profile_2016 = "available, couldn't read it (228)"
xtc_profile_2017 = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2017/249_1.csv')
xtc_profile_2018 = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2018/229_1.csv')
xtc_profile_2019 = "available, couldn't read it (230)"
xtc_profile_2020 = "not available -> corona studies"
xtc_profile_2021 = "not available"
xtc_profile_2022 = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2022/245_0.csv')
xtc_profile_2023 = pd.read_csv(r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2023/214_0.csv')

'''
2013 report
Prompted by a number of fatal accidents caused by white heroin sold as cocaine, the 
Amsterdam authorities launched a coke alert campaign in 2014 (it was discontinued in 
2015). The campaign had considerable impact in the nightlife scene. Mobile drug 
suppliers faced more questioning from clients about the purity of their products, and 
the drug checking service received significantly more cocaine submissions. None of 
this appeared to influence the scale of cocaine use, however. Prices remained stable 
at around 50 euros per gram. The purity of the submitted samples also remained 
stable, although levamisole adulteration has increased.
'''