
### This script contains the function that download the Antenne reports,
### finds its tables and save them as .csv files.

# General purpose
import os
import torch

# PDF scraping
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

# PDF to image conversion
from pdf2image import convert_from_path

# Table extraction (tensors)
from PIL import Image
import torch

# Read tables and save them as .csv
import tabula
import pandas as pd

## Download the reports
def download_reports(url, download_folder=r'./data/source/antenne_reports'):

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

## Get the tables as .png files (so that they can be processed by the model)
def report_tables_to_png(tables_dict, init_year=2003, end_year=2024):
    
    print("Converting the tables to images...")

    for year in range(init_year, end_year):
        # Path to the PDF file
        pdf_path = f'./data/source/antenne_reports/antenne-amsterdam-{year}.pdf'

        # Specify the pages to convert 
        pages_to_convert = tables_dict[str(year)]

        # Convert the specified pages to images
        images = convert_from_path(pdf_path, first_page=min(pages_to_convert), last_page=max(pages_to_convert))

        # Save or process the selected pages
        selected_images = []
        for i, page_num in enumerate(pages_to_convert):
            # Extract the image for the selected page (remembering that list indexing starts at 0)
            page_image = images[page_num - min(pages_to_convert)]
            selected_images.append(page_image)

            # Save the image
            page_image.save(f'data/intermediate/antenne_reports_to_images/antenne_amsterdam_{year}/{page_num}.png', 'PNG')
        
    print("Done!")

## Obtain the boundaries of the tables inside the pages of the reports
def obtain_the_tensors(image_processor, model, init_year=2003, end_year=2024):

    print("Detecting tables in the images...")

    for year in range(init_year, end_year):
        # Path to images folder
        folder_path = f'data/intermediate/antenne_reports_to_images/antenne_amsterdam_{year}'
        file_names = [f for f in os.listdir(folder_path) if f.endswith('.png')]
        
        # Apply the model to each image
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
            torch.save(results['boxes'], f'data/intermediate/antenne_reports_table_tensors/antenne_amsterdam_{year}/{tensors_name}.pt')

    print("Done!")

## Convert the tables to .csv files, if they can be read
def report_tables_to_csv(res_cons, init_year=2003, end_year=2024):

    print("Extracting tables and saving them as .csv files...")

    for year in range(init_year, end_year):
        # Path to tensors folder
        folder_path = f'./data/intermediate/antenne_reports_table_tensors/antenne_amsterdam_{year}'
        file_names = [f for f in os.listdir(folder_path) if f.endswith('.pt')]

        # Path to the PDF files
        pdf_path = f'./data/source/antenne_reports/antenne-amsterdam-{year}.pdf'

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
                    df.to_csv(f'./data/intermediate/antenne_reports_raw_csvs/antenne_amsterdam_{year}/{page}_{tensor}.csv', index=False)

    print("Done!")

