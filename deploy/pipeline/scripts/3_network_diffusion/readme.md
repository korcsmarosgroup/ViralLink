# 1. prepare_tiedie_input.R

Script to prepare the input files for TieDIE

**Input:**
* Contextualised PPI network output from 'filter_network_expressed_genes.R'
* TF-DEGs network file output from 'get_regulator_deg_network.R'
* Differentially expressed gene file output from 'diff_expression_deseq2.R'
* Viral protein- human binding protein file (provided - based on *Gordon et al.*)

**Output:**
* pathway.sif - sif format contextualised PPI (Omnipath) network
* upstream.input - text file containing the upstream genes with a weight and direction (human binding partners)
* downstream.intput - text file containing the downstream genes with a weight and direction (TFs)

**Run from command line:**

```
Rscript prepare_tiedie_input.R contextualised_ppi_network.txt tf-deg_interactions.txt filtered_differential_expression_data.csv viral_human_interactions.txt output_directory
```

# 2. tiedie.py

Script to run diffusion analysis using TieDIE

**Minimum Inputs:**
* Separate source/target input heat files: tab-separated, 3 columns each with <gene> <input heat> <sign (+/-)> (as created in the prepare_tiedie_input.R script)
* A search pathway in *.sif* format (geneA <interaction> geneB)

**Outputs:**
* Creates a directory in the current working directory, and writes all output to that
* Information and warnings are logged to standard error

**Run from command line:**

```
python3 TieDie/tiedie.py -u upstream.input -d downstream.input -n network.sif -o outdput_directory
```