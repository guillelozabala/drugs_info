from codes.data_construction.antenne_reports_clearing_utils import *

path_2023 = r'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_2023/'

# TOTAL SAMPLES DATA

# Rows with missing data
faulty_rows = [0, 4, 16, 28] 

# Coordinates of faulty cells and their correct values
changes = [
    (10, 2, 35),
    (6, 3, 6),
    (10, 3, 39),
    (17, 3, 66),
    (21, 3, 138),
    (28, 3, 291)
]

units = ['mdma', 'total']

COLUMN_MAP_TOTAL_SAMPLES = {
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
    }

clean_total_reports_data('225_0.csv',path_2023,COLUMN_MAP_TOTAL_SAMPLES,faulty_rows,changes,units)


# DOSES DATA

# Constants
COLUMN_MAP_DOSES = {
    'year': 'Unnamed: 0',
    'n_samples': 'Unnamed: 1',
    'n_prices_default': 'Unnamed: 3',
    'prices_default': 'Unnamed: 4',
    'dosering': 'dosering',
}

# Substance-specific settings
SUBSTANCE_SETTINGS_DOSES = {
    'mdma': {
        'adjustments': [
            {'column': COLUMN_MAP_DOSES['year'], 'function': lambda x: x + 2000 if x < 50 else x + 1000},
            {'column': COLUMN_MAP_DOSES['n_samples'], 'function': lambda x: x * 1000 if x < 10 else x},
            {'column': COLUMN_MAP_DOSES['n_prices_default'], 'function': lambda x: x * 1000 if x < 10 else x},
        ]
    },
    'cocaine': {
        'adjustments': [{'column': COLUMN_MAP_DOSES['year'], 'function': lambda x: x + 2000}]
    },
    'twocb': {
        'adjustments': [
            {'column': 'Unnamed: 5', 'function': lambda x, i: x + ['2', '3', '2', '4', '4', '2', '3', '3', '6', '7', '0', '7'][i], 'index': True},
        ],
        'drop_columns': ['Unnamed: 3'],
        'price_column': 'Unnamed: 5',
        'n_price_column': 'Unnamed: 4',
    },
    'ghb': {
        'split_columns': {'Unnamed: 2': ['dose_min', 'dose_max'], 'doserin': ['dose_mean', 'dose_sd']},
        'drop_columns': ['Unnamed: 2', 'doserin'],
        'price_column': None,
    },
    'lsd': {
        'adjustments': [{'column': COLUMN_MAP_DOSES['year'], 'function': lambda x: x + 2000}],
        'price_column': 'prijs',
    },
}

substances_doses = [
    ('mdma', '227_2.csv'),
    ('cocaine', '229_2.csv'),
    ('amphetamine', '230_2.csv'),
    ('ketamine', '231_1.csv'),
    ('twocb', '232_2.csv'),
    ('lsd', '233_2.csv'),
    ('ghb', '234_2.csv')
]

# Process each substance
for substance, file_name in substances_doses:
    clean_dosering_data(substance, file_name, path_2023, SUBSTANCE_SETTINGS_DOSES, COLUMN_MAP_DOSES)

# PURITY DATA

substances_purity = [
    ('mdma', '227_0.csv'), # missing last row
    ('cocaine', '228_0.csv'),
    ('amphetamine', '229_1.csv'),
    ('ketamine', '230_1.csv'), #year
    ('twocb', '231_0.csv'),
    ('lsd', '232_1.csv'), # year
    ('ghb', '233_1.csv')
]

COLUMN_MAP_PURITY = {
    'Unnamed: 0':'year',
    'geen':'no_analysis',
}

TRANSLATIONS = {
    'uitsluitend': 'exclusively',
    'voornamelijk': 'primarily',
    'ander': 'other',
    'overige': 'remaining'
}

# Process each substance
for substance, file_name in substances_purity:
    clean_purity_data(substance, file_name, path_2023, COLUMN_MAP_PURITY, TRANSLATIONS)

