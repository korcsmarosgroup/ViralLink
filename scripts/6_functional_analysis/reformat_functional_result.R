# Author : Agatha Treveil
# Date : April 2020
#
# Script to reformat functional enrichment results (output from network_functions_analysis.R) into table of gene annotations
#
# Input: list of overrepresentation result tables to process
#
# Output: Reformatted table for each input table - where rows are genes rather than functions.

### Set up ###

# Install requried packages
if (!requireNamespace("tidyverse", quietly = TRUE)) 
  install.packages("tidyverse")
if (!requireNamespace("reshape2", quietly = TRUE)) 
  install.packages("reshape2")

# Load packages
library(tidyverse)
library(tidyr)
library(reshape2)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

outdir <- args[1]

# Results of the functional analysis
files <- c("6_functional_analysis/deg_layer/degs_go_0.1_overrep_results.txt", "6_functional_analysis/deg_layer/degs_reactome_overrep_results.txt",
           "6_functional_analysis/ppi_layer/ppis_go_0.1_overrep_results.txt", "6_functional_analysis/ppi_layer/ppis_reactome_overrep_results.txt")

# Create output dir if required
path <- file.path(outdir, "6_functional_analysis", "reformatted")
dir.create(path, showWarnings = FALSE, recursive=TRUE)

### ###

# Iterate files
for (f in files){
    
  # Get file name
    if (grepl("/", f, fixed = TRUE)){
      filen_list <- strsplit(f, "/")
      filen <- sapply(filen_list, tail, 1 )
    }
  
    # Open file
    data <- read.csv(file.path(outdir,f), sep = "\t")
    
   if("geneID" %in% colnames(data)){
     coln <- "geneID"
   } else {
     coln <- "core_enrichment"
   }
    
    # Filter for required cols and wide to long
    data2 <- data %>% dplyr::select(c(Description, coln)) %>% separate_rows(coln)
    data2$match <- 1
    
    # Pivot table
    data3 <- data2 %>% pivot_wider(names_from = Description, values_from = match, values_fn = list(match = length))
    
    # convert na to 0
    data3[is.na(data3)] <- 0
    
    # Save
    write.table(data3, file = file.path(path, paste0("reformatted_",filen)), sep = "\t", quote=F, row.names = F)
}

