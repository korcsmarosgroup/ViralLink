# 1. Downloading_omnipath_dorothea.R

Script to download directed and signed OmniPath protein-protein interactions and regulatory interactions from from DoRothEA (within OmniPath, confidence levels A,B,C)

**Input:**
* Output directory
       
**Output:**
* Omnipath and dorothea networks with correct headers

**Run from command line:**

```
Rscript Downloading_omnipath_dorothea.R /path_to/output_directory/
```


# 2. filter_network_expressed_genes.R

Script to filter networks for expressed genes - runs for regulatory interactions and for ppis

**Input:**
* Network file, space delimited, gene names in columns "source_genesymbol" "target_genesymbol" or "to" "from"
* Table of genes which are expressed, tab delimited, gene names in column "Gene" (ouput from DESeq2)
* ID type of the differentially expressed genes - uniprot or gene symbols

**Output:**
* Networks in same format as input network (but tab seperated), filtered to include only interactions where source and target node are in the expressed list.

**Run from command line:**

```
Rscript filter_network_expressed_genes.R expressed_genes_file.txt tf-tg_network.txt ppi_network.txt id_type("symbol" or "uniprot") output_directory/
```

# 3. get_regulator_deg_network.R 

Script to get regulator - differentially expressed genes from the contextualised regulatory network

**Input:**
* Contextualised regulatory network file (all nodes expressed, tab delimited, output from filter_network_expressed_genes.R). Uniprot ids in columns "to" and "from", gene symbols in columns "source_genesymbol" and "target_genesymbol"
* Table of differentially expressed genes (csv, output from deseq2)
* ID type of the differentially expressed genes - uniprot or gene symbols

**Output:**
* Network in same format as input network (but tab seperated), filtered to include only interactions where target nodes are differentially expressed.

**Run from command line:**

```
Rscript get_regulator_deg_network.R contextualised_tf-tg_network.txt differentially_expressed_gene_table.csv id_type("symol" or "uniprot") output_directory/
```
