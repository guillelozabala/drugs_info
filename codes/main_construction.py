
import json
from transformers import AutoImageProcessor, TableTransformerForObjectDetection
from data_construction.antenne_reports_utils import (
    read_link,
    download_reports,
    rename_pdf_files,
    report_tables_to_png,
    obtain_the_tensors,
    report_tables_to_csv,
)


# Main function
def main():

    # Load the paths
    antenne_reps_path = r"./data/source/antenne_reports"
    national_reps_path = r"./data/source/national_drug_monitor"

    # Load the links
    antenne_reps_link = read_link(antenne_reps_path + "/original_link.txt")
    national_reps_link = read_link(national_reps_path + "/original_link.txt")

    # Download the reports
    download_reports(antenne_reps_link, antenne_reps_path)
    download_reports(national_reps_link, national_reps_path)

    # Rename the PDF files (National reports)
    rename_pdf_files(national_reps_path)

    # Load the tables dictionary (Antenne reports)
    with open(antenne_reps_path + "/tables_dict.json", "r") as f:
        antenne_dict = json.load(f)

    # Load the tables dictionary (National reports)
    with open(national_reps_path + "/incidents_dict.json", "r") as f:
        national_dict = json.load(f)

    # Convert report tables to PNG
    report_tables_to_png(
        antenne_dict,
        "antenne",
        init_year=2003,
        end_year=2024
    )

    report_tables_to_png(
        national_dict,
        "national",
        init_year=1999,
        end_year=2024
    )

    # Initialize the image processor and model
    image_processor = AutoImageProcessor.from_pretrained(
        "microsoft/table-transformer-detection"
    )
    model = TableTransformerForObjectDetection.from_pretrained(
        "microsoft/table-transformer-detection"
    )

    # Obtain the tensors
    obtain_the_tensors(
        image_processor,
        model,
        "antenne",
        init_year=2003,
        end_year=2024
    )

    obtain_the_tensors(
        image_processor,
        model,
        "national",
        init_year=1999,
        end_year=2024
    )

    # Resolution constant (200 dpi)
    res_cons = 72 / 200

    # Convert report tables to CSV
    report_tables_to_csv(
        res_cons,
        "antenne",
        init_year=2003,
        end_year=2024
    )

    report_tables_to_csv(
        res_cons,
        "national",
        init_year=2003,
        end_year=2024
    )
