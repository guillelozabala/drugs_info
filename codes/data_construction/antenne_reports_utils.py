
### This script contains the function that download the Antenne reports,
### finds its tables and save them as .csv files.

# General purpose
import os
import re
import torch

# PDF scraping
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

# PDF to image conversion
from pdf2image import convert_from_path

# Table extraction (tensors)
from PIL import Image

# Read tables and save them as .csv
import tabula
import pandas as pd

## Load the links
def read_link(file_path):
    with open(file_path, 'r') as file:
        return file.read().strip()

## Download the reports
def download_reports(url, download_folder):

    print("Downloading the reports from the HvA webpage...")

    # Get the HTML content of the webpage
    response = requests.get(url)
    if response.status_code != 200:
        print("Failed to retrieve the webpage.")
        return

    # Parse the HTML content with BeautifulSoup
    soup = BeautifulSoup(response.text, 'html.parser')

    # Find all <a> tags with href attributes ending in .pdf
    pdf_links = [urljoin(url, link['href']) for link in soup.find_all('a', href=True) if link['href'].endswith('.pdf')]

    # Download each PDF file
    for pdf_link in pdf_links:
        try:
            pdf_response = requests.get(pdf_link)
            pdf_response.raise_for_status()

            # Extract the file name from the link
            pdf_name = pdf_link.split('/')[-1]

            # Save the PDF to the folder
            pdf_path = os.path.join(download_folder, pdf_name)
            with open(pdf_path, 'wb') as pdf_file:
                pdf_file.write(pdf_response.content)

            print(f"Downloaded: {pdf_name}")
        except requests.exceptions.RequestException as e:
            print(f"Failed to download {pdf_link}: {e}")
    
    print("Done!")

## Rename the PDF files
def rename_pdf_files(directory):
    # Regular expression to find the first year in the filename
    year_pattern = re.compile(r'(19|20)\d{2}')

    # Iterate over all files in the directory
    for filename in os.listdir(directory):
        if filename == "bevriezing-JB23-verkleind.pdf":
            old_file = os.path.join(directory, filename)
            new_file = os.path.join(directory, "NDM-2023.pdf")
            os.rename(old_file, new_file)
            continue
        if filename.endswith('.pdf'):
            # Search for the first year in the filename
            match = year_pattern.search(filename)
            if match:
                # Construct the new filename
                new_filename = f"NDM-{match.group(0)}.pdf"
                # Get the full paths
                old_file = os.path.join(directory, filename)
                new_file = os.path.join(directory, new_filename)
                # Rename the file
                os.rename(old_file, new_file)
                print(f"Renamed '{filename}' to '{new_filename}'")

    print("Done!")

## Get the tables as .png files (so that they can be processed by the model)
def report_tables_to_png(tables_dict, report, init_year, end_year):
    print("Converting the tables to images...")

    for year in range(init_year, end_year):
        try:
            if report == "antenne":
                pdf_path = f'./data/source/antenne_reports/antenne-amsterdam-{year}.pdf'
                pages_to_convert = tables_dict[str(year)]
                images = convert_from_path(pdf_path, first_page=min(pages_to_convert), last_page=max(pages_to_convert))
                output_path = 'data/intermediate/antenne_reports_to_images/antenne_amsterdam_'
            
            elif report == "national":
                pdf_path = f'./data/source/national_drug_monitor/NDM-{year}.pdf'

                # Check if the file exists before trying to convert it
                if not os.path.exists(pdf_path):
                    print(f"Warning: File {pdf_path} not found. Skipping year {year}.")
                    continue

                # images = convert_from_path(pdf_path)
                # output_path = 'data/intermediate/national_reports_to_images/national_report_'
                # pages_to_convert = list(range(1, len(images) + 1))

                pages_to_convert = tables_dict[str(year)]
                images = convert_from_path(pdf_path, first_page=min(pages_to_convert), last_page=max(pages_to_convert))
                output_path = 'data/intermediate/national_reports_to_images/national_report_'

            # Save or process the selected pages
            selected_images = []
            for i, page_num in enumerate(pages_to_convert):
                page_image = images[page_num - min(pages_to_convert)]
                selected_images.append(page_image)

                # Ensure the output directory exists before saving
                year_output_dir = os.path.dirname(output_path + f'{year}/{page_num}.png')
                os.makedirs(year_output_dir, exist_ok=True)

                page_image.save(output_path + f'{year}/{page_num}.png', 'PNG')

        except FileNotFoundError:
            print(f"Error: The file {pdf_path} does not exist. Skipping {year}.")
        except Exception as e:
            print(f"Unexpected error processing {pdf_path}: {e}")

    print("Done!")

## Obtain the boundaries of the tables inside the pages of the reports
def obtain_the_tensors(image_processor, model, report, init_year, end_year):

    print("Detecting tables in the images...")

    for year in range(init_year, end_year):

        try: 
            if report == "antenne":
                folder_path = f'data/intermediate/antenne_reports_to_images/antenne_amsterdam_{year}'
                output_path = f'data/intermediate/antenne_reports_table_tensors/antenne_amsterdam_{year}'

            elif report == "national":
                folder_path = f'data/intermediate/national_reports_to_images/national_report_{year}'
                if not os.path.exists(folder_path):
                    print(f"Warning: File {folder_path} not found. Skipping year {year}.")
                    continue
                output_path = f'data/intermediate/national_reports_table_tensors/national_report_{year}'

            file_names = [f for f in os.listdir(folder_path) if f.endswith('.png')]

            # Ensure the output directory exists before saving
            os.makedirs(output_path, exist_ok=True)

            for file_name in file_names:
                file_path = os.path.join(folder_path, file_name)
                image = Image.open(file_path).convert("RGB")

                # Prepare image for the model
                inputs = image_processor(images=image, return_tensors="pt")

                # Forward pass
                outputs = model(**inputs)

                # Obtain the bounding boxes and class logits
                target_sizes = torch.tensor([image.size[::-1]])
                results = image_processor.post_process_object_detection(outputs, threshold=0.9, target_sizes=target_sizes)[0]

                # Save the results
                tensors_name = file_name.replace('.png', '')
                torch.save(results['boxes'], f'{output_path}/{tensors_name}.pt')

        except FileNotFoundError:
            print(f"Error: The file {folder_path} does not exist. Skipping {year}.")
        except Exception as e:
            print(f"Unexpected error processing {folder_path}: {e}")

    print("Done!")

## Convert the tables to .csv files, if they can be read
def report_tables_to_csv(res_cons, report ,init_year, end_year):

    print("Extracting tables and saving them as .csv files...")

    for year in range(init_year, end_year):

        try: 
            if report == "antenne":
                # Path to tensors folder
                folder_path = f'./data/intermediate/antenne_reports_table_tensors/antenne_amsterdam_{year}'
                # Path to the PDF files
                pdf_path = f'./data/source/antenne_reports/antenne-amsterdam-{year}.pdf'
                # Path to the output folder
                output_path = f'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_{year}'
            elif report == "national":
                folder_path = f'./data/intermediate/national_reports_table_tensors/national_report_{year}'
                pdf_path = f'./data/source/national_drug_monitor/NDM-{year}.pdf'
                if not os.path.exists(folder_path):
                    print(f"Warning: File {folder_path} not found. Skipping year {year}.")
                    continue
                output_path = f'./data/intermediate/national_reports_raw_csvs/national_report_{year}'
            
            file_names = [f for f in os.listdir(folder_path) if f.endswith('.pt')]

            for file_name in file_names:
                # Load the tensor and the report
                file_path = os.path.join(folder_path, file_name)
                table_tensor = torch.load(file_path, weights_only=True)
                
                for tensor in range(len(table_tensor)):
                    # Extract the bounding box coordinates
                    tensor_list = table_tensor[tensor].tolist()
                    tensor_list = [element * res_cons for element in tensor_list]
                    xmin, ymin, xmax, ymax = tensor_list

                    # Extract the table from the PDF page
                    page = int(file_name.replace('.pt', ''))
                    table = tabula.read_pdf(pdf_path, pages=page, stream=True, area=[ymin, xmin, ymax, xmax])
                    # Save the table as a .csv file if possible
                    if table:
                        df = pd.DataFrame(pd.concat(table))
                        df.to_csv(f'{output_path}/{page}_{tensor}.csv', index=False)
        
        except FileNotFoundError:
            print(f"Error: The file {folder_path} does not exist. Skipping {year}.")
        except Exception as e:
            print(f"Unexpected error processing {folder_path}: {e}")

    print("Done!")








