# Author: Dezso Modos
# Date: April 2020
#
# Script to download directed and signed OmniPath protein-protein interactions and regulatory interactions from 
# from DoRothEA (within OmniPath, confidence levels A,B,C)
#
# Input: outdir
#        
# Output: Omnipath and dorothea networks with correct headers
#
##### Setup #####

# Installing packages
if (!requireNamespace("dplyr", quietly = TRUE)) 
  install.packages("dplyr")
if (!requireNamespace("tibble", quietly = TRUE)) 
  install.packages("tibble")
if (!requireNamespace("purrr", quietly = TRUE)) 
  install.packages("purrr")
if(!'OmnipathR' %in% installed.packages()[,"Package"]){
  require(devtools)
  install_github('saezlab/OmnipathR')
}

# Loading the required packages
library(dplyr)
library(tibble)
library(purrr)
library(OmnipathR)
#library(openxlsx)
#library(igraph)
#library(qgraph)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

outdir <- args[1]

# Create output directory if doesn't exist
path <- file.path(outdir, "2_process_a_priori_networks", "unprocessed_networks")
dir.create(path, showWarnings = FALSE, recursive=TRUE)

##### PPIs #####

# Get OmniPath PPI interaction network
ia_omnipath <- import_omnipath_interactions() %>% as_tibble()

# If you need higher coverage on PPI add these with `bind_rows` below
ia_ligrec <- import_ligrecextra_interactions() %>% as_tibble()
ia_pwextra <- import_pathwayextra_interactions() %>% as_tibble()
ia_kinaseextra <- import_kinaseextra_interactions() %>% as_tibble()

interactions <- as_tibble(
  bind_rows(
    ia_omnipath %>% mutate(type = 'ppi'),
    ia_pwextra %>% mutate(type = 'ppi'),
    ia_kinaseextra %>% mutate(type = 'ppi'),
    ia_ligrec %>% mutate(type = 'ppi')))

# For the network propagation interactome we need such an interaction table where we have
# the sign of the interactions and the direction of the interactions.
# First we take all the availble databases from Omnipath then we filter those which are ditrected and only inhibition OR stimulation have per one interaction.
# It is a question whether you should use consensus or is_inhibition is_directed columns.

interactions_filtered <- interactions[interactions$consensus_direction==1,]
interactions_filtered <- interactions_filtered[(interactions_filtered $consensus_inhibition +interactions_filtered$consensus_stimulation)==1,]

# Filter for the interactions which are involved in loops or which edges have multiple edges.

human_directed_interactome <- graph_from_data_frame(interactions_filtered, directed = TRUE, vertices = NULL)
human_directed_interactome <- simplify(human_directed_interactome, remove.multiple = FALSE, remove.loops = TRUE)

# The original igraph function deletes the edge attribute so below you can see a slightly changed one.

a = which_multiple(human_directed_interactome)
edge_indexes = E(human_directed_interactome)
human_directed_interactome  = subgraph.edges(human_directed_interactome, edge_indexes[a==FALSE])

# Keep only the giant component.
# First we have it from Csanadi updated for the vertex ids. 
# https://lists.gnu.org/archive/html/igraph-help/2009-08/msg00064.html

giant.component <- function(graph, ...) {
  cl <- clusters(graph, ...)
  induced_subgraph(graph, which(cl$membership == which.max(cl$csize)))
}

human_directed_interactome_giant_component  = giant.component(human_directed_interactome) 

# Write out the igraph both in ncol format

write_graph(human_directed_interactome_giant_component, paste0(path,"/directed_human_ppi_interactome.ncol"), format="ncol")
human_directed_interactome_filtered = as_data_frame(human_directed_interactome_giant_component, what = "edges")
write.table(human_directed_interactome_filtered, paste0(path, "/omnipath_signed_directed.txt"))

##### Regulatory interactions ####

# Download DOROTHEA for transcriptional regulation interactions
# The confidence level will be those TF-target interactions which are currated (a,b,c)

ia_transcriptional <- import_dorothea_interactions(confidence_level = c('A', 'B', 'C')) %>% as_tibble()

# After importing dataframe we go through again the same steps as for the PPIs
# Filtering only interactions where we know the direction and only inhibitory or excitatory.

ia_transcriptional <- ia_transcriptional[ia_transcriptional$consensus_direction==1,]
ia_transcriptional <- ia_transcriptional[(ia_transcriptional$consensus_stimulation+ia_transcriptional$consensus_inhibition)==1,]

# Make a graph and exclude self loops and multiple edges.
# We do not make a giant compnent for the graph, due to the TF-target interactome is not fully discovered and has multiple valuable components. 

ia_transcriptional2 <- graph_from_data_frame(ia_transcriptional, directed = TRUE, vertices = NULL)
ia_transcriptional2 <- simplify(ia_transcriptional2, remove.multiple = FALSE, remove.loops = TRUE)
a = which_multiple(ia_transcriptional2)
edge_indexes = E(ia_transcriptional2)
ia_transcriptional2  = subgraph.edges(ia_transcriptional2, edge_indexes[a==FALSE])

# Write results into files for further work

write_graph(ia_transcriptional2, paste0(path, "/directed_human_TF_targets.ncol"), format="ncol")
human_tf_data_filtered = as_data_frame(ia_transcriptional2, what = "edges")
write.table(human_tf_data_filtered, paste0(path,"/dorothea_abc_signed_directed.txt"))

