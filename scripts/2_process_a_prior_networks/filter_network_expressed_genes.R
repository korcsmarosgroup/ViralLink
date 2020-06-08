# Author: Agatha Treveil
# Date: April 2020
#
# Script to filter networks for expressed genes - runs for regulatory interactions and for ppis
#
# Input: Network file, space delimited, gene names in columns "source_genesymbol" "target_genesymbol" or "to" "from"
#        Table of genes which are expressed, tab delimited, gene names in column "Gene" (ouput from DESeq2)
#        ID type of the differentially expressed genes - uniprot or gene symbols
#
# Output: Networks in same format as input network (but tab seperated), filtered to include only interactions where source and target node are in the expressed list.

# Installing packages
if (!requireNamespace("dplyr", quietly = TRUE)) 
  install.packages("dplyr")

# Load packages
library(dplyr)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

# Output directory
outdir <- args[1]

# ID type of the  expressed genes - uniprot or gene symbols
id_type <- "symbol" # symbol or uniprot - the ids in the expression data

# Create output dir if required
path <- file.path(outdir, "2_process_a_priori_networks")
dir.create(path, showWarnings = FALSE, recursive=TRUE)

if (id_type == "symbol"){
  source_col = "source_genesymbol"
  target_col = "target_genesymbol"
} else if (id_type == "uniprot") {
  source_col = "to"
  target_col = "from"
}

# Gene expression file - tab delimited
expressed <- read.csv(file.path(outdir, "1_process_expression_results", "expressed_genes.txt"), sep = "\t")

files <- c("dorothea_abc_signed_directed.txt","omnipath_signed_directed.txt")

for (i in files){
  # Network file - space delimited 
  network <- read.csv(file.path(path,"unprocessed_networks", i), sep = " ")
  
  # Filter source and target nodes
  network_f <- network %>% filter((get(source_col) %in% expressed$Gene) & (get(target_col) %in% expressed$Gene))
  
  # Get network name for out filename
  name <- strsplit(i, "_")[[1]][1]
  # Save output
  write.table(network_f, file = file.path(path, paste0(name, "_contextualised_network.txt")), sep = "\t", quote = F, row.names = F)
}
