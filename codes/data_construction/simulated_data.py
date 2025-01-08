import pandas as pd
import leidenalg as la
import igraph as ig
import numpy as np
from sklearn.cluster import KMeans
from scipy.sparse import csr_matrix
import json
import dask.dataframe as dd
import matplotlib.pyplot as plt

file_path = r'./data/source/simulated/soc-LiveJournal1.txt.gz'
df = pd.read_csv(file_path, compression='gzip', sep='\t', skiprows=3)
df.columns = ['FromNodeId', 'ToNodeId']

# Convert the dataframe to an igraph object
edges = list(zip(df['FromNodeId'], df['ToNodeId']))
graph = ig.Graph(edges=edges, directed=True)

# Apply the k-means algorithm

# Extract the adjacency matrix of the graph
# adj_matrix = graph.get_adjacency_sparse()
adj_list = graph.get_adjlist()
# Save the adjacency list as a JSON file
with open(r'./data/source/simulated/adj_list.json', 'w') as f:
    json.dump(adj_list, f)

# Load the adjacency list from the JSON file
with open(r'./data/source/simulated/adj_list.json', 'r') as f:
    adj_list = json.load(f)

import h5py

# Save the adjacency list as an HDF5 file
with h5py.File(r'./data/source/simulated/adj_list.h5', 'w') as f:
    for i, neighbors in enumerate(adj_list):
        f.create_dataset(str(i), data=neighbors)

# Load the adjacency list from the HDF5 file
adj_list = []
with h5py.File(r'./data/source/simulated/adj_list.h5', 'r') as f:
    for i in range(len(f.keys())):
        adj_list.append(list(f[str(i)]))

# Convert the adjacency list to a sparse matrix
rows = []
cols = []
data = []

for i, neighbors in enumerate(adj_list):
    for neighbor in neighbors:
        rows.append(i)
        cols.append(neighbor)
        data.append(1)

adj_sparse_matrix = csr_matrix((data, (rows, cols)), shape=(graph.vcount(), graph.vcount()))
# Save the sparse matrix to a file
sparse_matrix_file = r'./data/source/simulated/adj_sparse_matrix.npz'
np.savez_compressed(sparse_matrix_file, data=adj_sparse_matrix.data, indices=adj_sparse_matrix.indices, indptr=adj_sparse_matrix.indptr, shape=adj_sparse_matrix.shape)


sparse_matrix_file = r'./data/source/simulated/adj_sparse_matrix.npz'
# Load the sparse matrix from the file
loaded = np.load(sparse_matrix_file)
adj_sparse_matrix = csr_matrix((loaded['data'], loaded['indices'], loaded['indptr']), shape=loaded['shape'])

# Apply k-means clustering
kmeans = KMeans(n_clusters=40, random_state=42)
kmeans.fit(adj_sparse_matrix)

# Assign the cluster labels to the nodes
graph.vs['kmeans_cluster'] = kmeans.labels_.tolist()
# Save the igraph object to a file
graph.write_pickle(r'./data/source/simulated/graph.pkl')

# Load the igraph object from the file
graph = ig.Graph.Read_Pickle(r'./data/source/simulated/graph.pkl')

# Louviain method/algorithm
def create_clusters_data():
    # Accessing a compressed txt file using pandas
    compressed_file_path = r'./data/source/simulated/soc-LiveJournal1.txt.gz'
    df_compressed = pd.read_csv(compressed_file_path, compression='gzip', sep='\t', skiprows=3)
    df_compressed.columns = ['FromNodeId', 'ToNodeId']

    # Convert the dataframe to an igraph object
    edges = list(zip(df_compressed['FromNodeId'], df_compressed['ToNodeId']))
    ig_compressed = ig.Graph(edges=edges, directed=True)

    # Find the optimal partition using the Leiden algorithm
    ig_partition = la.find_partition(ig_compressed, la.ModularityVertexPartition)

    # Get the index of the membership vector as a list
    membership_index = list(range(len(ig_partition.membership)))

    # Create a dataframe from the membership vector
    membership_df = pd.DataFrame({
        'FromNodeId': membership_index,
        'Cluster': ig_partition.membership
    })

    membership_df_to = pd.DataFrame({
        'ToNodeId': membership_index,
        'Cluster_To': ig_partition.membership
    })

    # Convert the pandas dataframes to dask dataframes
    ddf_compressed = dd.from_pandas(df_compressed, npartitions=8)
    ddf_membership_df = dd.from_pandas(membership_df, npartitions=8)
    ddf_membership_df_to = dd.from_pandas(membership_df_to, npartitions=8)

    # Merge the dask dataframes
    ddf_merged = dd.merge(ddf_compressed, ddf_membership_df, on='FromNodeId', how='left')
    ddf_merged = dd.merge(ddf_merged, ddf_membership_df_to, on='ToNodeId', how='left')

    # Compute the final dataframe
    df_merged = ddf_merged.compute()

    # Save the dataframe to a csv file
    df_merged.to_csv(r'./data/source/simulated/soc-LiveJournal1-partition.csv', index=False)

    # Load the dataframe from the csv file
    df_merged = pd.read_csv(r'./data/source/simulated/soc-LiveJournal1-partition.csv')
    df_merged

    # Add a column for intra-cluster edges
    df_merged['IntraCluster'] = (df_merged['Cluster'] == df_merged['Cluster_To']).astype(int)

    # Sort the values of 'FromNodeId' and order df_merged accordingly
    df_merged = df_merged.sort_values(by=['FromNodeId', 'ToNodeId']).reset_index(drop=True)

    # Compute the relative presence of different values of 'Cluster_To' for each 'Cluster'
    relative_presence = df_merged.groupby(['Cluster', 'Cluster_To']).size().reset_index(name='Count')
    total_edges = df_merged.groupby('Cluster').size().reset_index(name='TotalEdges')
    relative_presence = pd.merge(relative_presence, total_edges, on='Cluster')
    relative_presence['RelativePresence'] = relative_presence['Count'] / relative_presence['TotalEdges']

    # Merge the relative presence into the main dataframe
    df_merged = pd.merge(df_merged, relative_presence[['Cluster', 'Cluster_To', 'RelativePresence']], on=['Cluster', 'Cluster_To'], how='left')

    # Save the updated dataframe to a csv file
    df_merged.to_csv(r'./data/source/simulated/soc-LiveJournal1-partition-intracluster.csv', index=False)

# Load the clusters from the csv file
df_clusters = pd.read_csv(r'./data/source/simulated/soc-LiveJournal1-partition-intracluster.csv')
df_clusters

# Find the nodes that are the farthest apart in the network
def find_farthest_nodes(graph):
    max_distance = 0
    farthest_nodes = (None, None)
    for v in range(graph.vcount()):
        shortest_paths = graph.distances(v)[0]
        farthest_node = np.argmax(shortest_paths)
        distance = shortest_paths[farthest_node]
        if distance > max_distance:
            max_distance = distance
            farthest_nodes = (v, farthest_node)
    return farthest_nodes

compressed_file_path = r'./data/source/simulated/soc-LiveJournal1.txt.gz'
df_compressed = pd.read_csv(compressed_file_path, compression='gzip', sep='\t', skiprows=3)
df_compressed.columns = ['FromNodeId', 'ToNodeId']

# Convert the dataframe to an igraph object
edges = list(zip(df_compressed['FromNodeId'], df_compressed['ToNodeId']))
ig_compressed = ig.Graph(edges=edges, directed=True)

# Add a column for the farthest nodes
farthest_nodes = find_farthest_nodes(ig_compressed)
df_clusters['FarthestNodes'] = [farthest_nodes] * len(df_clusters)

# Set a seed for reproducibility
np.random.seed(42)

# Extract unique ids and clusters
data_ids = df_clusters[['FromNodeId', 'Cluster']].drop_duplicates().reset_index(drop=True)
data_ids.columns = ['id', 'cluster']

# Generate all combinations of ids, clusters, and years
years = range(2010, 2020)

# Expand the DataFrame with all years for each id-cluster pair
data = (
    data_ids
    .assign(key=1)  # Temporary key for cross join
    .merge(pd.DataFrame({'year': years, 'key': 1}), on='key')
    .drop(columns='key')  # Remove temporary key
)

# Randomly pick 20% of the clusters to be faulty in 2014
clusters = data['cluster'].unique()
np.random.shuffle(clusters)
faulty_clusters = clusters[:int(0.2 * len(clusters))]

data['faulty'] = data['cluster'].isin(faulty_clusters)
random_year = np.random.choice(years)
data['red_alert'] = (data['year'] == random_year) & (data['faulty'] == True)

r = 1     # Number of successes
p = 0.99995   # Probability of success
data['hospitalizations'] = (1 - (data['red_alert'] == True))*np.random.negative_binomial(r, p, size=len(data))

data

# Aggregate at the cluster level
cluster_aggregates = data.groupby(['cluster', 'year', 'faulty', 'red_alert']).agg(
    total_ids=('id', 'count'),
    total_hospitalizations=('hospitalizations', 'sum'),
).reset_index()

cluster_aggregates['hospitalization_rate'] = (cluster_aggregates['total_hospitalizations'] / cluster_aggregates['total_ids'])*100000

cluster_aggregates

# Plot the data
plt.figure(figsize=(12, 6))
for faulty in [True, False]:
    subset = cluster_aggregates[cluster_aggregates['faulty'] == faulty].copy()
    subset['avg_hospitalizations'] = subset.groupby('year')['total_hospitalizations'].transform('mean')
    subset['sd_hospitalizations'] = subset.groupby('year')['total_hospitalizations'].transform('std')
    subset['number_of_clusters'] = subset.groupby('year')['cluster'].transform('nunique')
    subset = subset.drop_duplicates(subset=['year'])
    label = 'Faulty Clusters' if faulty else 'Non-Faulty Clusters'
    plt.plot(subset['year'], subset['avg_hospitalizations'], label=label, marker='o')
    plt.fill_between(
        subset['year'],
        subset['avg_hospitalizations'] - 1.96 * subset['sd_hospitalizations']/np.sqrt(subset['number_of_clusters']),
        subset['avg_hospitalizations'] + 1.96 * subset['sd_hospitalizations']/np.sqrt(subset['number_of_clusters']),
        alpha=0.2
    )
plt.xlabel('Year')
plt.ylabel('Average Total Hospitalizations')
plt.title('Average Total Hospitalizations per Cluster Across Years')
plt.legend()
plt.grid(True)
plt.show()



# # Find clusters not connected to cluster 5
# cluster_5_edges = df_clusters[df_clusters['Cluster'] == 5]
# connected_clusters = set(cluster_5_edges['Cluster_To'].unique())
# all_clusters = set(df_clusters['Cluster'].unique())
# not_connected_clusters = all_clusters - connected_clusters

# print("Clusters not connected to cluster 5:", not_connected_clusters)

# Create a dictionary where each key is a cluster and the value is the set of clusters not connected to it
not_connected_dict = {}
for cluster in clusters:
    cluster_edges = df_clusters[df_clusters['Cluster'] == cluster]
    connected_clusters = set(cluster_edges['Cluster_To'].unique())
    all_clusters = set(df_clusters['Cluster'].unique())
    not_connected_clusters = all_clusters - connected_clusters
    not_connected_dict[cluster] = not_connected_clusters

df_clusters[df_clusters['Cluster'] == 5]
not_connected_dict[0]