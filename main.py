
import os

# Check if Conda is installed
if os.system("conda --version") == 0:
    # Check if the environment already exists
    env_name = "drugs_info"  # Replace with your environment name
    if os.system(f"conda env list | findstr {env_name}") != 0:
        os.system("conda env create -f environment.yml")
        print("Conda environment successfully created!")
    else:
        print(f"Conda environment '{env_name}' already exists.")
else:
    print("Error: Conda is not installed.")


import json
from transformers import AutoImageProcessor, TableTransformerForObjectDetection
from codes.data_construction.antenne_reports_utils import *

def main():

    # Load the paths
    antenne_reports_path = r'./data/source/antenne_reports'
    national_reports_path = r'./data/source/national_drug_monitor'

    # Load the links
    antenne_reports_link = read_link(antenne_reports_path + '/original_link.txt')
    national_reports_link = read_link(national_reports_path + '/original_link.txt')

    # Download the reports
    download_reports(antenne_reports_link, antenne_reports_path)
    download_reports(national_reports_link, national_reports_path)

    # Rename the PDF files (National reports)
    rename_pdf_files(national_reports_path)

    # Load the tables dictionary (Antenne reports)
    with open(antenne_reports_path + '/tables_dict.json', 'r') as f:
        antenne_dict = json.load(f)

    # Load the tables dictionary (National reports)
    with open(national_reports_path + '/incidents_dict.json', 'r') as f:
        national_dict = json.load(f)

    # Convert report tables to PNG
    report_tables_to_png(antenne_dict, 'antenne', init_year=2003, end_year=2024)
    report_tables_to_png(national_dict, 'national', init_year=1999, end_year=2024)

    # Initialize the image processor and model
    image_processor = AutoImageProcessor.from_pretrained("microsoft/table-transformer-detection")
    model = TableTransformerForObjectDetection.from_pretrained("microsoft/table-transformer-detection")

    # Obtain the tensors
    obtain_the_tensors(image_processor, model,'antenne', init_year=2003, end_year=2024)
    obtain_the_tensors(image_processor, model,'national', init_year=1999, end_year=2024)

    # Resolution constant (200 dpi)
    res_cons = 72 / 200

    # Convert report tables to CSV
    report_tables_to_csv(res_cons, 'antenne', init_year=2003, end_year=2024)
    report_tables_to_csv(res_cons, 'national', init_year=2003, end_year=2024)

if __name__ == "__main__":
    main()