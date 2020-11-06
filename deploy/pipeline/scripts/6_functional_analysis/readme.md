# 1. network_functional_analysis.R

Functional overrepresentation analysis of causal networks: upstream signalling proteins (binding proteins-TFs inclusive), and differentially expressed genes (DEGs) seperately. Uses Reactome and Gene Ontology BP.

>NB. 
>* GO analyses carried out using uniprot IDs, but for the Reactome analysis it is necessary to convert to ENTREZ IDs
>* All nodes of the cell-type specific PPI network (expressed omnipath) are used as the background for the upstream signalling proteins
>* All TGs of the cell-type specific TF-TG network (expressed dorothea) are used as the background for the DEGs significantly overrepresented functions have q val <= 0.05
>* GO analyses use simplify to remove redundant function (with default parameter 0.7)

**Input:**

* Whole network node file (output from combined_edge_node_tables.R)
* Background network file for ppis (contextualised specific PPI network output from filter_network_expressed_genes.R)
* Background network file for degs (contextualised specific TF-TG network output from filter_network_expressed_genes.R)
        
**Output:**

* Data table, dot plot and map plot for each overrepresentation analysis

**Run from command line:**
```
Rscript network_functional_analysis.R node_table.txt contextualised_ppi_network.txt contextualised_tf-tg_network.txt output_directory
```

# 2. cluster_functional_analysis.R

Functional analysis of human genes from clusters inside network. Overrepresentation analysis - reactome and GO BP - using contextualised network as background.

>NB. 
>* GO analyses carried out using uniprot IDs for the ppi nodes, but for the Reactome analysis it was necessary to convert to ENTREZ
>* For the overenrichment analysis (q val <= 0.05) it usea all nodes of the cell-type specific networks (expressed omnipath) as the background.
>* For the GO analyses it uses simplify with default parameter 0.7

**Input:**
* Node table (csv file) output from cytoscape containing the cluster annotations in the column "MCODE_cluster"
* PPI background network file - expressed omnipath network

**Output:**
* For each cluster (with >= 15 nodes): table of results, dot plot and map plot for GO and Reactome overrepresentation
* For all clusters (with >= 15 nodes) together (compareCluster function) dot plot for GO and Reactome overrepresentation

**Run from command line:**
 
```
Rscript cluster_functional_analysis.R node_table_betweenness_clusters.txt contextualised_ppi_network.txt output_directory
```

# 3. network_aware_functional_analysis.R

Pathway analysis of upstream signalling proteins (binding proteins-TFs inclusive) from causal network. Uses ANUBIX network aware pathway analysis tool. Reactome and KEGG pathways analysed. Using contextualised omnipath network as background.

>NB. 
>* Reactome and KEGG pathway annotations obtained from ANUBIX R package (for KEGG) and on BitBucket site (for Reactome)
>* Reactome and KEGG pathway nodes converted to Uniprot to be comparable to input networks
>* Used contextualised specific PPI network (expressed omnipath) as background
>* Significantly overrepresented pathways have q val <= 0.05

**Input:**
* Whole network node file (output from combined_edge_node_tables.R)
# Background network file for ppis (contextualised specific PPI network output from filter_network_expressed_genes.R)
# Reactome pathway file downloaded from ANUBIX bitbucket page (saved in *input_files/anubix_reactome_pathways.txt*)

**Output:**
* Table of enriched Reactome pathways (q <= 0.05)
# Table of enriched KEGG pathways (q <= 0.05)

**Run from command line:**
 
```
Rscript network_aware_functional_analysis.R node_table.txt contextualised_ppi_network.txt input_files/anubix_reactome_pathways.txt output_directory
```

# 4. reformat_functional_result.R

Script to reformat functional enrichment results (output from network_functions_analysis.R) into table of gene annotations. 

>NB. This script has the output files from the previous network_functional_analysis.R script hardcoded into it. To use other files, edit line 29 of the script.

**Input:**
* List of overrepresentation result tables to process

**Output:**
* Reformatted table for each input table - where rows are genes rather than functions.

**Run from command line:**

```
Rscript reformat_functional_result.R output_directory
```