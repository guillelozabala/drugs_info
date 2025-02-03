import pandas as pd
import numpy as np
import inspect

def clean_total_reports_data(
        file_name,
        path,
        column_map,
        faulty_rows,
        changes,
        units
    ):
        
    # Read the CSV file into a DataFrame
    df = pd.read_csv(path + file_name)

    # Drop the specified faulty rows and reset the index
    df = df.drop(index=faulty_rows).reset_index(drop=True)

    # Apply the specified changes to the DataFrame
    for row, col, value in changes:
        df.iloc[row, col] = value

    # Rename the columns according to the column_map
    df.rename(columns=column_map, inplace=True)

    # Scale the specified columns' values by 1000 if they are less than 10
    for variable in units:
        df[variable] = df[variable].apply(lambda x: x * 1000 if x < 10 else x)

    # Fill NaN values with 0 and convert all values to integers
    df = df.fillna(0).astype(int)

    # Save the cleaned DataFrame to a CSV file
    df.to_csv(r'./data/processed/antenne_reports/testservice/total_samples_2023.csv', index=False)


def clean_dosering_data(
        substance,
        file_name,
        path,
        substance_settings,
        column_map
    ):

    df = pd.read_csv(path + file_name)
    df = df.drop(index=[0, 1]).reset_index(drop=True)

    # Get the substance-specific settings
    settings = substance_settings.get(substance, {})
    
    # Apply adjustments
    for adjustment in settings.get('adjustments', []):
        column = adjustment['column']
        function = adjustment['function']
        function_args = inspect.signature(function).parameters
        if len(function_args) == 1:
            df[column] = df.apply(lambda row: function(row[column]), axis=1)
        else:
            df[column] = df.apply(lambda row: function(row[column], row.name), axis=1)

    # Column splitting
    split_columns = settings.get('split_columns', {'Unnamed: 2': ['dose_min', 'dose_max'], column_map['dosering']: ['dose_mean', 'dose_sd']})
    for col, new_cols in split_columns.items():
        df[new_cols] = df[col].str.split('-', expand=True) if '-' in df[col][0] else df[col].str.split(' ', expand=True)
    
    # Get the price and number of samples priced columns
    price_col = settings.get('price_column', column_map['prices_default'])
    n_price_col = settings.get('n_price_column', column_map['n_prices_default'])

    # Remove undesired characters
    df['dose_sd'] = df['dose_sd'].str.replace(r'[()]', '', regex=True)
    if price_col:
        df[price_col] = df[price_col].str.replace(r'[€]', '', regex=True)

    # Rename columns
    rename_map = {
        column_map['year']: 'year',
        column_map['n_samples']: 'n_samples',
        n_price_col: 'n_prices',
        price_col: 'price_per_gram'
    }
    df.rename(columns=rename_map, inplace=True)

    # Convert columns to numeric
    if 'price_per_gram' in df.columns:
        df['price_per_gram'] = df['price_per_gram'].str.replace(r',', '.', regex=True)
        cols_to_num = ['dose_min', 'dose_max', 'dose_mean', 'dose_sd', 'price_per_gram']
    else:
        cols_to_num = ['dose_min', 'dose_max', 'dose_mean', 'dose_sd']
    df[cols_to_num] = df[cols_to_num].apply(pd.to_numeric, errors='coerce')

    # Create derived variables
    df['adj_volatility'] = df['dose_sd'] * np.sqrt(df['n_samples'])

    # Specific variables for certain substances
    if substance in ['mdma', 'twocb']:
        df.rename(columns={'price_per_gram': 'price_per_pill'}, inplace=True)
        df['price_per_mg'] = df['price_per_pill'] / df['dose_mean']
    elif substance == 'lsd':
        df.rename(columns={'price_per_gram': 'price_per_tab'}, inplace=True)
        df['price_per_mg'] = df['price_per_tab'] / df['dose_mean']

    # Drop unnecessary columns
    df_filter = df.filter(settings.get('drop_columns', []) + ['Unnamed: 2', column_map['dosering'], 'prijs'])
    df.drop(df_filter, inplace=True, axis=1)

    # Save processed data
    output_path = f'./data/processed/antenne_reports/testservice/{substance}_dosering_2023.csv'
    df.to_csv(output_path, index=False)


def clean_purity_data(
    substance,
    file_name,
    path,
    column_map,
    translations
    ):

    df = pd.read_csv(path + file_name)
    df = df.drop(index=[0]).reset_index(drop=True)

    # Rename specific columns
    df.rename(columns=column_map, inplace=True)

    # Split columns with multiple values
    for col, eng_col in translations.items():
        if df[col].str.contains(' ').any():
            df[[f'N_{eng_col}_{substance}', f'{eng_col}_{substance}_pct']] = df[col].str.split(' ', expand=True)
    df.drop(columns=translations.keys(), inplace=True)

    # Convert columns to numeric
    for col in df.columns:
        df[col] = df[col].astype(str).str.replace(r'[%]', '', regex=True)
        df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0).astype(int)

    # Idiosyncratic adjustments
    if substance == 'mdma':
        missing_row_2023 = pd.Series([2023, 35, 791, 97, 4, 0, 18, 2, 1, 0], index=df.columns)
        df = pd.concat([df, missing_row_2023.to_frame().T], ignore_index=True)
    elif substance in ['ketamine', 'lsd']:
        df['year'] = df['year'] + 2000

    # Save processed data
    output_path = f'./data/processed/antenne_reports/testservice/{substance}_purity_2023.csv'
    df.to_csv(output_path, index=False)
