# Author: Agatha Treveil
# Date: May 2020
#
# Script to get regulator - differentially expressed genes from the contextualised regulatory network
#
# Input: Contextualised regulatory network file (all nodes expressed, tab delimited, output from filter_network_expressed_genes.R)
#           uniprot ids in columns "to" and "from", gene symbols in columns "source_genesymbol" and "target_genesymbol"
#        Table of differentially expressed genes (csv, output from deseq2)
#        ID type of the differentially expressed genes - uniprot or gene symbols
#
# Output: Network in same format as input network (but tab seperated), filtered to include only interactions where target nodes are differentially expressed.

##### Set up #####

# Capture  messages and errors to a file.
zz <- file("virallink.out", open="a")
sink(zz, type="message", append = TRUE)
message("\nStarting reg-deg network script: get_regualtor_deg_network.R\n")

# Install required packages
if (!requireNamespace("tidyverse", quietly = TRUE)) 
  install.packages("tidyverse", repos = "https://cloud.r-project.org")

# Load required packages
library(tidyverse)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

# Check length of command line parameters
if (length(args) != 4){
  stop("Wrong number of command line input parameters. Please check.")
}

# Output directory
outdir <- args[4]

# Create output dir if required
path <- file.path(outdir, "2_process_a_priori_networks")
dir.create(path, showWarnings = FALSE, recursive=TRUE)

# Contextualised regulatory network
reg_net <- read.csv(args[1], sep = "\t")

# Differentially expressed genes (prefiltered)
diff_genes <- read.csv(args[2])

# ID type of the differentially expressed genes - uniprot or gene symbols
id_type <- args[3] # either "uniprot" or "symbol"
  
##### Preprocess #####

# Get column names of network to match to the differentially expressed genes (based on id type)
if(id_type == "symbol"){
  source_col <- "source_genesymbol"
  target_col <- "target_genesymbol"
} else if(id_type == "uniprot"){
  source_col <- "to"
  target_col <- "from"
} else {
  stop("The differential expression data id type is not correctly specified. Should be \"uniprot\" or \"symbol\"")
}

##### Filter network #####

# Filter netowrk so all target genes are differentially expressed
reg_net_f <- reg_net %>% filter(get(target_col) %in% diff_genes$Gene) %>% unique()

# Get list of regulators with number of targeted DEGs
regs <- reg_net_f %>% select(deg_regs = !!source_col) %>% add_count(deg_regs, name = "num_degs") %>% unique()

##### Save #####

write.table(reg_net_f, file = file.path(path,"contextualised_regulator-deg_network.txt"), sep = "\t", quote = F, row.names = F)
write.table(regs, file = file.path(path, "contextualised_regulators_of_degs.txt"), sep = "\t", quote = F, row.names = F)

# reset message sink and close the file connection
sink(type="message")
close(zz)