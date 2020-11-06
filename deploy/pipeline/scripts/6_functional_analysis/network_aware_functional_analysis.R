# Author : Agatha Treveil
# Date : November 2020
#
# Network-aware pathway analysis of causal network upstream signalling proteins (binding proteins-TFs inclusive)
# Using Reactome and KEGG pathways via ANUBIX (https://bitbucket.org/sonnhammergroup/anubix)
#
# NB. pathway nodes converted to Uniprot to be comparable to input networks
#     background contextualised specific PPI network (expressed omnipath)
#     significantly overrepresented pathways have q val <= 0.05
#
# Input: whole network node file (output from combined_edge_node_tables.R)
#        background network file for ppis (contextualised specific PPI network output from filter_network_expressed_genes.R)
#        reactome pathway file downlaoded from ANUBIX bitbucket page
#        output directory
# Output: enriched reactome pathways (q <= 0.05)
#         enriched kegg pathways (q <= 0.05)

##### Set up #####

# Capture  messages and errors to a file.
zz <- file("virallink.out", open="a")
sink(zz, type="message", append = TRUE)
message("\nStarting network-aware functional analysis: network_aware_functional_analysis.R\n")

# Install requried packages
if (!requireNamespace("devtools", quietly = TRUE))
  install.packages("devtools")
if (!requireNamespace("tidyverse", quietly = TRUE))
  install.packages("tidyverse")
if (!requireNamespace("org.Hs.eg.db", quietly = TRUE)) 
  BiocManager::install("org.Hs.eg.db")
require(devtools)
install_bitbucket("sonnhammergroup/anubix")

#packages
library(tidyverse)
library(ANUBIX)
library(org.Hs.eg.db)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

# Check length of command line parameters
if (length(args) != 4){
  stop("Wrong number of command line input parameters. Please check.")
}

outdir <- args[4]

# Create output dir if required
path1 <- file.path(outdir, "6_functional_analysis", "ppi_layer", "network-aware")
dir.create(path1, showWarnings = FALSE, recursive=TRUE)

##### Preprocess files #####

preproc_pathways <- function(pathways){
  # Function to convert reactome and kegg pathway annotations to uniprot IDs
  # Input: pathways: two column pathway annotation file with ensembl gene IDs in first column
  
  # Set colnames
  colnames(pathways) <- c("gene", "pathway")
  
  # Get uniprot-ensembl conversion table
  unip <- mapIds(org.Hs.eg.db, as.character(pathways$gene), c("UNIPROT"),keytype="ENSEMBL")
  
  # Map back to pathway IDs
  pathways_u <- left_join(pathways, data.frame(unip, col1 = names(unip)), by = c("gene" = "col1")) %>% 
    unique() %>%
    dplyr::select(gene = unip, pathway) %>%
    dplyr::filter(!is.na(gene))
  
  return(pathways_u)
}

preproc_backgr_ppi <- function(backgr){
  # Get 2 column table of interactions
  # Count nodes in ppi background network
  
  source <- backgr %>% dplyr::select(node = from) %>% unique()
  target <- backgr %>% dplyr::select(node = to) %>% unique()
  nodes_list <- rbind(source, target) %>% unique()
  
  # Get just source and target cols as uniprot IDs
  backgr2 <- backgr %>% dplyr::select(to, from)
  
  out <- list(nrow(nodes_list), backgr2)
  
  return(out)
}

##### Pathway analysis #####

run_anubix <- function(num_backg_nodes, backgr_network, pathways, test_nodes){
  # Function to run ANUBIX pathway analysis on the PPI nodes of the causal network
  # Uses the contextualised omnipath network as background
  # Tests against Reactome or KEGG pathway tables provided by Anubix
  # Inputs: num_backgr_nodes: number of unique nodes in the contextualised omnipath network (used instead of all human genes)
  #         backgr_network: 2 column contextualised omnipath network
  #         pathways: reactome or kegg annotations from ANUBIX (2 columns)
  #         test_nodes: all PPI nodes from the test causal network
  
  # Change network headers to match Anubix example network (example_anubix$network)
  backgr_network2 <- as.data.frame(backgr_network)
  colnames(backgr_network2) <- c("X2.Gene1","X3.Gene2")
  
  # Reformat test node set to match Anubix example (example_anubix$gene_set)
  test_nodes_df <- data.frame(V1 = test_nodes, V2 = "geneset1")
  
  # ANUBIX link matrix creation using Omnipath network and reactome/kegg pathways
  links <- anubix_links(network=backgr_network2,pathways,cutoff = 0.75,network_type = "unweighted")
  
  # Run main anubix analysis
  # Doesn't work in RStudio due to issues with parallelisation ?
  results <- anubix(links, test_nodes_df, pathways, cores = 2, total_genes=as.numeric(num_backg_nodes[[1]]), sampling = 2000)
  
  return(results)
}

##### Run all #####

# Read whole network node file 
nodes <- read.csv(args[1], sep = "\t")

# Read background network file 
backgr_ppi <- read.csv(args[2], sep = "\t")

# Read Reactome annotation file (obtained from ANUBIX BitBucket page - as used in paper) 
reactome <- read.csv(args[3], sep = "\t")
# Get KEGG annotation file and remove HSA rows
kegg <- example_anubix$pathway_set %>% dplyr::filter(!str_detect(V1, "^HSA:"))

# Convert IDs of reactome and kegg pathways
reactome_u <- preproc_pathways(reactome)
kegg_u <- preproc_pathways(kegg)

# Preprocess background nodes (output [1] = number of nodes in whole network, [2] = network source and target interactions)
process_backgr_ppi <- preproc_backgr_ppi(backgr_ppi)

# Get all ppi nodes
nodes_ppi <- nodes %>% filter(ppi_layer== "protein"|bindingprot_layer== "bindingprot"|tf_layer== "tf") %>% dplyr::select(node)

# Run anubix for Reactome pathways
reactome_results <- run_anubix(process_backgr_ppi[1],process_backgr_ppi[2],reactome_u,nodes_ppi)
kegg_results <- run_anubix(process_backgr_ppi[1],process_backgr_ppi[2],kegg_u,nodes_ppi)

# Sort by q value
reactome_results <- reactome_results %>% arrange(!!sym('q-value')) %>% dplyr::filter(!!sym('q-value') <= 0.05)
kegg_results <- kegg_results %>% arrange(!!sym('q-value')) %>% dplyr::filter(!!sym('q-value') <= 0.05)

# Output
if (reactome_results != ""){
  write.table(reactome_results, file = file.path(path1, "ppis_reactome_anubix_results.txt"), quote = FALSE, row.names = FALSE, sep = "\t")
}
if (kegg_results != ""){
  write.table(kegg_results, file = file.path(path1, "ppis_kegg_anubix_results.txt"), quote = FALSE, row.names = FALSE, sep = "\t")
}

# reset message sink and close the file connection
sink(type="message")
close(zz)

##### Test ANUBIX
#links_genes <- example_anubix$links_genes
#pathway_set <- example_anubix$pathway_set
#gene_set <- example_anubix$gene_set
#network <- example_anubix$network
#results <- anubix(links_genes, gene_set, pathway_set, cores = 2, total_genes=20000, sampling = 2000)
