
import pandas as pd
import json
from codes.data_construction.national_reports_cleaning_utils import *

# Path to intermediate data files
source_path = r'./data/intermediate/national_reports_raw_csvs/national_report_'
# Path to auxiliary files
aux_path = r'./codes/data_construction/aux_files/'
# Path to save the cleaned datasets
save_path = r'./data/processed/national_reports/incidents/'

# Load the incidents datasets
with open(aux_path + 'incidents_datasets.json', 'r') as file:
    incidents_datasets = json.load(file)
# Load the incidents columns mapping
with open(aux_path + 'incidents_columns_mapping.json', 'r') as file:
    incidents_columns_mapping = json.load(file)

# Restrict the incidents datasets to those up to 2019 (failure to scan the 2020-2022 datasets)
incidents_datasets_up_to_2019 = {key: value for key, value in incidents_datasets.items() if int(key) < 2020}

# Clean the incidents datasets
incident_reports_up_to_19 = national_reports_cleaning(incidents_datasets_up_to_2019, source_path, incidents_columns_mapping)

# Load the handcrafed datasets
incidents_20 = load_and_append_csvs(source_path + '2021')
incidents_21 = load_and_append_csvs(source_path + '2022')
incidents_22 = load_and_append_csvs(source_path + '2023')

# Concatenate the datasets
joint_incidents = pd.concat([incident_reports_up_to_19, incidents_20, incidents_21, incidents_22], ignore_index=True)

# Save the cleaned dataset
joint_incidents.to_csv(save_path + 'joint_incidents.csv', index=False)