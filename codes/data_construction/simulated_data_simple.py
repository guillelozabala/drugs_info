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

community_sizes = [10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20]
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
df = g_ig.get_vertex_dataframe()
df['index'] = df.index
df = df[['index', 'block','kmeans_cluster']]
df['adjacency'] = g_ig.get_adjlist()

# 9 is the cluster of choice
shock_in_cluster = 9

def compute_relative_exposure(df, cluster_label):
    #cluster_nodes = df[df['kmeans_cluster'] == cluster_label]['index'].tolist()
    cluster_nodes = df['index'].tolist()
    #total_nodes = len(df)
    exposure_counts = {node: 0 for node in cluster_nodes}
    
    for node in cluster_nodes:
        neighbors = df.loc[node, 'adjacency']
        exposure_counts[node] = sum(1 for neighbor in neighbors if df.loc[neighbor, 'kmeans_cluster'] == cluster_label)
    
    relative_exposure = {node: exposure_counts[node] / len(df.loc[node, 'adjacency']) for node in cluster_nodes}
    return relative_exposure
    #return cluster_nodes

df['relative_exposure'] = compute_relative_exposure(df, shock_in_cluster)

average_exposure = df.groupby('kmeans_cluster')['relative_exposure'].mean().reset_index()
average_exposure.columns = ['kmeans_cluster', 'average_exposure']
df = pd.merge(df, average_exposure, on='kmeans_cluster', how='left')

# Create two copies of the dataset with different time periods
df_time_0 = df.copy()
df_time_0['time'] = 0

df_time_1 = df.copy()
df_time_1['time'] = 1

# Concatenate the two datasets
df = pd.concat([df_time_0, df_time_1], ignore_index=True)

df['treatment'] = df['average_exposure']
df.loc[df['kmeans_cluster'] == shock_in_cluster,'treatment'] = 1 
df.loc[df['time'] == 0, 'treatment'] = 0 
df

# HOSPITALIZATIONS GENERATING PROCESS
r = 1     # Number of successes
p = 0.9   # Probability of success
p_alt = 0.99   # Probability of success
df['hospitalizations'] = (1 - df['treatment'])*np.random.negative_binomial(r, p, size=len(df))

sum(df['hospitalizations'])


# plt.hist(df.loc[(df['time'] == 1)&(df['treatment'] != 1), 'treatment'].sort_values(), edgecolor='black')
# plt.show()

# Plot the evolution in hospitalizations from t=0 to t=1
hospitalizations_time_0 = df[df['time'] == 0]['hospitalizations'].sum()
hospitalizations_time_1 = df[df['time'] == 1]['hospitalizations'].sum()

plt.bar(['t=0', 't=1'], [hospitalizations_time_0, hospitalizations_time_1], color=['blue', 'orange'])
plt.xlabel('Time')
plt.ylabel('Total Hospitalizations')
plt.title('Evolution of Hospitalizations from t=0 to t=1')
plt.show()