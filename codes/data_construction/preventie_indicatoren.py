
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
preventie_indicatoren

plt.figure(figsize=(10, 5))
plt.plot(preventie_indicatoren['year'], preventie_indicatoren['n_reports']) #, label='Minimum mgs')
#plt.axvline(x=2013, color='red', linestyle='--', label='Year 2013 (t = -1)')
plt.xlabel('Year')
plt.ylabel('Reports')
plt.title('Number of reports')
plt.xticks(np.arange(1994,2024, 1))
#plt.legend()
plt.show()

# Plot dose_min and dose_max over the years
plt.figure(figsize=(10, 5))
plt.plot(preventie_indicatoren['year'], preventie_indicatoren['dose_min'], label='Minimum mgs')
plt.plot(preventie_indicatoren['year'], preventie_indicatoren['dose_mean'], label='Mean mgs')
plt.plot(preventie_indicatoren['year'], preventie_indicatoren['dose_max'], label='Maximum mgs')
#plt.axvline(x=2013, color='red', linestyle='--', label='Year 2013 (t = -1)')
plt.xlabel('Year')
plt.ylabel('Mgs')
plt.title('XTC pills containing exclusively or mainly MDMA -- Dosage in milligrams')
plt.legend()
plt.show()

plt.figure(figsize=(10, 5))
plt.plot(preventie_indicatoren['year'], preventie_indicatoren['dose_sd'], label='Dose sd')
plt.axvline(x=2013, color='red', linestyle='--', label='Year 2013 (t = -1)')
plt.xlabel('Year')
plt.ylabel('Dose')
#plt.title('Dose Min and Max Over the Years')
plt.legend()
plt.show()

preventie_indicatoren['adj_volatility'] = preventie_indicatoren['dose_sd'] * np.sqrt(preventie_indicatoren['n_reports'])
plt.figure(figsize=(10, 5))
plt.plot(preventie_indicatoren['year'], preventie_indicatoren['adj_volatility'], label=r'$\sigma_{mg} * \sqrt{N}$')
#plt.axvline(x=2013, color='red', linestyle='--', label='Year 2013 (t = -1)')
plt.xlabel('Year')
plt.ylabel('Volatility')
plt.title('XTC pills containing exclusively or mainly MDMA -- Dosage volatility in milligrams')
plt.legend(loc='upper left')
plt.show()

# Plot price_per_pill over the years
plt.figure(figsize=(10, 5))
plt.plot(preventie_indicatoren['year'], preventie_indicatoren['price_per_pill'], label='Price Per Pill', color='green')
#plt.axvline(x=2013, color='red', linestyle='--', label='Year 2013 (t = -1)')
plt.xlabel('Year')
plt.ylabel('Price Per Pill (€)')
plt.title('Price Per XTC Pill in Euros')
plt.legend()
plt.show()

preventie_indicatoren['price_per_mg'] = preventie_indicatoren['price_per_pill'] / preventie_indicatoren['dose_mean']
plt.figure(figsize=(10, 5))
plt.plot(preventie_indicatoren['year'], preventie_indicatoren['price_per_mg'], label='Price Per Pill', color='green')
plt.axvline(x=2013, color='red', linestyle='--', label='Year 2013 (t = -1)')
plt.xlabel('Year')
plt.ylabel('Price per milligram (€)')
plt.title('Price Per XTC Milligram in Euros')
plt.legend()
plt.show()


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

plt.figure(figsize=(10, 5))
plt.plot(testservice['year'], testservice['mdma'], label='mdma')
plt.axvline(x=2013, color='red', linestyle='--', label='Year 2013 (t = -1)')
plt.xlabel('Year')
plt.ylabel('mdma')
#plt.title('Dose Min and Max Over the Years')
plt.legend()
plt.show()

test_2000 = testservice[testservice['year'] > 1999]
plt.figure(figsize=(10, 5))
plt.plot(test_2000['year'], test_2000['mdma'], label='mdma')
plt.plot(test_2000['year'], test_2000['cocaine'], label='cocaine')
plt.plot(test_2000['year'], test_2000['amphetamine'], label='amphetamine')
plt.plot(test_2000['year'], test_2000['ketamine'], label='ketamine')
plt.plot(test_2000['year'], test_2000['2cb'], label='2cb')
plt.plot(test_2000['year'], test_2000['3mmc4mmc'], label='3mmc4mmc')
plt.plot(test_2000['year'], test_2000['4fa'], label='4fa')
plt.plot(test_2000['year'], test_2000['lsd'], label='lsd')
plt.plot(test_2000['year'], test_2000['ghb'], label='ghb')
plt.plot(test_2000['year'], test_2000['other'], label='other')
plt.plot(test_2000['year'], test_2000['unknown'], label='unknown')
plt.axvline(x=2013, color='red', linestyle='--', label='Year 2013 (t = -1)')
plt.xlabel('Year')
plt.ylabel('mdma')
#plt.title('Dose Min and Max Over the Years')
plt.legend()
plt.show()

plt.figure(figsize=(10, 5))
plt.plot(test_2000['year'], np.log(test_2000['mdma']), label='mdma')
plt.plot(test_2000['year'], np.log(test_2000['cocaine']), label='cocaine')
plt.plot(test_2000['year'], np.log(test_2000['amphetamine']), label='amphetamine')
plt.plot(test_2000['year'], np.log(test_2000['ketamine']), label='ketamine')
plt.plot(test_2000['year'], np.log(test_2000['2cb']), label='2cb')
plt.plot(test_2000['year'], np.log(test_2000['3mmc4mmc']), label='3mmc4mmc')
plt.plot(test_2000['year'], np.log(test_2000['4fa']), label='4fa')
plt.plot(test_2000['year'], np.log(test_2000['lsd']), label='lsd')
plt.plot(test_2000['year'], np.log(test_2000['ghb']), label='ghb')
plt.plot(test_2000['year'], np.log(test_2000['other']), label='other')
plt.plot(test_2000['year'], np.log(test_2000['unknown']), label='unknown')
plt.axvline(x=2013, color='red', linestyle='--', label='Year 2013 (t = -1)')
plt.xlabel('Year')
plt.ylabel('mdma')
#plt.title('Dose Min and Max Over the Years')
plt.legend()
plt.show()

test_base = testservice[testservice['year'] > 1999]
test_base.iloc[:, 1:] = test_base.iloc[:, 1:].astype(float)
test_base.iloc[:, 1:] = test_base.iloc[:, 1:].div(test_base.iloc[0, 1:]) * 100

plt.figure(figsize=(10, 5))
plt.plot(test_base['year'], test_base['mdma'], label='mdma')
plt.plot(test_base['year'], test_base['cocaine'], label='cocaine')
plt.plot(test_base['year'], test_base['amphetamine'], label='amphetamine')
plt.plot(test_base['year'], test_base['ketamine'], label='ketamine')
plt.plot(test_base['year'], test_base['2cb'], label='2cb')
plt.axvline(x=2013, color='red', linestyle='--', label='Year 2013 (t = -1)')
plt.xlabel('Year')
plt.ylabel('mdma')
#plt.title('Dose Min and Max Over the Years')
plt.legend()
plt.show()

plt.figure(figsize=(10, 5))
plt.plot(test_base['year'], np.log(test_base['mdma']), label='mdma')
plt.plot(test_base['year'], np.log(test_base['cocaine']), label='cocaine')
plt.plot(test_base['year'], np.log(test_base['amphetamine']), label='amphetamine')
plt.plot(test_base['year'], np.log(test_base['ketamine']), label='ketamine')
plt.plot(test_base['year'], np.log(test_base['2cb']), label='2cb')
plt.axvline(x=2013, color='red', linestyle='--', label='Year 2013 (t = -1)')
plt.xlabel('Year')
plt.ylabel('mdma')
#plt.title('Dose Min and Max Over the Years')
plt.legend()
plt.show()

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