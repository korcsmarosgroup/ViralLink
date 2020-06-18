
---- 1. network_functional_analysis.R ----

Functional overrepresentation analysis of causal networks: upstream signalling proteins (binding proteins-TFs inclusive), and differentially expressed genes (DEGs) seperately
Reactome and Gene ontology BP

NB. GO analyses carried out using uniprot IDs, but for the Reactome analysis it is necessary to convert to ENTREZ IDs
All nodes of the cell-type specific PPI network (expressed omnipath) are used as the background for the upstream signalling proteins
All TGs of the cell-type specific TF-TG network (expressed dorothea) are used as the background for the DEGs
significantly overrepresented functions have q val <= 0.05
GO analyses use simplify to remove rudundant function (with parameter 0.1)

Input: whole network node file (output from combined_edge_node_tables.R)
        background network file for ppis (contextualised specific PPI network output from filter_network_expressed_genes.R)
        background network file for degs (contextualised specific TF-TG network output from filter_network_expressed_genes.R)
        
Output: Data table, dot plot and map plot for each overrepresentation analysis

Run from command line:

> Rscript network_functional_analysis.R node_table.txt contextualised_ppi_network.txt contextualised_tf-tg_network.txt output_directory/


---- 2. cluster_functional_analysis.R ----

Functional analysis of human genes from clusters inside network
Overrepresentation analysis - reactome and GO BP - using cell type specific network as background

NB. GO analyses carried out using uniprot IDs for the ppi nodes, but for the Reactome analysis it was necessary to convert to ENTREZ
    For the overenrichment analysis (q val <= 0.05) it usea all nodes of the cell-type specific networks (expressed omnipath) as the background.
    For the GO analyses it uses simplify with parameter 0.1

Input: Node table (csv file) output from cytoscape containing the cluster annotations in the column "MCODE_cluster"
       PPI background network file - expressed omnipath network

Output: For each cluster (with >= 15 nodes): table of results, dot plot and map plot for GO and Reactome overrepresentation
        For all clusters (with >= 15 nodes) together (compareCluster function) dot plot for GO and Reactome overrepresentation

Run from command line:
 
> Rscript cluster_functional_analysis.R node_table_betweenness_clusters.txt contextualised_ppi_network.txt output_directory/


---- 3. reformat_functional_result.R ----

Script to reformat functional enrichment results (output from network_functions_analysis.R) into table of gene annotations. 

NB. This script has the output files from the previous network_functional_analysis.R script hardcoded into it. To use other files, edit line 29 of the script.

Input: list of overrepresentation result tables to process

Output: Reformatted table for each input table - where rows are genes rather than functions.

Run from command line:

> Rscript reformat_functional_result.R output_directory/
