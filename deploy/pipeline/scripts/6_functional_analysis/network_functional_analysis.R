# Author : Agatha Treveil
# Date : April 2020
#
# Functional overrepresentation analysis of causal networks: upstream signalling proteins (binding proteins-TFs inclusive), 
# and differentially expressed genes (DEGs) seperately
# Reactome and Gene ontology BP
#
# NB. GO analyses carried out using uniprot IDs, but for the Reactome analysis it is necessary to convert to ENTREZ IDs
#     All nodes of the contextualised specific PPI network (expressed omnipath) are used as the background for the upstream signalling proteins
#     All TGs of the contextualised specific TF-TG network (expressed dorothea) are used as the background for the DEGs
#     significantly overrepresented functions have q val <= 0.05
#     GO analyses use simplify to remove rudundant function (with default parameter 0.7)
#
# Input: whole network node file (output from combined_edge_node_tables.R)
#        background network file for ppis (contextualised specific PPI network output from filter_network_expressed_genes.R)
#        background network file for degs (contextualised specific TF-TG network output from filter_network_expressed_genes.R)
#        
# Output: Data table and dot plot for each overrepresentation analysis (commented out map plot due to package updates causing error when running it)


##### Set up #####

# Set timeout
options(timeout=250)

# Capture  messages and errors to a file.
zz <- file("virallink.out", open="a")
sink(zz, type="message", append = TRUE)
message("\nStarting functional analysis: network_functional_analysis.R\n")

# Install requried packages
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
if (!requireNamespace("ReactomePA", quietly = TRUE))
  BiocManager::install("ReactomePA", update = TRUE, ask = FALSE)
if (!requireNamespace("clusterProfiler", quietly = TRUE)) 
  BiocManager::install("clusterProfiler")
if (!requireNamespace("tidyverse", quietly = TRUE)) 
  install.packages("tidyverse")
if (!requireNamespace("org.Hs.eg.db", quietly = TRUE)) 
  BiocManager::install("org.Hs.eg.db")

#packages
library(tidyverse)
library(ReactomePA)
library(clusterProfiler)
library(org.Hs.eg.db)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

# Check length of command line parameters
if (length(args) != 4){
  stop("Wrong number of command line input parameters. Please check.")
}

outdir <- args[4]

# Create output dir if required
path1 <- file.path(outdir, "6_functional_analysis", "ppi_layer")
path2 <- file.path(outdir, "6_functional_analysis", "deg_layer")
dir.create(path1, showWarnings = FALSE, recursive=TRUE)
dir.create(path2, showWarnings = FALSE, recursive=TRUE)

##### Preprocess files #####

preproc_backgr_ppi <- function(backgr){
  # Get all nodes in ppi background network
  
  source <- backgr %>% dplyr::select(node = from) %>% unique()
  target <- backgr %>% dplyr::select(node = to) %>% unique()
  nodes <- rbind(source, target) %>% unique()
  
  return(nodes)
}

##### Enrichment analysis #####

go_overrep <- function(net, back_nodes, name, id,folder){
  # Carries out GO overrepresentation analysis.

  # Carry out normal GO gene overrepresentation analysis
  go1 <- enrichGO(gene = as.character(net$node), OrgDb = "org.Hs.eg.db", keyType = id, universe =as.character(back_nodes$node), ont = 'BP', qvalueCutoff = 0.05)
  
  if (nrow(go1) > 0) {
    # Remove redundancy of GO terms. Cutoff refers to similarity
    go2 <- clusterProfiler::simplify(go1, by = "qvalue", select_fun=min)
    
    # Get as dataframe
    go2_df <- as.data.frame(go2)
    
    #if (nrow(go2_df) >1){
    #  # Get enrichment map
    #  map_ora <- emapplot(go2)
    #  # Save map
    #  filen <- file.path(folder,paste0(name,"_map_GO_overrep.pdf"))
    #  pdf(filen)
    #  print(map_ora)
    #  dev.off()
    #}
    
    # Get dot plot
    dot_plot <- dotplot(go2, showCategory=10, orderBy="qvalue", font.size = 10)
    # Save dot plot
    filep <- file.path(folder,paste0(name,"_dot_GO_overrep.pdf"))
    pdf(filep)
    print(dot_plot)
    dev.off()
   
  } else{
    go2_df <- ""
  }
  
  return(go2_df)
}


reactome_overrep <- function(net, back_nodes, name, id,folder){
  # Carries out reactome overrepresentation analysis.
  
  # Convert to entrez genes
  net_e <- bitr(net$node, fromType=id, toType='ENTREZID', OrgDb="org.Hs.eg.db")
  back_nodes_e <- bitr(back_nodes$node, fromType=id, toType='ENTREZID', OrgDb="org.Hs.eg.db")
  
  # Carry out normal reactome gene overrepresentation analysis (can only use entrez :( )
  re1 <- enrichPathway(gene = as.character(net_e$ENTREZ), organism = "human", universe =as.character(back_nodes_e$ENTREZ), qvalueCutoff = 0.05)
  
  if (nrow(re1) > 0) {
   
    # Get as dataframe
    re1_df <- as.data.frame(re1)
    
   #if (nrow(re1_df) >1){
   #  # Get enrichment map
   #  map_ora <- emapplot(re1)
   #  # Save map
   #  filen <- file.path(folder,paste0(name,"_map_reactome_overrep.pdf"))
   #  pdf(filen)
   #  print(map_ora)
   #  dev.off()
   #}
    
    # Get dot plot
    dot_plot <- dotplot(re1, showCategory=10, orderBy="qvalue", font.size = 10)
    # Save dot plot
    filep <- file.path(folder,paste0(name, "_dot_reactome_overrep.pdf"))
    pdf(filep, width=6.5)
    print(dot_plot)
    dev.off()
  } else{
    re1_df <- ""  
  }
  
  return(re1_df)
}


##### Run all #####

# Read background files
backgr_ppi <- read.csv(args[2], sep = "\t")
backgr_deg <- read.csv(args[3], sep = "\t")
  
# Read nodes file
nodes <- read.csv(args[1], sep = "\t")

# Preprocess background nodes
back_nodes_ppi <- preproc_backgr_ppi(backgr_ppi)
back_nodes_deg <- backgr_deg %>% dplyr::select(node = to) %>% unique()

# Get all ppi nodes
nodes_ppi <- nodes %>% filter(ppi_layer== "protein"|bindingprot_layer== "bindingprot"|tf_layer== "tf") %>% dplyr::select(node)
# Get all deg nodes
nodes_degs <- nodes %>% filter(deg_layer == "deg") %>% dplyr::select(node)

# Run GO overenrichment analysis
go_res_ppi <- go_overrep(nodes_ppi, back_nodes_ppi, "ppis", "UNIPROT",path1)
if (go_res_ppi != ""){
  write.table(go_res_ppi, file = file.path(path1,"ppis_go_overrep_results.txt"), quote = FALSE, row.names = FALSE, sep = "\t")
}
go_res_deg <- go_overrep(nodes_degs, back_nodes_deg, "degs", "UNIPROT",path2)
if (go_res_deg != ""){
  write.table(go_res_deg, file = file.path(path2, "degs_go_overrep_results.txt"), quote = FALSE, row.names = FALSE, sep = "\t")
}
# Run reactome overenrichment analysis
reactome_res_ppi <- reactome_overrep(nodes_ppi, back_nodes_ppi, "ppis","UNIPROT",path1)
if (reactome_res_ppi != ""){
  write.table(reactome_res_ppi, file = file.path(path1, "ppis_reactome_overrep_results.txt"), quote = FALSE, row.names = FALSE, sep = "\t")
}
reactome_res_deg <- reactome_overrep(nodes_degs, back_nodes_deg, "degs","UNIPROT",path2)
if (reactome_res_deg != ""){
  write.table(reactome_res_deg, file = file.path(path2, "degs_reactome_overrep_results.txt"), quote = FALSE, row.names = FALSE, sep = "\t")
}
# reset message sink and close the file connection
sink(type="message")
close(zz)
