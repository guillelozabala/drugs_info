import requests
from bs4 import BeautifulSoup
import os
from urllib.parse import urljoin

def download_pdfs_from_webpage(url, download_folder=r'./data/source/antenne_reports'):
    # Create a folder to store the downloaded PDFs if it doesn't exist
    #if not os.path.exists(download_folder):
    #    os.makedirs(download_folder)

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

download_pdfs_from_webpage("https://www.hva.nl/praktisch/algemeen/etalage/antenne/amsterdam/publicaties/publicaties.html")