import pandas as pd

path_euroden = r'./data/source/euro_den/euroden-data-nov-2025.csv'

df_euroden = pd.read_csv(path_euroden)
df_euroden

import matplotlib.pyplot as plt

# Ensure the 'date' column is in datetime format
# df_euroden['date'] = pd.to_datetime(df_euroden['date'])

# Extract the year from the 'date' column
# df_euroden['year'] = df_euroden['date'].dt.year

# Filter the dataframe for the years 2013 to 2023
df_filtered = df_euroden[(df_euroden['Year'] >= 2013) & (df_euroden['Year'] <= 2023)]

# Find hospitals with observations spanning from 2013 to 2023
hospitals_with_full_span = df_filtered.groupby('Hospital')['Year'].nunique()
hospitals_with_full_span = hospitals_with_full_span[hospitals_with_full_span == 11].index

# Filter the dataframe to include only those hospitals
df_filtered = df_filtered[df_filtered['Hospital'].isin(hospitals_with_full_span)]

# Group by year and sum the values of the specified column
yearly_sum = df_filtered.groupby('Year')['All presentations'].sum()

# Plot the results
plt.figure(figsize=(10, 6))
yearly_sum.plot(kind='bar')
plt.xlabel('Year')
plt.ylabel('Sum of Values')
plt.title('Sum of Values by Year (2013-2023)')
plt.show()