# 1. filter_networks_by_functions.R

Script to reformat networks so that functions are the last nodes instead of DEG nodes. 
* Removes the TF-DEG interactions and adds TF-function interactions based on functions required.
* Takes all upstream connections which are associated with the supplied functions and removes orphans.
* Takes different functions for DEGs and upstream PPIs.
* If Cytoscape is open, the script will load the network into it and save as a *.cys* file

**Input:**
1. **network**: Causal network text file (output from workflow ('combined_edge_node_tables.R'))
2. **node_table**: Node table of causal network (output from workflow ('combined_edge_node_tables.R'))
3. **reactome_funcs**:  Reformatted results table from overrepresentation analysis of DEGs (output from workflow ('reformat_functional_result.R'))
4. **reactome_assoc**: Reformatted reactome-uniprot association file (provided: previously downloaded from Reactome website and reformatted April 2020) - *input_files/reactome_annotations_uniprot_300420.txt*
5. **deg_functions**: Text file containing list of overrepresented DEG Reactome functions to include in output network. Use Reactome function names eg. "Immune System". Must be present in the *reactome_funcs* file. One function per line of text file.
6. **ppi_functions**: Text file containing list of upstream functions (don't have to be overrepresented) to include (will filter the human binding proteins, intermediary signalling proteins and the TFs). Use Reactome function names eg. "Immune System". Must be present in the *reactome_assocs* file. One function per line of text file.

**Output:**
* A standalone network of supplied functions in text format
* Node table and edge annotation table which have a column labelled as specified to indicate the the edges/nodes are in this network 
  - This is for visualising the network within larger networks (includes the deg nodes (and tf-deg edges) which are collapsed into functional categories). 
  - The node annotation table can also be used alongside the functional standalone network for layer and functional annotations.
* Cytoscape file containing the network (if cytoscape is open locally).

**Run from command line:**

```
Rscript network node_table reactome_funcs reactome_assoc deg_functions ppi_functions name output_directory
```
