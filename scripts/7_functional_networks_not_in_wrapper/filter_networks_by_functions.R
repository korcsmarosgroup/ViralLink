# Author: Agatha Treveil
# Date: April 2020
#
# Script to reformat networks so that functions are the last nodes instead of deg nodes
# Removes the tf-deg interactions and adds TF-function interactions based on functions required
# Takes all upstream connections which are associated with the supplied functions and removes orphans
# Takes different functions for degs and upstream ppis
# If Cytoscape is open, the script will load the network into it and save as a .cys file
#
# Input: Final network and node tables of whole causal network (output from 'combined_edge_node_tables.R')
#        Reformatted results table from overrepresentation analysis of DEGs (output from 'reformat_functional_result.R')
#        Reformatted reactome-uniprot association file (provide: previously downloaded from Reactome website and reformatted April 2020)
#        List of DEG overrepresented functions to include
#        List of upstream functions (don't have to be overrepresented) to include (will filter the human binding proteins, intermediary signalling proteins and the TFs)
#
# Output: A standalone network 
#         Node table and edge annotation table which have a column labelled as specified to indicate the the edges/nodes are in this network 
#                 - This is for visualising the network within larger networks (includes the deg nodes (and tf-deg edges) which are collapsed into functional categories). 
#                 - The node annotation table can also be used alongside the functional standalone network for layer and functional annotations.
#         Cytoscape file containing the network

##### Setup #####

# Install requried packages
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
if (!requireNamespace("RCy3", quietly = TRUE)) 
  BiocManager::install("RCy3")
if (!requireNamespace("tidyverse", quietly = TRUE)) 
  install.packages("tidyverse")
if (!requireNamespace("naniar", quietly = TRUE)) 
  install.packages("naniar")

# Load packages
library(tidyverse)
library(naniar)
library(RCy3)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

outdir <- args[8]

# Output from 'combined_edge_node_tables.R'
# Network 
network <- read.csv(args[1], sep = "\t")
# Node table
node_table <- read.csv(args[2], sep = "\t")

# Reformatted functional overrepresentation results table for DEGs
reactome_funcs <- read.csv(args[3], sep = "\t") 

# Reformatted reactome-uniprot association file
reactome_assoc <- read.csv(args[4], sep = "\t")

# Required functions to extract from whole causal network
# deg functions must be in the overrepresented file (reactome_funcs)
deg_functions <- c(readLines(args[5]))
# ppi functions must be in the whole Reactome-uniprot file (reactome_assoc) - so can be any Reactome function annotated to at least one human protein
ppi_functions <- c(readLines(args[6]))

# Col name for output node table (also used in file name)
name <- args[7]

# Create output dir if required
path <- file.path(outdir, "7_functional_networks", name)
dir.create(path, showWarnings = FALSE, recursive=TRUE)

##### Filter network for cov proteins + those in functions specified #####

# Get genes associated with input ppi functions
reactome_assoc_filt <- data.frame(gene = character(), reactome = character(), ppi_func = character())
for (func in ppi_functions){
  reactome_assoc_f1 <- reactome_assoc %>% filter(grepl(func, reactome, fixed=TRUE)) %>%
    mutate(ppi_func = func)
  reactome_assoc_filt <- rbind(reactome_assoc_filt, reactome_assoc_f1)
}

reactome_assoc_filt <- reactome_assoc_filt %>% group_by(gene) %>% summarise(ppi_functions=paste(ppi_func, collapse=";"))

# Filter network for those genes and cov proteins
net_func <- network %>% filter(((Target.node %in% reactome_assoc_filt$gene)&(Source.node %in% reactome_assoc_filt$gene))|
                                 ((Target.node %in% reactome_assoc_filt$gene)&layer == "cov-bindingprot")|
                                 ((Source.node %in% reactome_assoc_filt$gene)&layer == "tf-deg"))

rm(reactome_assoc_f1)

##### Get all new tf-function interactions #####

# replace functions spaces etc with '.' - because r does this to the headers on import
strings <- "-| |\\(|\\)|\\/"
functions2 <- str_replace_all(deg_functions, strings,".")

# Get the tf-deg network
net_tfdeg <- net_func %>% filter(layer == "tf-deg")

# Empty df of tf-function interactions for new and removed edges and for removed nodes
ints <- data.frame()
#all_degs <- data.frame()
old_ints <- data.frame()

for (i in functions2){
  
  # Get i with spaces in
  j <- str_replace_all(i, "\\.", " ")
  
  # Get nodes of required function
  func_filt <- reactome_funcs %>% dplyr::select(!!!i, geneID) %>% filter(get(i)== 1) %>%
    mutate(!!i := str_replace(get(i), "1", i))
  
  # Join to node table
  func_filt2 <- left_join(func_filt, node_table, by = c("geneID"="ENTREZID"))
  
  # Replace the tf-deg interactions containing these degs with function
  net_replace <- net_tfdeg %>%  mutate(Target.node = ifelse(Target.node %in% func_filt2$node, j, as.character(Target.node)))                                     

  # Get only the new interactions
  net_replace <- net_replace %>% filter(Target.node == j) %>% mutate(Relationship = "unknown", layer = "tf-function") %>% unique()
  
  # Save all the new interactions
  ints <- rbind(ints, net_replace)
  
  # Save list of all 'removed' degs
  #degs1 <- func_filt2 %>% select(node) %>% unique()
  #all_degs <- rbind(all_degs, degs1)
  
  # Save list of all 'removed' tf-deg interactions
  net_tfdeg2 <- net_tfdeg %>% filter(Target.node %in% func_filt2$node)
  old_ints <- rbind(old_ints, net_tfdeg2)
}

rm(strings, i,j,net_tfdeg, net_tfdeg2, net_replace,func_filt2,func_filt)

##### Join all edges together #####
# Replace all tf-deg interactions with tf-function interactions

# Get all but tf-deg interactions
net_tffun <- net_func %>% filter(layer != "tf-deg")

# Add new interactions instead of tf-deg ints
net <- rbind(net_tffun, ints)

rm(ints, net_func, net_tffun)

##### Remove orphans in ppi layer by function #####
# Remove orphans for specific functional categories and label the edges with functional annotations

# Get the binding protein-tf network
ppis <- net %>% filter( layer == "bindingprot-tf")
  
# Get list of TFs
tfs <- net %>% filter(layer == "tf-function") %>% dplyr::select(Source.node) %>% unique()

# Get list of binding proteins
bps <-  net %>% filter(layer == "cov-bindingprot") %>% dplyr::select(Target.node) %>% unique()

# Append function labels
ppis <- left_join(ppis, reactome_assoc_filt, by = c("Target.node" = "gene"))
ppis <- left_join(ppis, reactome_assoc_filt, by = c("Source.node" = "gene"))

# empty df for filtered interactions
new_edges <- data.frame() #Source.node = character(), Target.node=character(), Relationship = character(), layer = character())

# Split by ppi function
for (x in ppi_functions){
  # Get all interactions for that functions
  ppis_x <- ppis %>% filter(grepl(x, ppi_functions.x, fixed=TRUE)) %>% filter(grepl(x, ppi_functions.y, fixed = TRUE))
  
  # Carry out orphan filtering
  # For each target node, if not in list or in source col, remove interaction
  # Repeat multiple times, counting how many were removed
  for(n in 1:10){
    ppis_x <- ppis_x %>% filter((Target.node %in% tfs$Source.node) | (Target.node %in% ppis_x$Source.node))
    print(nrow(ppis_x)) # Just manually check that 10 recurrances is enough
  }
  # For each source node if not in list of cov proteins or in target col, remove interaction
  for(n in 1:10){
    ppis_x <- ppis_x %>% filter((Source.node %in% bps$Target.node) | (Source.node %in% ppis_x$Target.node))
    print(nrow(ppis_x)) # Just manually check that 10 recurrances is enough
  }
  
  # Add edges to df - with annotation of function
  ppis_x <- ppis_x %>% mutate(ppi_functions = x) %>% dplyr::select(-c(ppi_functions.x, ppi_functions.y))
  new_edges <- bind_rows(new_edges, ppis_x)
}

# Join functions together, remove duplicates
net_ppi <- new_edges %>% group_by(Source.node, Target.node, Relationship, layer) %>%
  summarise_all(funs(paste(na.omit(.), collapse = ";"))) %>% unique() %>% summarise(functions=paste(ppi_functions, collapse=";")) %>%
  mutate(layer = "bindingprot-tf") #unite(functions, as.character(ppi_functions), sep = ";")

rm(ppis, tfs, bps, ppis_x, new_edges)

##### Add other edge annotations ######

# cov-bindingprotein functional annotations
net_cov <- net %>% filter(layer == "cov-bindingprot")
net_cov <- left_join(net_cov, reactome_assoc_filt, by = c("Target.node" = "gene"))
net_cov <- net_cov %>% dplyr::rename(functions = ppi_functions)

# tf - function functional annotations
net_deg <- net %>% filter(layer == "tf-function") %>% mutate(functions = Target.node)

# Join together into one network
net_all <- bind_rows(net_cov, net_ppi, net_deg)

rm(net_cov,net_ppi,net_deg, net)

##### Remove orphan paths whole network #####

# Get list of functions
functions3 <- str_replace_all(functions2, "\\.", " ")

# Get list of cov proteins
cov_nodes <- network %>% filter(layer == "cov-bindingprot") %>% dplyr::select(Source.node) %>% unique()

# For each target node, if not in list or in source col, remove interaction
# Repeat multiple times, counting how many were removed
net_f <- net_all
for(n in 1:10){
  net_f <- net_f %>% filter((Target.node %in% functions3) | (Target.node %in% net_f$Source.node))
  print(nrow(net_f)) # Just manually check that 10 recurrances is enough
}
# For each source node if not in list of cov proteins or in target col, remove interaction
for(n in 1:10){
  net_f <- net_f %>% filter((Source.node %in% cov_nodes$Source.node) | (Source.node %in% net_f$Target.node))
  print(nrow(net_f)) # Just manually check that 10 recurrances is enough
}

##### Save network #####

# Save
write.table(net_f, file = file.path(path, "function_specific_network.txt"), sep = "\t", quote = FALSE, row.names = FALSE)

rm(functions2, network, net_all)

##### Create table of edges #####
# Includes the deg nodes which are collapsed into functional categories

# Filter tf-degs so tf is in target col of other ints (is a targeted tf)
old_ints2 <- old_ints %>% filter(Source.node %in% net_f$Target.node)
net_f2 <- net_f %>% dplyr::select(-c(functions))
# Bind to all upstream edges
all_edges <- rbind(net_f2, old_ints2)

# convert to required format
all_edges2 <- all_edges %>% mutate(edge = paste0(Source.node," (interacts with) ",Target.node)) %>%
  dplyr::select(edge) %>% unique() %>% mutate(!!name := "yes")

write.table(all_edges2,file=file.path(path, "function_specific_network_edges.txt"), sep = "\t", quote = F, row.names = F)

rm(net_f2)

##### Create table of nodes #####
# Includes the deg nodes which are collapsed into functional categories

# Get layers of network
tfs <- net_f %>% filter(layer == "tf-function")
bindingprots <- net_f %>% filter(layer == "cov-bindingprot")
ppis <- net_f %>% filter(layer == "bindingprot-tf")

# Get pathway membership and layer info
# Get nodes with no upstream interactions
cov_nodes <- net_f %>% filter(layer == "cov-bindingprot") %>% dplyr::select(node = Source.node, functions) %>% unique() %>% mutate(cov_layer = "cov2")

# Collapse functions of upstream interactions to get functions of nodes with upstream interactions
edges_collapsed <- net_f %>% dplyr::select(node = Target.node, functions) %>% unique() %>% group_by(node) %>% summarise(functions=paste(functions, collapse=";"))
# Get layer info for these interactions         
edges_collapsed <- edges_collapsed %>% mutate(bindingprot_layer = ifelse(node %in% bindingprots$Target.node, "bindingprot", "NA"))
edges_collapsed <- edges_collapsed %>% mutate(tf_layer = ifelse((node %in% tfs$Source.node), "tf","NA"))
edges_collapsed <- edges_collapsed %>% mutate(ppi_layer = ifelse(((node %in% ppis$Source.node)&(node %in% ppis$Target.node)), "protein","NA"))

# Combine together 
nodes <- bind_rows(edges_collapsed, cov_nodes) %>% unique()  %>% replace_with_na_all(condition = ~.x =="NA") %>%
  unite(all_nodes, cov_layer, bindingprot_layer, ppi_layer, tf_layer, sep = ";", remove=FALSE, na.rm = TRUE)
nodes[is.na(nodes)] <- "NA"

# Remove duplicates in the function column
nodes2 <- nodes %>%
  separate_rows(functions, sep = ";") %>%
  group_by(node, all_nodes, cov_layer, bindingprot_layer, ppi_layer, tf_layer) %>%
  summarise(functions = paste(unique(functions), collapse = ";")) %>% mutate(!!name := "yes")

# Save node table
write.table(nodes2, file = file.path(path, "function_specific_network_nodes.txt"), sep = "\t", quote = F, row.names = F)

# Get genes associated with input deg functions - to annotate deg nodes which are removed
reactome_assoc_filt_deg <- data.frame(gene = character(), reactome = character(), ppi_func = character())
for (func in deg_functions){
  reactome_assoc_f1 <- reactome_assoc %>% filter(grepl(func, reactome, fixed=TRUE)) %>%
    mutate(deg_func = func)
  reactome_assoc_filt_deg <- rbind(reactome_assoc_filt_deg, reactome_assoc_f1)
}
reactome_assoc_filt_deg <- reactome_assoc_filt_deg %>% group_by(gene) %>% summarise(deg_functions=paste(deg_func, collapse=";"))

# Get degs which were collapsed into functions
deg_nodes <- old_ints2 %>% dplyr::select(node= Target.node) %>% unique()
deg_nodes <- left_join(deg_nodes, reactome_assoc_filt_deg, by =c("node"="gene"))
deg_nodes <- deg_nodes %>% mutate(deg_functions = paste0("deg_", deg_functions), deg_layer = "deg")     

# deg table
write.table(deg_nodes, file = file.path(path, "function_specific_network_deg_nodes.txt"), sep = "\t", quote = F, row.names = F)

rm(deg_nodes, edges_collapsed,cov_nodes, all_edges, n, ppis, tfs, bindingprots)

##### Load into Cytoscape #####

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
  
  net_f2 <- net_f %>% rename("source"= "Source.node", "target"="Target.node", "interaction"="Relationship")
  nodes3 <- nodes2 %>% rename("id" = "node")
  
  # Add network to cytoscape
  createNetworkFromDataFrames(nodes3,net_f2, title=name)
  
  # Save cys file
  saveSession(filename = file.path(path, "function-specific_network.cys"))
}

