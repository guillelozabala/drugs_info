import requests
from bs4 import BeautifulSoup
from datetime import datetime, timedelta
import pandas as pd
import json

# Define a function to scrape a webpage for specific keywords
def scrape_for_keywords(url, keywords):
    try:
        # Fetch the content of the webpage
        response = requests.get(url)
        response.raise_for_status()  # Raise an exception for HTTP errors
        page_content = response.text

        # Parse the HTML
        soup = BeautifulSoup(page_content, 'html.parser')
        
        # Convert HTML to plain text and search for keywords
        page_text = soup.get_text().lower()
        
        # Search for keywords
        found_keywords = {keyword: page_text.count(keyword.lower()) for keyword in keywords}
        
        # Find all links within the container with the specific class, if it exists
        n_links = len(soup.select('.Archive__list a'))
            
        return [found_keywords, n_links]

    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")
        return None

# Load the keywords
with open(r'./codes/data_construction/aux_files/telegraaf_keywords.json', 'r') as f:
    keywords = json.load(f)

# Define the start and end dates
start_date, end_date, delta = datetime(2009, 1, 1), datetime(2023, 12, 31), timedelta(days=1)

# Create an empty list to store the matches
matches = []

# Loop over the dates and scrape the webpage for the keywords
current_date = start_date
while current_date <= end_date:
    url = f"https://www.telegraaf.nl/archief/{current_date.year}/{current_date.month:02d}/{current_date.day:02d}"
    results = scrape_for_keywords(url, keywords)
    results_keywords = results[0]
    for keyword, count in results_keywords.items():
        results_links = results[1]
        matches.append({
            'date': current_date,
            'n_links': results_links,
            'keyword': keyword,
            'count': count,
            'url': url
        })
    current_date += delta

# Save the matches to a JSON file
with open(r'./data/processed/red_alerts_news/telegraaf_matches.json', 'w') as f:
    json.dump(matches, f, default=str)

# Convert matches to a DataFrame
matches_df = pd.DataFrame(matches)

# Convert the 'date' column to datetime
matches_df['date'] = pd.to_datetime(matches_df['date'])

# Aggregate the observations at the year-month level for each keyword
matches_df['year_month'] = matches_df['date'].dt.to_period('M')
monthly_aggregated_df = matches_df.groupby(['year_month', 'keyword']).agg({
    'count': 'sum',
    'n_links': 'sum'
}).reset_index()

# Save the aggregated data to a CSV file
monthly_aggregated_df.to_csv(r'./data/processed/red_alerts_news/telegraaf_monthly_aggregated.csv', index=False)

# Aggregate the observations at the year level for each keyword
matches_df['year'] = matches_df['date'].dt.year
yearly_aggregated_df = matches_df.groupby(['year', 'keyword']).agg({
    'count': 'sum',
    'n_links': 'sum'
}).reset_index()

# Save the aggregated data to a CSV file
yearly_aggregated_df.to_csv(r'./data/processed/red_alerts_news/telegraaf_yearly_aggregated.csv', index=False)