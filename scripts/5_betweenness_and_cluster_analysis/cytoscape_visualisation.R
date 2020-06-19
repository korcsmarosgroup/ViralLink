# Author : Agatha Treveil
# Date : June 2020
#
# Script to create Cytoscape file containing each of the networks (whole causal network and 
# network clusters - if calculated). REQUIRES CYTOSCAPE PROGRAM TO BE OPEN - will skip otherwise.
#
# Input: Directed causal network output from 'combined_edge_node_tables.R'
#        Node table output from 'betweenness_and_clustering.R' (with or without cluster labels)
#
# Output: Cytoscape file containing the whole causal network and cluster networks (if cluster annotations calculated previously)

##### Setup #####

# Capture  messages and errors to a file.
zz <- file("all.Rout", open="a")
sink(zz, type="message", append = TRUE)
message("\nStarting visualisation: cytoscape_visualisation.R\n")

# Install required packages
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
if (!requireNamespace("RCy3", quietly = TRUE)) 
  BiocManager::install("RCy3")
if (!requireNamespace("tidyverse", quietly = TRUE)) 
  install.packages("tidyverse")

# Load packages
library(tidyverse)
library(RCy3)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

# Check length of command line parameters
if (length(args) != 3){
  stop("Wrong number of command line input parameters. Please check.")
}

# Output directory
outdir <- args[3]

# Directed causal network output from 'combined_edge_node_tables.R'
net <- read.csv(args[1], sep = "\t")

# Node table output from 'betweenness_and_clustering.R'
nodes <- read.csv(args[2], sep = "\t")

# Create output dir if required
path <- file.path(outdir, "5_betweenness_and_cluster_analysis")
dir.create(path, showWarnings = FALSE, recursive=TRUE)

##### Preprocess #####

net2 <- net %>% dplyr::rename("source"= "Source.node", "target"="Target.node", "interaction"="Relationship")
nodes2 <- nodes %>% dplyr::rename("id" = "node")

# Determine if clustering has been carried out
if("MCODE_Cluster" %in% colnames(nodes2)){
  cluster = TRUE
  clus_filt <- nodes2 %>% dplyr::select(MCODE_Cluster) %>% group_by(MCODE_Cluster) %>% count() %>% filter(MCODE_Cluster != "NA")
} else {
  cluster = FALSE
}

# Determine if betweenness centrality calcualtions have been carried out
if("betweenness_centrality" %in% colnames(nodes2)){
  bet = TRUE
} else {
  bet=FALSE 
}

##### Import into Cytoscape #####

# See if cytoscape is open
cyto_error <- FALSE
tryCatch( {msg <- cytoscapePing () } , error = function(e) {cyto_error <<- TRUE})

if (!cyto_error){
  continue = TRUE
  print('Successfully connected to Cytoscape - continuing with visualisation')
} else {
  continue = FALSE
  print('Could not connect to Cytoscape - skipping visualisation')
}

# Run visualisation if cytoscape open
if(continue){
  # Add network to cytoscape - sometimes not working as in 'https://github.com/cytoscape/RCy3/issues/81'
  #createNetworkFromDataFrames(nodes2,net2, title="causal network")
  # Here is a workaround
  createNetworkFromDataFrames(nodes2, edges=net2[,1:2], title="causal network")
  edges <- net2 %>%
    mutate(key=paste(source, "(interacts with)", target))
  loadTableData(edges[,3:5],data.key.column = 'key', table = 'edge')
  
  # Colour by Betweenness centrality if data exists in network
  if (bet){
    setNodeColorMapping("betweenness_centrality",mapping.type="c", network="causal network")
  }
  
  # Subnetwork for each cluster
  if (cluster){
    for (i in clus_filt$MCODE_Cluster){
      clearSelection(type = "both", network = "causal network")
      selectNodes(i, by.col = "MCODE_Cluster", network="causal network")
      selectEdgesConnectingSelectedNodes(network="causal network")
      createSubnetwork(nodes="selected", subnetwork.name = i,network = "causal network")
      layoutNetwork()
    }
  }
  
  # Save cys file
  saveSession(filename = file.path(path, "causal_network.cys"))
}

# reset message sink and close the file connection
sink(type="message")
close(zz)