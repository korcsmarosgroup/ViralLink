# 1. betweenness_and_clustering.R

Script to calculate betweenness centrality and identify clusters (using MCODE) in directed causal network.
REQUIRES CYTOSCAPE PROGRAM TO BE OPEN TO RUN CLUSTERING - if not open the clustering will be skipped

**Input:**
* Directed causal network output from 'combined_edge_node_tables.R'
*Node table output from 'combined_edge_node_tables.R'

**Output:**
* Updated node table with new column for betweenness centrality and, if MCODE successfully ran, 3 new columns with MCODE results.

**Run from command line:**

```
Rscript betweenness_and_clustering.R intracellular_network.txt node_table.txt output_directory/
```

# 2. cytoscape_visualisation.R

Script to create Cytoscape file containing each of the networks (whole causal network and network clusters - if calculated). REQUIRES CYTOSCAPE PROGRAM TO BE OPEN - will skip otherwise.

**Input:**
* Directed causal network output from 'combined_edge_node_tables.R'
* Node table output from 'betweenness_and_clustering.R' (with or without cluster labels)

**Output:**
* Cytoscape file containing the whole causal network and cluster networks (if cluster annotations calculated previously)

**Run from command line:**

```
Rscript cytoscape_visualisation.R intracellular_network.txt node_table_betweenness_clustering.txt output_directory/
```
