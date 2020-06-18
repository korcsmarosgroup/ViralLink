
---- 1. diff_expression_deseq2.R ---- 

Script to carry out differential expression using Deseq2 with a counts table input. Will only carry out
1 pairwise comparison in 1 run.

Input: Raw counts table with all samples as columns and genes as rows (tab delimited).
        Metadata table with conversion between sample IDs and condition names (see 'empty_mapping_table.txt)
           - The table should contain one row per input sample
           - "sample_name" column should contain the sample name matching the relevant column header in the counts table.
           - "condition" column should contain "test" or "control"  depending on whether the sample is a test or control sample (all other values will be ignored). 
           - Differential expression is calculated by comparing "test" samples to "control" samples.
        lfc cut off and p adj value cut off

Output: R deseq2 data object following differential expression
        Table of differential expression results - unfiltered
        Table of differential expression results - filtered

Run from command line:

> Rscript diff_expression_deseq2.R raw_counts_table.txt metadata_table.txt output_directory/

---- 2. filter_expression_gaussian.py ---- 

Script to filter a normalised counts table only for genes which are expressed

Input: Normalised counts matrix with genes as rows and samples as columns, tab delimited. First column contains gene names/ids, all other columns are counts values.

Output: Tab delimited text file containing all genes deemed expressed with columns: "Gene", "mean_expression", "log2_mean_expression" and "zscore".

Run from command line:

> python3 filter_expression_gaussian.py -i normalised_counts_table.txt -o output_directory/