import pandas as pd
#import leidenalg as la
import networkx as nx
import igraph as ig
import numpy as np
from sklearn.cluster import KMeans
#from scipy.sparse import csr_matrix
#import json
#import dask.dataframe as dd
import matplotlib.pyplot as plt

np.random.seed(666)

community_sizes = [10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 20]
probs = [[0.75 if i == j else 0.25 for j in range(len(community_sizes))] for i in range(len(community_sizes))]
g_nx = nx.stochastic_block_model(community_sizes, probs, seed=0)
g_ig = ig.Graph.from_networkx(g_nx)

# Apply k-means clustering
kmeans = KMeans(n_clusters = len(community_sizes), random_state=42)
g_ig_adjacency = g_ig.get_adjacency()
kmeans.fit(g_ig_adjacency)

# Assign the cluster labels to the nodes
g_ig.vs['kmeans_cluster'] = kmeans.labels_.tolist()

# DataFrame
df = g_ig.get_vertex_dataframe().reset_index()
df['index'] = df.index
df = df[['index', 'block','kmeans_cluster']]
df['adjacency'] = g_ig.get_adjlist()

# 9 is the cluster of choice
# shock_in_cluster = [5, 8, 9, 13, 18]
shock_in_cluster = np.random.choice(range(30), 10, replace=False)

def compute_relative_exposure(df, cluster_label):
    cluster_nodes = df['index'].tolist()
    exposure_counts = {node: 0 for node in cluster_nodes}
    
    for node in cluster_nodes:
        neighbors = df.loc[node, 'adjacency']
        exposure_counts[node] = sum(1 for neighbor in neighbors if df.loc[neighbor, 'kmeans_cluster'] in cluster_label)
    
    relative_exposure = {node: exposure_counts[node] / len(df.loc[node, 'adjacency']) for node in cluster_nodes}
    return relative_exposure

df['relative_exposure'] = compute_relative_exposure(df, shock_in_cluster)

average_exposure = df.groupby('kmeans_cluster')['relative_exposure'].mean().reset_index()
average_exposure.columns = ['kmeans_cluster', 'average_exposure']
df = pd.merge(df, average_exposure, on='kmeans_cluster', how='left')

# Create copies of the dataset for multiple time periods
time_periods = 10  # Define the number of time periods
dfs = []

for t in range(time_periods):
    df_time = df.copy()
    df_time['time'] = t
    dfs.append(df_time)

# Concatenate the datasets for all time periods
df = pd.concat(dfs, ignore_index=True)

df['treatment'] = df['average_exposure']
df.loc[df['kmeans_cluster'].isin(shock_in_cluster),'treatment'] = 1 
df.loc[~df['time'].isin([5,6]), 'treatment'] = 0 
df

# HOSPITALIZATIONS GENERATING PROCESS
r = 1     # Number of successes
p = 0.8   # Probability of success
p_alt = 0.99   # Probability of success
df['hospitalizations'] = (1 - 0.9*df['treatment'])*np.random.negative_binomial(r, p, size=len(df))

# Calculate the number of nodes in each cluster
cluster_sizes = df.groupby('kmeans_cluster')['index'].count().reset_index()
cluster_sizes.columns = ['kmeans_cluster', 'cluster_size']

# Merge the cluster sizes with the main dataframe
df = pd.merge(df, cluster_sizes, on='kmeans_cluster', how='left')

# Calculate hospitalizations per capita
df['hospitalizations_per_capita'] = df['hospitalizations'] / df['cluster_size']
df['cluster_treated'] = 1 * (df['kmeans_cluster'].isin(shock_in_cluster))


df.to_csv(r'./data/processed/simulations/simulated_data_simple_1.csv', index=False)

# Calculate hospitalizations for the shock cluster and the rest separately for each time period
hospitalizations_shock = df[df['kmeans_cluster'].isin(shock_in_cluster)].groupby('time')['hospitalizations_per_capita'].agg(['mean', 'sem']).reset_index()
hospitalizations_rest = df[~df['kmeans_cluster'].isin(shock_in_cluster)].groupby('time')['hospitalizations_per_capita'].agg(['mean', 'sem']).reset_index()

# Plot the evolution in hospitalizations for the shock cluster and the rest over time periods with error bars
plt.errorbar(hospitalizations_shock['time'], hospitalizations_shock['mean'], yerr=hospitalizations_shock['sem'], marker='o', color='red', label='Shock Cluster', capsize=5)
plt.errorbar(hospitalizations_rest['time'], hospitalizations_rest['mean'], yerr=hospitalizations_rest['sem'], marker='o', color='blue', label='Rest', capsize=5)

plt.xlabel('Time')
plt.ylabel('Hospitalizations per capita')
plt.title('Evolution of Hospitalizations from t=0 to t=1')
plt.legend()
plt.show()

# Plot histogram for 'treatment'
plt.figure(figsize=(10, 6))
plt.hist(df.loc[(df['treatment'] != 1) & ~(df['time'].isin(shock_in_cluster)),'treatment'], color='skyblue', edgecolor='black')
plt.xlabel('Treatment')
plt.ylabel('Frequency')
plt.title('Histogram of Treatment')
plt.show()


shock_rest_1 = df.loc[df['treatment'].between(0.33, 1, inclusive='neither'), 'kmeans_cluster'].unique()
shock_rest_2 = df.loc[df['treatment'].between(0, 0.33, inclusive='right'), 'kmeans_cluster'].unique()
   
hospitalizations_rest_1 = df[df['kmeans_cluster'].isin(shock_rest_1)].groupby('time')['hospitalizations_per_capita'].agg(['mean', 'sem']).reset_index()
hospitalizations_rest_2 = df[df['kmeans_cluster'].isin(shock_rest_2)].groupby('time')['hospitalizations_per_capita'].agg(['mean', 'sem']).reset_index()

# Plot the evolution in hospitalizations for the shock cluster and the rest over time periods
plt.errorbar(hospitalizations_shock['time'], hospitalizations_shock['mean'], yerr=hospitalizations_shock['sem'], marker='o', color='red', label='Shock Cluster')
plt.errorbar(hospitalizations_rest_1['time'], hospitalizations_rest_1['mean'], hospitalizations_rest_1['sem'], marker='o', color='blue', label='Close')
plt.errorbar(hospitalizations_rest_2['time'], hospitalizations_rest_2['mean'], hospitalizations_rest_2['sem'], marker='o', color='green', label='Rest')

plt.xlabel('Time')
plt.ylabel('Hospitalizations per capita')
plt.title('Evolution of Hospitalizations from t=0 to t=1')
plt.legend()
plt.show()

plt.plot(hospitalizations_shock['time'], hospitalizations_rest['mean'] - hospitalizations_shock['mean'], marker='o', color='red', label='Shock Cluster')
plt.xlabel('Time')
plt.ylabel('Hospitalizations per capita')
plt.title('Evolution of Hospitalizations from t=0 to t=1')
plt.legend()
plt.show()

hospitalizations_shock = df[df['kmeans_cluster'].isin(shock_in_cluster)].groupby('time')['hospitalizations'].agg(['mean', 'sem']).reset_index()
hospitalizations_rest_1 = df[df['kmeans_cluster'].isin(shock_rest_1)].groupby('time')['hospitalizations'].agg(['mean', 'sem']).reset_index()
hospitalizations_rest_2 = df[df['kmeans_cluster'].isin(shock_rest_2)].groupby('time')['hospitalizations'].agg(['mean', 'sem']).reset_index()
# Plot the evolution in hospitalizations for the shock cluster and the rest over time periods
plt.errorbar(hospitalizations_shock['time'], hospitalizations_shock['mean'], yerr=hospitalizations_shock['sem'], marker='o', color='red', label='Shock Cluster')
plt.errorbar(hospitalizations_rest_1['time'], hospitalizations_rest_1['mean'], hospitalizations_rest_1['sem'], marker='o', color='blue', label='Close')
plt.errorbar(hospitalizations_rest_2['time'], hospitalizations_rest_2['mean'], hospitalizations_rest_2['sem'], marker='o', color='green', label='Rest')
plt.xlabel('Time')
plt.ylabel('Hospitalizations per capita')
plt.title('Evolution of Hospitalizations from t=0 to t=1')
plt.legend()
plt.show()
