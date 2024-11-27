import requests
from bs4 import BeautifulSoup
import pandas as pd

# Define a function to scrape a webpage for tables
def scrape_for_tables(url):
    try:
        # Fetch the content of the webpage
        response = requests.get(url)
        response.raise_for_status()  # Raise an exception for HTTP errors
        page_content = response.text

        # Parse the HTML
        soup = BeautifulSoup(page_content, 'html.parser')
        
        # Find all tables in the webpage
        tables = soup.find_all('table')
        captions = soup.find_all('caption')

        # Extract data from each table
        tables_data = []
        for table in tables:
            table_data = []
            rows = table.find_all('tr')
            for row in rows:
                cols = row.find_all(['td', 'th'])
                cols = [ele.text.strip() for ele in cols]
                table_data.append(cols)
            tables_data.append(table_data)
        
        return [tables_data, captions]

    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")
        return None

# Convert the tables to a pandas DataFrame and save as a .csv file
def tables_to_csv(url, csv_filename):
    tables_data, captions = scrape_for_tables(url)

    for i, table_data in enumerate(tables_data):
        df = pd.DataFrame(table_data[1:], columns=table_data[0])
        df.to_csv(f"./data/source/euda/{csv_filename}_{i}.csv", index=False)
        print(f"Table {i} saved as {csv_filename}_{i}.csv")

    for i, caption in enumerate(captions):
        with open(f"./data/source/euda/{csv_filename}_{i}.txt", 'w') as f:
            f.write(caption.text.strip() + '\n')
        print(f"Caption saved as {csv_filename}_{i}.txt")

tables_to_csv('https://www.euda.europa.eu/data/source-data/edr/2023/nps_en', 'euda_tables')