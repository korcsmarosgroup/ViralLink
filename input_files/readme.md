## Input files provided for the workflow:

0. The user should provide a raw counts table with sample names as column headers and gene names (gene symbol or UniProt) as row names. (see *example_expression_data/* for an example)

1. empty_mapping_table.txt
	* This example mapping table should be completed with the information based on the provided expression data
	* The table should contain one row per input sample
	* *sample_name* column should contain the sample name matching the relevant column header in the counts table.
	* *condition* column should contain "test" or "control"  depending on whether the sample is a test or control sample (all other values will be ignored). Differential expression is calculated by comparing "test" samples to "control" samples.

2. sarscov2-human_ppis_gordon_april2020.txt
	* Protein-protein interactions (PPIs) between SARS-CoV-2 proteins and human binding proteins predicted by *Gordon et al.* (doi: 10.1038/s41586-020-2286-9) obtained from IntAct in April 2020.
	* Can be exchanged for any other viral-host PPI interactions written in the same format: tab delimited, two columns with headers *viral_protein* and *human_protein* with IDs in UniProt foramt.

3. sarscos2_protein_annotations.txt
	* Gene annotations for the SARS-CoV-2 proteins in the PPI interaction file (*sarscov2-human_ppis_gordon_april2020.txt*). Obtained from IntAct.
	* Can be exchanged with any annotation file which contains the viral UniProt IDs in the column *Accession* and corresponding gene names in the columns *gene_symbol*. Tab delimited.

4. reactome_annotations_uniprot_300420.txt
	* This file contains Reactome associations for all human UniProt IDs. It was downloaded from the Reactome website on 30th April 2020 and reformated to contain 2 columns: uniprot id column *gene* and a column of Reactome pathway names seperated by ";", named *reactome*. The file is tab delimited.


## Also provided to help determine the correct input formats of expression data:

1. example_expression_data/
	* Unnormalsed counts table (tab delimited) from GSE147507
	* Metadata table containing condition names for each of the samples in the counts table in the columns *sample_name* and *condition*. 
	  - *sample_name* should match the column headers in the counts table.
	  - *condition* should contain *test* or *control* (all other values will be ignored). Differential expression is calculated by comparing *test* samples to *control* samples.