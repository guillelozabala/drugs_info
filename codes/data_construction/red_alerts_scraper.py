import requests
from bs4 import BeautifulSoup
from datetime import datetime, timedelta
import pandas as pd
import json

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

start_date = datetime(2009, 1, 1)
end_date = datetime(2023, 12, 31)
delta = timedelta(days=1)

matches_dict = {}
for keyword in keywords:
    matches_dict[keyword] = []

matches_df = pd.DataFrame({
    'date': pd.to_datetime([]),
    'n_links': pd.Series([], dtype='int'),
    'keyword': pd.Series([], dtype='str'),
    'count': pd.Series([], dtype='int'),
    'url': pd.Series([], dtype='str')
})

current_date = start_date

while current_date <= end_date:
    url = f"https://www.telegraaf.nl/archief/{current_date.year}/{current_date.month:02d}/{current_date.day:02d}"
    results = scrape_for_keywords(url, keywords)
    results_keywords = results[0]
    if results_keywords is None:
        current_date += delta
        continue

    if any(count > 0 for count in results_keywords.values()):
        for keyword, count in results_keywords.items():
            if count > 0:
                print(f"Keyword '{keyword}' found {count} times at {url}")
                matches_dict[keyword].append(url)
                new_row = pd.DataFrame([{
                    'date': current_date,
                    'n_links': results[1],
                    'keyword': keyword,
                    'count': count,
                    'url': url
                }])
                matches_df = pd.concat([matches_df, new_row], ignore_index=True)

    current_date += delta

matches_dict
matches_df

matches_df[(matches_df['date'].dt.year == 2014) & (matches_df['date'].dt.month == 11)]
matches_df[(matches_df['date'].dt.year == 2014) & (matches_df['date'].dt.month == 12)]
matches_df[(matches_df['date'].dt.year == 2015) & (matches_df['date'].dt.month == 1)]


matches_df.to_csv(r'./data/processed/red_alert_news/telegraaf_matches.csv', index=False)

# Aggregate the observations at the year level for each keyword
matches_df['year'] = matches_df['date'].dt.year
yearly_aggregated_df = matches_df.groupby(['year', 'keyword']).agg({
    'count': 'sum',
    'n_links': 'sum'
}).reset_index()

yearly_aggregated_df.to_csv(r'./data/processed/red_alert_news/telegraaf_yearly_aggregated.csv', index=False)


# if results is None:
#     current_date += delta
#     continue
# results_keywords = results[0]
#     current_date += delta
#     continue