import pandas as pd
import leidenalg as la
import igraph as ig

# Accessing a compressed txt file using pandas
compressed_file_path = 'C:/Users/guill/Downloads/soc-LiveJournal1.txt.gz'
df_compressed = pd.read_csv(compressed_file_path, compression='gzip', sep='\t', skiprows=3)
df_compressed.columns = ['FromNodeId', 'ToNodeId']

# Display the first few rows of the dataframe
print(df_compressed)

# Convert the dataframe to an igraph object
edges = list(zip(df_compressed['FromNodeId'], df_compressed['ToNodeId']))
ig_compressed = ig.Graph(edges=edges, directed=True)

# Find the optimal partition using the Leiden algorithm
ig_partition = la.find_partition(ig_compressed, la.ModularityVertexPartition)