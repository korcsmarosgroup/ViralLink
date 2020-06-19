# Author : Agatha Treveil
# Date : June 2020
#
# Script to calculate betweenness centrality and identify clusters (using MCODE) in directed causal network.
# REQUIRES CYTOSCAPE PROGRAM TO BE OPEN TO RUN CLUSTERING - if not open the clustering will be skipped
#
# Input: Directed causal network output from 'combined_edge_node_tables.R'
#        Node table output from 'combined_edge_node_tables.R'
#
# Output: Updated node table with new column for betweenness centrality and, if MCODE successfully ran, 
#         3 new columns with MCODE results.

##### Setup #####

# Capture  messages and errors to a file.
zz <- file("all.Rout", open="a")
sink(zz, type="message", append = TRUE)
message("\nStarting betweenness + clustering: betweenness_and_clustering.R\n")

# Install requried packages
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
if (!requireNamespace("RCy3", quietly = TRUE)) 
  BiocManager::install("RCy3")
if (!requireNamespace("tidyverse", quietly = TRUE)) 
  install.packages("tidyverse")
if (!requireNamespace("igraph", quietly = TRUE)) 
  install.packages("igraph")

# Load packages
library(tidyverse)
library(RCy3)
library(igraph)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

# Check length of command line parameters
if (length(args) != 3){
  stop("Wrong number of command line input parameters. Please check.")
}

outdir <- args[3]

# Directed causal network output from 'combined_edge_node_tables.R'
net <- read.csv(args[1], sep = "\t")
  
# Node table output from 'combined_edge_node_tables.R'
nodes <- read.csv(args[2], sep = "\t")

# Create output dir if required
path <- file.path(outdir, "5_betweenness_and_cluster_analysis")
dir.create(path, showWarnings = FALSE, recursive=TRUE)

##### Betweenness centrality #####

# Convert to igraph network
i_net <- graph_from_data_frame(net, directed=TRUE)

# Calculate node betweenness values
betweenness_res <- betweenness(i_net, v = V(i_net), directed = TRUE, weights = NULL,
            nobigint = TRUE, normalized = FALSE)

# Get into dataframe
betweenness_res2 <- data.frame(betweenness_centrality=sort(betweenness_res, decreasing=TRUE)) %>% tibble::rownames_to_column()

# Add to node table
nodes_2 <- left_join(nodes, betweenness_res2, by = c("node"="rowname"))

##### Clustering #####

cytoscape_func <- function(i_net){
  # Function to carry out MCODE clustering and export MCODE node annotations
  # Only to be run if already checked that the script can connect to cytoscape >= v7
  # Returns node table with MCODE results - or empty table if couldn't get MCODE running
  
  # Install MCODE all
  install_error <- FALSE
  tryCatch({installApp("MCODE")}, error=function(e) {install_error <<- TRUE})
  
  # Only continue if success installing MCODE, else print error
  if (install_error){
    print('Error installing MCODE app - skipping MCODE clustering')
    clust_res <- ""
  } else {

    # Import network into igraph
    createNetworkFromIgraph(i_net,"whole_network")

    # Carry out clustering
    commandsRun('mcode cluster degreeCutoff=2 fluff=FALSE haircut=TRUE nodeScoreCutoff=0.2 kCore=2 maxDepthFromStart=100')
    
    # Wait for Cytoscape to catch up
    Sys.sleep(60)
    
    ###### PROBLEMS ##########
    
    # Get results as table ## POSSIBLE BUG IN RCY3 as the MCODE_Cluster col is mixed up???
    #clust_res <- getTableColumns(table="node",columns=c("name", "MCODE_Node_Status", "MCODE_Score","MCODE_Cluster"))
    
    # Instead get just the clustered/seed nodes and export node table - downside of this appraoch is we can't keep the cluster 
    # values for the unclustered data 
    selectNodes("unclustered", by.col = "MCODE_Node_Status", network="whole_network")
    deleteSelectedNodes(network = "whole_network")
    
    # Creating subnetwork also doesn't appear to work  - another bug?
    #selectEdgesConnectingSelectedNodes(network="whole_network")
    #createSubnetwork(subnetwork.name = "clustered_nodes", network="whole_network")
    
    # Export subnetwork node table
    clust_res <- getTableColumns(table="node",columns=c("name", "MCODE_Node_Status", "MCODE_Score","MCODE_Cluster"))
    
  }
  
  # Close cytoscape session
  closeSession(FALSE)
  
  return(clust_res)
}

# See if cytoscape is open and >= v7
cyto_error <- FALSE
tryCatch( {msg <- cytoscapePing () } , error = function(e) {cyto_error <<- TRUE})

if (!cyto_error){
  if (cytoscapeVersionInfo ()[2] >= 3.7){
    continue = TRUE
    print('Successfully connected to Cytoscape - carrying out MCODE clustering and creating Cytoscape file')
  } else {
    continue = FALSE
    print('Successfully connected to Cytscape BUT version not >= 3.7 - skipping MCODE clustering and creation of Cytoscape file')
  }
} else {
  continue = FALSE
  print('Could not connect to Cytoscape - skipping MCODE clustering and creation of Cytoscape file')
}

# Run clustering if cytoscape open and new enough - and RCy3 app new enough (error getting MCODE results if 'its not')
if(continue & (packageVersion("RCy3") >= "2.6.0")){
  
  # Call function to run MCODE
  results <- cytoscape_func(i_net)

  # If there are results in the table then MCODE ran
  if(results != ""){
    # Un-list the MCODE_cluster column
    results2 <- results %>% unnest(MCODE_Cluster) %>% group_by(name) %>% mutate(MCODE_Cluster = paste0(MCODE_Cluster, collapse = ";")) 
    
    # Join the mcode cluster results to the node table
    nodes_3 <- left_join(nodes_2, results2, by = c("node"="name"))
    
  } else {
    # If MCODE couldn't install then there won't be any results
    nodes_3 <- nodes_2
  }
} else {
  # If Cytoscape wasn't open (or too old) then there won't be any results
  nodes_3 <- nodes_2
}

##### Save output #####

# Save updated node table
write.table(nodes_3, file=file.path(path, "node_table_betweenness_clusters.txt"), row.names = FALSE, quote = FALSE, sep = "\t")

# reset message sink and close the file connection
sink(type="message")
close(zz)
