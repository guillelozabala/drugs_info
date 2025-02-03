import requests
from bs4 import BeautifulSoup
import pandas as pd

# Up to 2022 data
def download_csv_files_from_links(url):
    try:
        # Fetch the content of the webpage
        response = requests.get(url)
        response.raise_for_status()  # Raise an exception for HTTP errors
        page_content = response.text

        # Parse the HTML
        soup = BeautifulSoup(page_content, 'html.parser')
        
        # Find all links in the webpage
        links = soup.find_all('a', href=True)
        
        # Filter links that match the desired pattern
        csv_links = [requests.compat.urljoin(url, link['href']) for link in links if 'edr2024-nps-table-' in link['href'] and link['href'].endswith('.csv')]

        # Download each CSV file
        for csv_link in csv_links:
            csv_response = requests.get(csv_link)
            csv_response.raise_for_status()
            csv_filename = csv_link.split('/')[-1]
            with open(f"./data/source/euda/{csv_filename}", 'wb') as f:
                f.write(csv_response.content)
            print(f"Downloaded {csv_filename}")

    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")

# Root
csv_path = 'https://www.euda.europa.eu/data/source-data/edr/2024/complete_en'

# Download CSV files from the links
download_csv_files_from_links(csv_path)

# Up to 2021 data
# Define a function to scrape a webpage for tables
# def scrape_for_tables(url):
#     try:
#         # Fetch the content of the webpage
#         response = requests.get(url)
#         response.raise_for_status()  # Raise an exception for HTTP errors
#         page_content = response.text

#         # Parse the HTML
#         soup = BeautifulSoup(page_content, 'html.parser')
        
#         # Find all tables in the webpage
#         tables = soup.find_all('table')
#         captions = soup.find_all('caption')

#         # Extract data from each table
#         tables_data = []
#         for table in tables:
#             table_data = []
#             rows = table.find_all('tr')
#             for row in rows:
#                 cols = row.find_all(['td', 'th'])
#                 cols = [ele.text.strip() for ele in cols]
#                 table_data.append(cols)
#             tables_data.append(table_data)
        
#         return [tables_data, captions]

#     except requests.exceptions.RequestException as e:
#         print(f"An error occurred: {e}")
#         return None

# # Convert the tables to a pandas DataFrame and save as a .csv file
# def tables_to_csv(url, csv_filename):
#     tables_data, captions = scrape_for_tables(url)

#     for i, table_data in enumerate(tables_data):
#         df = pd.DataFrame(table_data[1:], columns=table_data[0])
#         df.to_csv(f"./data/source/euda/{csv_filename}_{i}.csv", index=False)
#         print(f"Table {i} saved as {csv_filename}_{i}.csv")

#     for i, caption in enumerate(captions):
#         with open(f"./data/source/euda/{csv_filename}_{i}.txt", 'w') as f:
#             f.write(caption.text.strip() + '\n')
#         print(f"Caption saved as {csv_filename}_{i}.txt")

# tables_to_csv('https://www.euda.europa.eu/data/source-data/edr/2023/nps_en', 'euda_tables')