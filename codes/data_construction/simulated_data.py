import numpy as np
import networkx as nx
import leidenalg
import igraph as ig
import time
import matplotlib.pyplot as plt

def generate_stochastic_block_model(sizes, p_in, p_out):
    """
    Generate a graph using the Stochastic Block Model.

    Parameters:
        sizes (list of int): Sizes of each community.
        p_in (float): Probability of edges within the same community.
        p_out (float): Probability of edges between different communities.

    Returns:
        G (networkx.Graph): Generated graph.
    """
    # Number of nodes and communities
    num_nodes = sum(sizes)

    # Create an empty adjacency matrix
    adj_matrix = np.zeros((num_nodes, num_nodes))

    # Assign nodes to communities
    community_indices = []
    start = 0
    for size in sizes:
        community_indices.append(range(start, start + size))
        start += size

    # Fill the adjacency matrix
    for i in range(num_nodes):
        for j in range(i, num_nodes):
            # Determine if nodes i and j are in the same community
            same_community = any(i in community and j in community for community in community_indices)
            
            # Assign edge based on probabilities
            if same_community:
                if np.random.rand() < p_in:
                    adj_matrix[i, j] = adj_matrix[j, i] = 1
            else:
                if np.random.rand() < p_out:
                    adj_matrix[i, j] = adj_matrix[j, i] = 1

    # Create a graph from the adjacency matrix
    G = nx.from_numpy_array(adj_matrix)
    return G


# Total Dutch population: 18,038,726 million (CBS)
# 21% of the population is under 20 years old, 5% is over 80 years old
# Lets say we have a total of (1-0.21-0.05)*18,038,726 = 13,348,657 people
# This is the number of nodes -> we need to split this number across communities
# We have the spatial distrivution of the population (neighborhoods)

community_sizes = [10, 15, 20]  # Sizes of the three communities , 10, 15, 20, 10, 15, 20
p_within = 0.75  # Probability of edges within communities
p_between = 0.25  # Probability of edges between communities

# Generate SBM graph
sbm_graph = generate_stochastic_block_model(community_sizes, p_within, p_between)

# Draw the graph
plt.figure(figsize=(8, 6))
pos = nx.spring_layout(sbm_graph, seed=42)  # Layout for visualization
node_colors = []
for i, size in enumerate(community_sizes):
    node_colors.extend([i] * size)
nx.draw(sbm_graph, pos, with_labels=True, node_color=node_colors, cmap=plt.cm.tab10, node_size=500, font_size=10)
plt.title("Stochastic Block Model Graph")
plt.show()




G = ig.Graph.Erdos_Renyi(100, 0.1)

part = leidenalg.find_partition(G, leidenalg.ModularityVertexPartition)
fig, ax=plt.subplots()
ig.plot(part, target=ax)
plt.show()

G_nx = ig.Graph.from_networkx(sbm_graph)

part_nx = leidenalg.find_partition(G_nx, leidenalg.ModularityVertexPartition)
fig, ax=plt.subplots()
ig.plot(part_nx, target=ax)
plt.show()


def generate_stochastic_block_model_lists(sizes, p_in, p_out):
    """
    Generate a graph using the Stochastic Block Model.

    Parameters:
        sizes (list of int): Sizes of each community.
        p_in (float): Probability of edges within the same community.
        p_out (float): Probability of edges between different communities.

    Returns:
        G (networkx.Graph): Generated graph.
    """
    # Number of nodes and communities
    num_nodes = sum(sizes)

    # Assign nodes to communities
    community_indices = []
    start = 0
    for size in sizes:
        community_indices.append(range(start, start + size))
        start += size

    # Create an empty graph
    edges = []

    # Fill edges based on probabilities
    for i in range(num_nodes):
        for j in range(i + 1, num_nodes):
            # Determine if nodes i and j are in the same community
            same_community = any(i in community and j in community for community in community_indices)
            
            # Assign edge based on probabilities
            if same_community:
                if np.random.rand() < p_in:
                    edges.append((i, j))
            else:
                if np.random.rand() < p_out:
                    edges.append((i, j))

    # Create a graph from the edges
    G = nx.Graph()
    G.add_edges_from(edges)
    return G

community_sizes = [10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20]  # Sizes of the three communities 
p_within = 0.75  # Probability of edges within communities
p_between = 0.25  # Probability of edges between communities

# Generate SBM graph
sbm_graph = generate_stochastic_block_model_lists(community_sizes, p_within, p_between)

# Draw the graph
plt.figure(figsize=(8, 6))
pos = nx.spring_layout(sbm_graph, seed=42)  # Layout for visualization
node_colors = []
for i, size in enumerate(community_sizes):
    node_colors.extend([i] * size)
nx.draw(sbm_graph, pos, with_labels=True, node_color=node_colors, cmap=plt.cm.tab10, node_size=500, font_size=10)
plt.title("Stochastic Block Model Graph")
plt.show()


# Measure the average time taken by generate_stochastic_block_model over 100 iterations
times = []
for _ in range(500):
    start_time = time.time()
    _ = generate_stochastic_block_model(community_sizes, p_within, p_between)
    end_time = time.time()
    times.append(end_time - start_time)
print(f"Average time taken by generate_stochastic_block_model: {np.mean(times):.4f} seconds")

# Measure the average time taken by generate_stochastic_block_model_lists over 100 iterations
times = []
for _ in range(500):
    start_time = time.time()
    _ = generate_stochastic_block_model_lists(community_sizes, p_within, p_between)
    end_time = time.time()
    times.append(end_time - start_time)
print(f"Average time taken by generate_stochastic_block_model_lists: {np.mean(times):.4f} seconds")

#sizes = [10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20, 10, 15, 20]
probs = [[0.75 if i == j else 0.25 for j in range(len(community_sizes))] for i in range(len(community_sizes))]
g = nx.stochastic_block_model(community_sizes, probs, seed=0)

times = []
for _ in range(500):
    start_time = time.time()
    _ = nx.stochastic_block_model(community_sizes, probs, seed=0)
    end_time = time.time()
    times.append(end_time - start_time)
print(f"Average time taken by generate_stochastic_block_model_lists: {np.mean(times):.4f} seconds")