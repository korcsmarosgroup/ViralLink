# ViralLink

## Overview

ViralLink is a systems biology workflow which reconstructs and analyses networks representing the effect of viral infection on specific human cell types. 

These networks trace the flow of signal from intracellular viral proteins through their human binding proteins and downstream signalling pathways, ending with transcription factors regulating genes differentially expressed upon viral exposure. In this way, the workflow provides a mechanistic insight from previously identified knowledge of virally infected cells. By default, the workflow is set up to analyse the intracellular effects of SARS-CoV-2, requiring only transcriptomics counts data as input from the user: thus encouraging and enabling rapid multidisciplinary research. However, the wide ranging applicability and modularity of the workflow facilitates customisation of viral context, *a priori* interactions and analysis methods.

ViralLink is currently available as a series of R and Python scripts which can be run seperately from the command line - to enable flexibility - or through a Bash wrapper script created for easy accessibility.

More detailed information about ViralLink is available in the following paper:

> Treveil A., Bohar B., Sudhakar P. et al. [ViralLink: An integrated workflow to investigate the effect of SARS-CoV-2 on intracellular signalling and regualtory pathways (link) _BioRxiv_ (2020)

<img src="virallink_overview.png" align="center" width="500">

----
## Getting Started 

### Prerequisites

ViralLink should run on any UNIX system, and has been tested on Linux and Mac OS. Windows compatibility is not supported at this time.

**R (≥ 4.0.0)** and **Python 3** are required to run the workflow. Additionally, for clustering analysis and visualisation, **Cytoscape (≥ 7.0.0)** is required (and it must be open locally when the scripts are run - or these functions will be skipped).

Furthermore, the following packages are required:

* R packages: 

```
tidyverse
org.Hs.eg.db
DESeq2
OmnipathR (needs "devtools")
RCy3 (≥ 2.6.0)
igraph
reshape2
naniar
```

* Python3 packages:

```
scipy (≥ 0.12.0)
numpy (≥ 1.7)
math
os
Neworkx
```

### Inputs to ViralLink

All input files and parameters should be specified by editing the **BLANK** file using a text editor.

**The input files for ViralLink are as follows:**

1. A unnormalsied counts table from a human transcriptomics study. Genes (using gene symbols or UniProt protein IDs) as rows and samples as columns.  (REQUIRED FROM USER)

2. A tab-delimited two-column metadata table specifying test and control sample IDs in the following format. Here the sample names must match the headers in the normalised counts table. For an example metadata file see the *input_data* folder.  (REQUIRED FROM USER)


|   sample_name	|   condition	|
| ------------- | ------------- |
|   sample1	|   test	|
|   sample2	|   test	|
|   sample3	|   control	| 

3. Viral - human protein-protein interaction table
	- Interactions for SARS-CoV-2 from [*Gordon et al.*](https://www.nature.com/articles/s41586-020-2286-9) provided: *input_files/sarscov2-human_ppis_gordon_april2020.txt*
	- Tab-delimited with one line per interaction
	- 2 columns named *viral_protein* and *human_protein*
	- Human proteins in UniProt format
	
4. Gene symbol annotations for all input viral proteins, for ease of data interpretation.
	- Annotations for the Gordon *et al* SARS-CoV-2 proteins provided: *input_files/sarscov2_protein_annotations.txt*
	- Tab-delimited with one line per protein
	- At least 2 columns named *Accession* and *gene_symbol*

5. Reactome annotations for all human UniProt IDs
	- Only required for the *filter_networks_by_functions.R* script (which is not part of the Bash wrapper)
	- Provided based on data downloaded from Reactome on 30/04/2020: *input_files/reactome_annotations_uniprot_300420.txt*
	- Tab-delimited text file with 2 columns: uniprot id column "gene" and a column of Reactome pathway names seperated by ";", named "reactome"
	
**Addition required parameters:**

1. Log2 fold change cut off 
	- Genes must have log2 fold change more than or equal the modulus of this value to be differentially expressed
	
2. Adjusted p value cut off 
	- Genes must have adjusted p value (from differential expression analysis) less than than or equal to this value to be differentially expressed
	
3. Type of ID in the input expression data
	-  Must be "symbol" (for gene symbols) or UniProt (for Uniprot IDs)

----
## Running ViralLink

### Download
To use ViralLink, all _scripts_ and all _input\_files_ should be downloaded using the _Clone or download_ button on the Github web page or by typing the following into a terminal window:

```
cd folder/to/clone-into/
git clone https://https://github.com/korcsmarosgroup/viral_intracellular_networks
```

### Run Bash wrapper

```

```

### Debugging

----
## Outputs of ViralLink

ViralLink outputs a number of different files. The most important are the final network and analysis results files:
1. **The recontructed intracellular network:**
	- in edge table text format: *4_create_network/final_network.txt*
	- in Cytoscape format: *5_betweenness_and_cluster_analysis/causal_network.cys*
	
2. **Node annotations for each gene/protein in the network:**
	- Without betweenness centrality measures and cluster annotations: *4_create_network/node_table.txt*
	- With betweenness centrality measures and cluster annotations: *5_betweenness_and_cluster_analysis/node_table_betweenness_cluster.txt*
	
3. **Overrepresented functions/pathways:**
	- All related files output to the folder: *6_functional_analysis/*

----
## References

[*Gordon et al.*](https://www.nature.com/articles/s41586-020-2286-9):

> Gordon DE., Jang GM., Bouhaddou M., *et al.*. (2020). A SARS-CoV-2 protein interaction map reveals targets for drug repurposing, *Nature*, https://doi.org/10.1038/s41586-020-2286-9.

