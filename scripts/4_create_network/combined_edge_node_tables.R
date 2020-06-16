# Author : Agatha Treveil
# Date : April 2020
#
# Script to combine the covid subnetworks into 1 network table and one node table
#
# Input: Receptor-tf network output from tiedie
#        SARS-CoV-2 - human binding protein network (columns 'viral_protein', 'human_protein')
#        Contextualised regulatory network (TFs - DEGs) (incl. columns 'DEG',"	TF", "consensus_stimulation") output from 'get_regulator_deg_network.R'
#        Heats values output from TieDie
#        Sars proteins gene symbol to uniprot conversion table
#        Differential expression table (unfiltered)
#
# Output: Network file where each line represents an interaction
#         Node table where each lines represents one node in the network

##### Setup #####

# Install required packages
if (!requireNamespace("tidyverse", quietly = TRUE)) 
  install.packages("tidyverse")
if (!requireNamespace("org.Hs.eg.db", quietly = TRUE)) 
  install.packages("org.Hs.eg.db")

library(tidyverse)
library(org.Hs.eg.db)

outdir <- args[8]

# Receptor-tf network from tiedie
rec_tf <- read.csv(args[1], header=F, col.names=c("Source.node","Relationship","Target.node"), sep = "\t")
# Node heats from tiedie
heats <- read.csv(args[2], sep="=")

# Virus-receptor network
cov_rec <- read.csv(args[3], sep = "\t")
# SARS-Cov2 gene symbols
sars <- read.csv(args[4], sep = "\t")

# tf-deg network
tf_deg <- read.csv(args[5], sep = "\t")

# lfc table (unfiltered)
lfc <- read.csv(args[6])

# ID type of the lfc table (uniprot or symbol)
id_type <- args[7] # "symbol" or "uniprot"

# Create output dir if required
path <- file.path(outdir, "4_create_network")
dir.create(path, showWarnings = FALSE, recursive=TRUE)

##### Process network edges #####

rec_tf2 <- rec_tf %>% mutate(layer= "bindingprot-tf") 

if("sign" %in% colnames(cov_rec)){
  cov_rec2 <- cov_rec %>% mutate(Relationship = ifelse(sign == "-","inhibits>", ifelse(sign=="+", "stimulates>", "unknown")))  %>%
    select(-c(sign)) %>%
    mutate(layer = "cov-bindingprot") %>%
    dplyr::rename(Source.node = viral_protein, Target.node = human_protein) %>%
    filter(Target.node %in% rec_tf2$Source.node)
} else {
  cov_rec2 <- cov_rec %>% mutate(Relationship = "unknown", layer = "cov-bindingprot") %>%
    dplyr::rename(Source.node = viral_protein, Target.node = human_protein) %>%
    filter(Target.node %in% rec_tf2$Source.node)
}

tf_deg2 <- tf_deg %>% mutate(layer = "tf-deg") %>%
  dplyr::select(Target.node = to, Source.node = from, Relationship = consensus_stimulation, layer) %>%
  filter(Source.node %in% rec_tf2$Target.node) %>%
  mutate(Relationship = str_replace(Relationship, "1", "stimulates>")) %>%
  mutate(Relationship = str_replace(Relationship, "0", "inhibits>"))

# Join together
whole_net <- rbind(cov_rec2, rec_tf2, tf_deg2) %>% unique()

# Save
write.table(whole_net, file = file.path(path, "final_network.txt"), sep = "\t", quote = F, row.names = F)

##### Process node table #####

# Get layers of all nodes
nodes1 <- whole_net %>% filter(layer == "cov-bindingprot") %>% mutate(cov_layer = "cov2") %>% dplyr::select(node = Source.node, cov_layer) %>% unique()
nodes2 <- whole_net %>% filter(layer == "cov-bindingprot") %>% mutate(bindingprot_layer = "bindingprot") %>% dplyr::select(node = Target.node, bindingprot_layer) %>% unique()
nodes3 <- whole_net %>% filter(layer == "bindingprot-tf") %>% mutate(ppi1_layer = "bindingprot and/or protein") %>% dplyr::select(node = Source.node, ppi1_layer) %>% unique()
nodes4 <- whole_net %>% filter(layer == "bindingprot-tf") %>% mutate(ppi2_layer = "protein and/or tf") %>% dplyr::select(node = Target.node, ppi2_layer) %>% unique()
nodes5 <- whole_net %>% filter(layer == "tf-deg") %>% mutate(tf_layer = "tf") %>% dplyr::select(node = Source.node, tf_layer) %>% unique()
nodes6 <- whole_net %>% filter(layer == "tf-deg") %>% mutate(deg_layer = "deg") %>% dplyr::select(node = Target.node, deg_layer) %>% unique()

# Join node layers together
all_nodes <- full_join(nodes1, nodes2) %>% full_join(nodes3) %>% full_join(nodes4) %>% full_join(nodes5) %>% full_join(nodes6)

# Combine the ppi layer col
all_nodes <- all_nodes %>% mutate(ppi_layer = ifelse((ppi1_layer == "bindingprot and/or protein" & ppi2_layer == "protein and/or tf"), "protein", "NA")) %>%
  dplyr::select(-c(ppi1_layer, ppi2_layer))

# Combine into 1 column
all_nodes <- all_nodes %>% unite(all_nodes, cov_layer, bindingprot_layer, ppi_layer, tf_layer, deg_layer, sep = ";", remove=FALSE, na.rm = TRUE)
all_nodes[is.na(all_nodes)] <- "NA"
rm(nodes1,nodes2, nodes3, nodes4, nodes5, nodes6)

# Get human node id conversion from Orgdb
id_mapping <- select(org.Hs.eg.db, keys=all_nodes$node, columns=c("SYMBOL","ENTREZID"), keytype="UNIPROT")
# Get only the first mapped id - as need 1:1 mapping later on
id_mapping2 <- id_mapping[!(duplicated(id_mapping$UNIPROT)),]
# Add id conversions to node table
all_nodes <- left_join(all_nodes, id_mapping2, by = c("node"="UNIPROT"))

# Add sars node id conversions
sars_sym <- sars %>%dplyr::select(c(node = Accession, gene_symbol))
all_nodes <- left_join(all_nodes, sars_sym, by = c("node")) %>% mutate(SYMBOL = replace_na(SYMBOL,"")) %>% mutate(gene_symbol = replace_na(as.character(gene_symbol),""))
all_nodes <-all_nodes %>% mutate(gene_symbol = paste0(SYMBOL, gene_symbol)) %>% dplyr::select(-c(SYMBOL))

# Add node heats from tiedie
heats$node <- row.names(heats)
heats$node <- gsub('\\s+', '', heats$node)
all_nodes <- left_join(all_nodes,heats)

# Add lfc and adj p value for all
if (id_type == "symbol"){
  lfc2 <- lfc %>% dplyr::select(gene_symbol = X, log2FoldChange, padj)
} else if(id_type == "uniprot"){
  lfc2 <- lfc %>% dplyr::select(UNIPROT = X, log2FoldChange, padj)
}
all_nodes <- left_join(all_nodes, lfc2)

# Save node table
write.table(all_nodes, file = file.path(path, "node_table.txt"), sep = "\t", quote = F, row.names = F)

