# Author : Agatha Treveil
# Date : April 2020
#
# Functional analysis of human genes from clusters inside network
# Overrepresentation analysis - reactome and GO BP - using contextualised specific network as background
#
# NB. GO analyses carried out using uniprot IDs for the ppi nodes, but for the Reactome analysis it was necessary to convert to ENTREZ
#     For the overenrichment analysis (q val <= 0.05) it usea all nodes of the contextualised specific networks (expressed omnipath) as the background.
#     For the GO analyses it uses simplify with parameter 0.1
#
# Input: Node table (csv file) output from cytoscape containing the cluster annotations in the column "MCODE_cluster"
#        PPI background network file - expressed omnipath network
#
# Output: For each cluster (with >= 15 nodes): table of results, dot plot and map plot for GO and Reactome overrepresentation
#         For all clusters (with >= 15 nodes) together (compareCluster function) dot plot for GO and Reactome overrepresentation
#

##### Set up #####

# Capture  messages and errors to a file.
zz <- file("all.Rout", open="a")
sink(zz, type="message", append = TRUE)
message("\nStarting cluster functional analysis: cluster_functional_analysis.R\n")

# Install requried packages
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
if (!requireNamespace("ReactomePA", quietly = TRUE)) 
  BiocManager::install("ReactomePA")
if (!requireNamespace("clusterProfiler", quietly = TRUE)) 
  BiocManager::install("clusterProfiler")
if (!requireNamespace("tidyverse", quietly = TRUE)) 
  install.packages("tidyverse")
if (!requireNamespace("org.Hs.eg.db", quietly = TRUE)) 
  BiocManager::install("org.Hs.eg.db")

# load packages
library(tidyverse)
library(ReactomePA)
library(clusterProfiler)
library(org.Hs.eg.db)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

# Check length of command line parameters
if (length(args) != 3){
  stop("Wrong number of command line input parameters. Please check.")
}

outdir <- args[3]

# node table containing genes in column gene_symbol and cluster number in 'MCODE_Cluster' - output from 'betweenness_and_clustering.R'
nodes <- read.csv(args[1], sep ="\t")

# Get background network (contextualised specific omnipath)
backgr <- read.csv(args[2], sep = "\t")

# Create output dir if required
path <- file.path(outdir, "6_functional_analysis", "clusters")
dir.create(path, showWarnings = FALSE, recursive=TRUE)

##### Preprocess files #####

preproc_backgr <- function(backgr){
  # Get all nodes in background network
  
  source <- backgr %>% dplyr::select(node = from) %>% unique()
  target <- backgr %>% dplyr::select(node = to) %>% unique()
  nodes <- rbind(source, target) %>% unique()
  
  return(nodes)
}

##### Enrichment analysis #####

go_overrep <- function(net_heats, back_nodes, name, id,folder){
  # Carries out GO overrepresentation analysis.

  # Carry out normal GO gene overrepresentation analysis
  go1 <- enrichGO(gene = as.character(net_heats), OrgDb = "org.Hs.eg.db", keyType = id, universe =as.character(back_nodes$node), ont = 'BP', qvalueCutoff = 0.05)
  
  if (nrow(go1) > 0) {
    # Remove redundancy of GO terms. Cutoff refers to similarity
    go2 <- clusterProfiler::simplify(go1, cutoff=0.1, by = "qvalue", select_fun=min)
    
    # Get as dataframe
    go2_df <- as.data.frame(go2)
    
    if (nrow(go1) >1){
      # Get enrichment map
      map_ora <- emapplot(go2)
      # Save map
      filen <- file.path(folder, paste0(name, "_go_0.1_overrep_map.pdf"))
      pdf(filen)
      print(map_ora)
      dev.off()
    }
    
    # Get dot plot
    dot_plot <- dotplot(go2, showCategory=10, orderBy="qvalue", font.size = 10)
    # Save dot plot
    filep <- file.path(folder, paste0(name, "_go_0.1_overrep_dot.pdf"))
    pdf(filep)
    print(dot_plot)
    dev.off()
   
  } else{
    go2_df <- ""
  }
  
  return(go2_df)
}


reactome_overrep <- function(net_heats_e, back_nodes_e, name, id,folder){
  # Carries out reactome overrepresentation analysis.
  
  # Carry out normal reactome gene overrepresentation analysis (can only use entrez :( )
  re1 <- enrichPathway(gene = as.character(net_heats_e$ENTREZ), organism = "human", universe =as.character(back_nodes_e$ENTREZ), qvalueCutoff = 0.05)
  
  if (nrow(re1) > 0) {
   
    # Get as dataframe
    re1_df <- as.data.frame(re1)
    
    if (nrow(re1) >1){
      # Get enrichment map
      map_ora <- emapplot(re1)
      # Save map
      filen <- file.path(folder, paste0(name, "_reactome_overrep_map.pdf"))
      pdf(filen)
      print(map_ora)
      dev.off()
    }
    
    # Get dot plot
    dot_plot <- dotplot(re1, showCategory=10, orderBy="qvalue", font.size = 10)
    # Save dot plot
    filep <- file.path(folder, paste0(name, "_reactome_overrep_dot.pdf"))
    pdf(filep)
    print(dot_plot)
    dev.off()
  } else{
    re1_df <- ""  
  }
  
  return(re1_df)
}

##### Run all #####

# Preprocess background nodes
back_nodes <- preproc_backgr(backgr)

# Remove unclustered nodes
nodes2 <- nodes %>% filter(MCODE_Cluster != "")

# Un-list the MCODE_cluster column
nodes3 <- nodes2 %>% unnest(MCODE_Cluster) %>% group_by(node) %>% mutate(MCODE_Cluster = paste0(MCODE_Cluster, collapse = ";")) 

# List clusters with <15 nodes
clusters <- nodes3 %>% ungroup() %>% dplyr::select(MCODE_Cluster) %>% group_by(MCODE_Cluster) %>% summarise(n = n()) %>%
  filter(n>= 15)

# Select clusters of interest
nodes3 <- nodes3 %>% filter(MCODE_Cluster %in% clusters$MCODE_Cluster)

# Split df to get seperate clusters
cluster_dfs <- split(nodes3 , f = nodes3$MCODE_Cluster)

compare_ids <- vector(mode = "list")
n<-1
for (i in cluster_dfs){
  
  if (nrow(i) == 0){
    next
  }
  
  # Name of cluster
  nam <- names(cluster_dfs)[n]
  print(nam)
  # Run overenrichment analysis
  go_res <- go_overrep(i$node, back_nodes, nam, "UNIPROT",path)
  write.table(go_res, file = file.path(path, paste0(nam, "_go_0.1_overrep_results.txt")), quote = FALSE, row.names = FALSE, sep = "\t")
  
  # get Entrez ids
  # Convert to entrez genes
  i_e <- bitr(i$node, fromType='UNIPROT', toType='ENTREZID', OrgDb="org.Hs.eg.db")
  back_nodes_e <- bitr(back_nodes$node, fromType='UNIPROT', toType='ENTREZID', OrgDb="org.Hs.eg.db")
  compare_ids[[as.character(n)]] <- i_e$ENTREZID
  
  # Run reactome overenrichment
  reactome_res <- reactome_overrep(i_e, back_nodes_e, nam,"UNIPROT",path)
  write.table(reactome_res, file = file.path(path, paste0(nam, "_reactome_overrep_results.txt")), quote = FALSE, row.names = FALSE, sep = "\t")
  
  n <- n+1
}

# Run together
clusters_go <- compareCluster(compare_ids, fun="enrichGO", ont = 'BP', OrgDb='org.Hs.eg.db',pvalueCutoff=0.1, universe = back_nodes_e$ENTREZID)
#clusters_go2 <- simplify(clusters_go,cutoff = 0.7,by = "p.adjust")
dotplot_g <- dotplot(clusters_go, font.size = 10, title = paste0("NHBE - clustering of PPI nodes"), showCategory=5)
fileg <- file.path(path,"all_clusters_go_overrep_dot.pdf")
pdf(fileg, width=7)
print(dotplot_g)
dev.off()

clusters_react <- compareCluster(compare_ids, fun="enrichPathway",pvalueCutoff=0.1, universe =back_nodes_e$ENTREZID)
#summary(clusters_react)
dotplot_r <- dotplot(clusters_react, font.size = 10, title = paste0("NHBE - clustering of PPI nodes"), showCategory=5)
filer <- file.path(path,"all_clusters_reactome_overrep_dot.pdf")
pdf(filer, width=6)
print(dotplot_r)
dev.off()

# reset message sink and close the file connection
sink(type="message")
close(zz)
