import json
from transformers import AutoImageProcessor, TableTransformerForObjectDetection
from codes.data_construction.antenne_reports_utils import download_reports, report_tables_to_png, obtain_the_tensors, report_tables_to_csv

def main():
    # Load the reports url
    with open(r'./data/source/antenne_reports/original_link.txt', 'r') as file:
        reports_link = file.read().strip()  # Strip any leading/trailing whitespace

    # Download the reports
    download_reports(reports_link)

    # Load the tables dictionary
    with open(r'./data/source/antenne_reports/tables_dict.json', 'r') as f:
        tables_dict = json.load(f)

    # Convert report tables to PNG
    report_tables_to_png(tables_dict)

    # Initialize the image processor and model
    image_processor = AutoImageProcessor.from_pretrained("microsoft/table-transformer-detection")
    model = TableTransformerForObjectDetection.from_pretrained("microsoft/table-transformer-detection")

    # Obtain the tensors
    obtain_the_tensors(image_processor, model)

    # Resolution constant (200 dpi)
    res_cons = 72 / 200

    # Convert report tables to CSV
    report_tables_to_csv(res_cons)

if __name__ == "__main__":
    main()