# Author : Agatha Treveil
# Date : April 2020
#
# Script to reformat functional enrichment results (output from network_functions_analysis.R) into table of gene annotations
#
# Input: list of overrepresentation result tables to process
#
# Output: Reformatted table for each input table - where rows are genes rather than functions.

### Set up ###

# Capture  messages and errors to a file.
zz <- file("virallink.out", open="a")
sink(zz, type="message", append = TRUE)
message("\nStarting reformatting functional results: reformat_functional_result.R\n")

# Install requried packages
if (!requireNamespace("tidyverse", quietly = TRUE)) 
  install.packages("tidyverse", repos = "https://cloud.r-project.org")
if (!requireNamespace("reshape2", quietly = TRUE)) 
  install.packages("reshape2", repos = "https://cloud.r-project.org")

# Load packages
library(tidyverse)
library(tidyr)
library(reshape2)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

# Check length of command line parameters
if (length(args) != 1){
  stop("Wrong number of command line input parameters. Please check.")
}

outdir <- args[1]

# Results of the functional analysis
files <- c("6_functional_analysis/deg_layer/degs_go_overrep_results.txt", "6_functional_analysis/deg_layer/degs_reactome_overrep_results.txt",
           "6_functional_analysis/ppi_layer/ppis_go_overrep_results.txt", "6_functional_analysis/ppi_layer/ppis_reactome_overrep_results.txt")

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
  
  # Open file if exists - else skip to next file
  if (file.exists(file.path(outdir,f))) {
    data <- read.csv(file.path(outdir,f), sep = "\t")
  } else {
    next
  } 
  
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

# reset message sink and close the file connection
sink(type="message")
close(zz)

