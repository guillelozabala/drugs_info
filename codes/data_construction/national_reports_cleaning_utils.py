import pandas as pd
import re
import os

def clean_dataframe(df, year, substance, column_mappings):

    # Preprocess
    df = df.transpose()
    df.columns = df.iloc[0]
    df = df[1:].dropna(axis=1, how='all') 

    # Remove unwanted characters from observations
    unwanted_characters = ['%', ' jaar']
    for char in unwanted_characters:
        df = df.map(lambda x: re.sub(char, '', str(x)) if isinstance(x, str) else x)
    
    # Remove spaces between integers
    df = df.map(lambda x: re.sub(r'(\d)\s+(\d)', r'\1\2', str(x)) if isinstance(x, str) else x)
    # Remove other strings
    df = df.map(lambda x: re.search(r'\d+(\.\d+)?', str(x)).group() if re.search(r'\d+(\.\d+)?', str(x)) else x)

    # Year-specific processings
    if year == '2011':
        df = df.loc[:, ~df.columns.astype(str).str.contains('lcohol')]

    if year in {'2014','2015','2016', '2019'}:
        df.columns = [f"Unnamed_{i}" if pd.isna(col) else col for i, col in enumerate(df.columns)]

    if year in {'2015', '2016', '2017', '2018', '2019'}:
        replacements = {1: 'SEH-MDI-ziekenhuizen', 2: 'SEH-LIS-ziekenhuizen'}
        for idx, name in replacements.items():
            df.iloc[idx, 0] = name

    if year in {'2018', '2019'}:
        df.iloc[3, 0] = 'Forensisch artsen'

    if year == '2019':
        df.iloc[0, 0] = 'Ambulances'
        if substance != 'Opioids':
            df.iloc[4, 0] = 'EHBO-posten'
        if substance == 'Cocaine':
            df['Ook alcohol gebruikt (%)'] = df.pop('Ook alcohol gebruikt (%)')
        if substance in {'MDMA', 'Opioids'}:
            df = df.drop(columns=df.columns[1])
        if substance == 'GHB':
            df = df.drop(columns=df.columns[1:3])

    # Apply column renaming (if exists)
    column_positions = column_mappings.get(year, {})
    df = df.rename(columns={df.columns[int(i)]: name for i, name in column_positions.items() if int(i) < len(df.columns)})

    # Handle index-related operations
    df['year'] = year if year != '2010' else df.index
    if year in {'2011', '2012', '2013', '2014'}:
        df['origin'] = df.index

    df['drug'] = substance

    return df.reset_index(drop=True)

def national_reports_cleaning(incidents_dict, source_path, column_mappings):

    dfs = []
    for year, substances in incidents_dict.items():
        index_year = str(int(year) + 1) if int(year) > 2013 else year
        dfs_year = [
            clean_dataframe(pd.read_csv(f"{source_path}{index_year}/{file}"), year, substance, column_mappings)
            for substance, file in substances.items() if substance != 'Ketamine'
        ]
        dfs.append(pd.concat(dfs_year, ignore_index=True))

    # print('yeah 9')
    joint_df = pd.concat(dfs, ignore_index=True)
    
    # In another function, we will handle the wrong values
    if len(joint_df) >= 58:
        joint_df.loc[57, 'median_age'] = 22
    
    if '2013' in joint_df['year'].values:
        joint_df.loc[(joint_df['drug'] == 'Opioids') & (joint_df['year'] == '2013'), 'below_25_pcnt'] = 100 - joint_df.loc[(joint_df['drug'] == 'Opioids') & (joint_df['year'] == '2013'), 'below_25_pcnt'].fillna(0).astype(int)
        joint_df.loc[(joint_df['drug'] == 'Opioids') & (joint_df['year'] == '2013') & (joint_df['below_25_pcnt'] == 100), 'below_25_pcnt'] = float('NaN')

    return joint_df

def load_and_append_csvs(folder_path):
    all_dfs = []
    for file_name in os.listdir(folder_path):
        if file_name.endswith('.csv'):
            df = pd.read_csv(os.path.join(folder_path, file_name))
            all_dfs.append(df)
    return pd.concat(all_dfs, ignore_index=True)
