# 1. combined_edge_node_tables.R

Script to combine the covid subnetworks into 1 network table and one node table

**Input:**
* Receptor-tf network output from tiedie
* SARS-CoV-2 - human binding protein network (columns 'viral_protein', 'human_protein')
* Contextualised regulatory network (TFs - DEGs) (incl. columns 'DEG',"	TF", "consensus_stimulation") output from 'get_regulator_deg_network.R'
* Heats values output from TieDie
* Sars proteins gene symbol to uniprot conversion table
* Differential expression table (unfiltered)

**Output:**
* Network file where each line represents an interaction
* Node table where each lines represents one node in the network

**Run from command line:**

```
Rscript combined_edge_node_tables.R tiedie_network.txt tiedie_heats.NA virus-human-interactions.txt virus_gene_annotations.txt tf-deg_interactions.txt unfiltered_differential_expression.csv id_type("symbol" or "uniprot") output_directory/
```