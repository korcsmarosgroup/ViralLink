# Script to carry out differential expression using Deseq2 with a counts table input. Will only carry out
# 1 pairwise comparison in 1 run.
#
# Author: Agatha Treveil
# Date: April 2020
#s
# Input: Raw counts table with all samples as columns and genes as rows (tab delimited).
#        Metadata table with conversion between sample IDs and condition names (see 'empty_mapping_table.txt)
#           - The table should contain one row per input sample
#           - "sample_name" column should contain the sample name matching the relevant column header in the counts table.
#           - "condition" column should contain "test" or "control"  depending on whether the sample is a test or control sample (all other values will be ignored). 
#           - Differential expression is calculated by comparing "test" samples to "control" samples.
#        lfc cut off and p adj value cut off
# Output: R deseq2 data object following differential expression
#        Table of differential expression results - unfiltered
#        Table of differential expression results - filtered
#        Normalised expression table across all samples and only for test condition samples.
# 

####### Set up ######

# Capture  messages and errors to a file.
zz <- file("virallink.out", open="a")
sink(zz, type="message", append = TRUE)
message("\nStarting differential expression analysis script: diff_expression_deseq2.R\n")

# Install required packages
if (!requireNamespace("BiocManager", quietly = TRUE)) 
  install.packages("BiocManager")
if (!requireNamespace("DESeq2", quietly = TRUE)) 
  BiocManager::install("DESeq2")
if (!requireNamespace("tidyverse", quietly = TRUE)) 
  install.packages("tidyverse")

# Load required packages
library(tidyverse)
library(DESeq2)

# Define parameters
args <- commandArgs(trailingOnly = TRUE)

# Check length of command line parameters
if (length(args) != 5){
  stop("Wrong number of command line input parameters. Please check.")
}

# Raw counts table
counts <- read.csv(args[1], sep = "\t")

# Metadata table
meta <- read.csv(args[2], sep = "\t")

# Output folder
outdir <- args[3]

# LFC cut off (>=)
lfccutoff <- as.double(args[4])

# Q val cut off (<=)
pcutoff <- as.double(args[5])

####### Pre-processing ######

# Condition names for test and control (as in metadata table)
test <- "test"
control <- "control"

# Get vectors of control and test samples IDs
meta_f <- meta %>% filter((condition == test )| (condition == control))

# Filter counts table to only include the required samples
counts_f <- counts %>% select(one_of(meta_f$sample_name))

# Convert counts to matrix and add gene names
counts_fm <- as.matrix(counts_f)
rownames(counts_fm) <- counts$X

# Test if control is alphabetically after test (weird deseq2 thing)
#if (test > control){
#  warning("The control is alphabetically before test condition so the differential expression comparison will be carried out backwards.")
#}

##### Differential expression ######

# Create deseq2 object
dds = DESeqDataSetFromMatrix(countData = counts_fm, colData = meta_f, design = ~ condition)

# Set control
dds$condition <- relevel(dds$condition, ref = control)

# Carry out diff exp
dds <- DESeq(dds)

##### Save output ######

# Create output dir
dir.create(file.path(outdir, "1_process_expression_data"), showWarnings = FALSE, recursive = TRUE)

# See the comparisons carried out
comparison_name <- resultsNames(dds)

# Save the object
save(dds, file=file.path(outdir, "1_process_expression_data", file="deseq2_dds.Rdata"))

# Get results table
results <- results(dds, name=comparison_name[2])

# Extract normalized counts data
dds <- estimateSizeFactors(dds)
norm_counts <- counts(dds, normalized = TRUE)
write.table(norm_counts, file.path(outdir, "1_process_expression_data",file="counts_normalised_deseq2.txt"), sep = "\t", quote=F)
# Extract normalised counts for test condition only
test_samples <- meta_f %>% filter(condition == test)
norm_counts_test <- subset(norm_counts, select=test_samples$sample_name)
write.table(norm_counts, file.path(outdir, "1_process_expression_data",file="counts_normalised_deseq2_test.txt"), sep = "\t", quote=F)

# Save differential expression results
out_file <- paste0("deseq2_res_", comparison_name[2], ".csv")
write.csv(as.data.frame(results), file=file.path(outdir, "1_process_expression_data", file= out_file))

# Filter results
results_filt <- as.data.frame(results) %>% tibble::rownames_to_column('Gene') %>% filter((padj <= pcutoff)&((log2FoldChange >= lfccutoff)|(log2FoldChange <= -lfccutoff)))
out_file2 <- paste0("deseq2_res_", comparison_name[2], "_filtered.csv")
write.csv(results_filt, file=file.path(outdir, "1_process_expression_data", file=out_file2), row.names = FALSE)

# reset message sink and close the file connection
sink(type="message")
close(zz)
