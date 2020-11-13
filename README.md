# ViralLink

## Overview

ViralLink is a systems biology workflow which reconstructs and analyses networks representing the effect of viral infection on specific human cell types.

These networks trace the flow of signal from intracellular viral proteins through their human binding proteins and downstream signalling pathways, ending with transcription factors regulating genes differentially expressed upon viral exposure. In this way, the workflow provides a mechanistic insight from previously identified knowledge of virally infected cells. By default, the workflow is set up to analyse the intracellular effects of SARS-CoV-2, requiring only transcriptomics counts data as input from the user: thus encouraging and enabling rapid multidisciplinary research. However, the wide ranging applicability and modularity of the workflow facilitates customisation of viral context, *a priori* interactions and analysis methods.

ViralLink is currently available as a series of R and Python scripts which can be run through two different methods:<br>
With docker: the whole pipeline and/or the separate stages can be run from within a docker container which negates the need for local Python and R installations making the pipeline easily accessible (recommended).<br>
Without docker: the whole pipeline (via a Python wrapper script) and/or the separate scripts can be run locally using local installations of Python and R with associated packages.


More detailed information about ViralLink is available in the following paper:

> Treveil A., Bohar B., Sudhakar P. et al. [ViralLink: An integrated workflow to investigate the effect of SARS-CoV-2 on intracellular signalling and regulatory pathways] https://doi.org/10.1101/2020.06.23.167254, _BioRxiv_, (2020)

<img src="virallink_overview.png" align="center" width="500">

----
## Getting Started

You can run the pipeline with or without a dockerisation. In both of the options, you can run the whole pipeline at once or you can run the different steps separately from each other. The dockerised and non dockerised versions have been successfully tested on OSX and Linux. The dockerised version has also been successfully tested on Windows 10, although a few extra steps are required. <br><br>
NOTE: The whole pipeline (with the example input data) needs around 6 GB of memory! But the memory allocation will vary on the input dataset. For example if you try to use it on a bigger dataset then they may require more memory! You can change the memory available to Docker in the Docker application settings.

### Dockerised pipeline

The dockerised pipeline requires only a few commands to run the whole analysis. Here you need to have Docker installed and open on your computer (docker version >=3). This is easily downloadable from the Docker website (www.docker.com). Also remember to edit the memory settings to give Docker at least 6 GB of memory. If you are running the dockerised pipeline on Windows please refer to the *Windows-specific set up* section for additional set up requirements. If running on OSX or Linux please skip the *Windows-specific set up* section.

#### Windows-specific set up

1.  Running the dockerised pipeline on Windows requires Docker to be installed. Running Docker requires enabling of Hyper-V in BIOS which is only available for Windows 10 Pro, Enterprise, and Education (*https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v*).

2. WSL2 should be installed and set as default (*https://docs.microsoft.com/en-us/windows/wsl/install-win10*). N.B. for step 6 in this webpage we succeessfully tested with Ubuntu 20.04 LTS.

3.  In the Docker settings select "WSL2 based engine".

4. Download the ViralLink repository using the _Clone or download_ button on the Github web page or by typing the following into the Command Prompt (if you have *git* installed):

```
cd folder/to/clone-into/
git clone git@github.com:korcsmarosgroup/ViralLink.git
```

4. Open the Command Prompt and convert all ".sh" files within the ViralLink folder to 'unix' format (they are automatically converted to dos when downloaded). You may need to install *dos2unix* in order to so this (*http://gnuwin32.sourceforge.net/packages/cygutils.htm*).

```
cd /path/to/ViraLink
dos2unix entry_point.sh
dos2unix install_base_layer.sh
dos2unix install_python.sh
dos2unix install_r.sh
```

5. From here you should be able to continue with the instructions within the *Running dockerised ViralLink* section below. Use the Command Prompt as your terminal.

#### Running dockerised ViralLink

To use the dockerised ViralLink, download the ViralLink repository using the _Clone or download_ button on the Github web page or by typing the following into a terminal window (of course, if you already did this during the Windows instructions then skip it):

```
cd folder/to/clone-into/
git clone git@github.com:korcsmarosgroup/ViralLink.git
```
Once the GitHub repository is successfully downloaded, then you need do the following within the command line terminal:
Go to the folder, where you downloaded the pipeline:
```
cd folder/to/clone-into/ViralLink
```
NB. if you plan to provide your own input files please refer to the *Inputs to ViralLink section* to specify the input files before you run the pipeline. Otherwise the pipeline will run with the provided default input files. Do this before you build the docker image.

Type the following command into the terminal: this builds a docker image, starts a docker container and steps into this container (it will take time):
```
bash virallink.sh
```
If the above command successfully finished, you should see something like this:
```
root@3c172830ba15:/home/virallink#
```
After you got this prompt in your terminal, you can run the whole pipeline with the following command:
```
python3 virallink.py
```

The speed of the whole pipeline run is roughly between 2 - 2 ½ hours, but this will depend on the hardware which it is being run on.

If you want to run any steps separately from the others, you need to navigate into the scripts folder after you got your prompt inside the docker container: ```root@3c172830ba15:/home/virallink#```. Every step has its own readme file, which contains the information on how you can run the given step only. For example:
```
cd scripts/1_process_expression_data/
```

#### Save files from the docker container to your computer

* If you are done with your pipeline run and you would like to save out the results from the docker container to your computer, you can do that with the following commands.
* First of all, do not close the docker container! Then, open a new terminal tab and run the following command to save the results in your computer:
```
docker cp virallink:/home/virallink/output_directory /path/on/your/computer/
docker cp virallink:/home/virallink/virallink.out /path/on/your/computer/
```

#### Debugging

* Upon running ‘bash virallink.sh’ an error such as the following means that docker is not installed or running on your computer:
```
virallink.sh: line 4: docker: command not found
```

* Upon running ‘bash virallink.sh’ an error such as the following means that the specified port is reserved. 
```
docker: Error response from daemon: Ports are not available: listen tcp 0.0.0.0:5900: bind: address already in use.
```
You should be able to get around this problem by opening the _virallink.sh file in a text editor and deleting the line where the reserved port is mentioned:
```
-p 5900:5900 \
```

### Non-dockerised pipeline

The pipeline can also be run using local installations of Python and R (with associated packages, see below for details), without the need for Docker.

#### Prerequisites

ViralLink should run on any UNIX system, and has been tested on Linux and Mac OS. Windows compatibility is not supported at this time - (use the dockerised pipeline to run ViralLink on Windows).

**R (≥ 4.0.0)** and **Python 3** are required to run the workflow. Additionally, for clustering analysis and visualisation, **Cytoscape (≥ 7.0.0)** is required (AND IT MUST BE OPEN LOCALLY when the scripts are run - or these functions will be skipped).

Furthermore, the following packages are required:

> NB. The R packages should be installed automatically as part of the workflow, but it is advisable to pre-install them if you can. The Python packages must be pre-installed.

**R packages:**

```
tidyverse
org.Hs.eg.db
DESeq2
OmnipathR (needs "devtools")
RCy3 (≥ 2.6.0)
igraph
reshape2
naniar
clusterProfiler
ReactomePA
ANUBIX
```

To install R packages, type the following into the terminal:

```
R
install.packages(c("BiocManager","tidyverse","devtools", "igraph","reshape2","naniar"))
require(devtools)
install_github('saezlab/OmnipathR')
install_bitbucket("sonnhammergroup/anubix")
BiocManager::install("RCy3","DESeq2","clusterProfiler","ReactomePA","org.Hs.eg.db")
quit()
```

**Python3 packages:**

```
scipy (≥ 0.12.0)
numpy (≥ 1.7)
networkx
distributions
```
To install Python3 packages, type the following into the terminal:

```
pip install numpy networkx scipy distributions
```

#### Running non-dockerised ViralLink

To use ViralLink, download the ViralLink repository using the _Clone or download_ button on the Github web page or by typing the following into a terminal window:

```
cd folder/to/clone-into/
git clone https://github.com/korcsmarosgroup/ViralLink
```

Make sure to navigate to the repository main directory before running the script. Do not change the folder structure or file names.

> NB. Ensure the *parameters.yml* file have been edited prior to running the script (unless you're running the example input data).<br>
> And do not forget to open Cytoscape locally!
>
```
*Open Cytoscape locally*
cd folder/to/clone-into/ViralLink/deploy/pipeline
python3 virallink.py
```

The speed of the workflow will depend on the specification of the computer. The most intensive parts are the tiedie.py script in step 3 and the functional analysis of step 6. It is likely to take between 30 minutes and a 2 hours to complete everything.

If you want to run any steps separately from the others, you need to navigate into the scripts folders. Every step has its own readme file, which contains the information on how you can run the given step only. For example:
```
cd folder/to/clone-into/ViralLink/deploy/pipeline/scripts/1_process_expression_data/
```

#### Debugging

* The wrapper outputs command line messages, warnings and errors to the file *virallink.out*. Open this in a text editor to try to identify issues with the workflow.

* Make sure that the *virallink.py* script is being run in Python 3 and from the main directory of the ViralLink repository. Make sure none of the folders or files have been renamed or moved.

* Ensure that the layout of the *parameters.yml* file and the parameter names have not been altered. Regarding the specified parameters, make sure that the file paths are reachable from the main directory of the ViralLink repository.

* The wrapper should install all required R packages, but this isn't always possible and can therefore cause errors running the workflow. Python packages must be pre-installed. Try to install all required packages (see section above) prior to running the wrapper.

* If you are missing *.cys* files or clustering results, make sure Cytoscape is open locally before running the workflow.

----

## Inputs to ViralLink

When running the whole workflow (not using the scripts seperately), all input files and parameters should be specified by editing the *parameters.yml* file using a text editor. For description of these parameters, see the *parameters_description.tsv* file. Both files are located in the folder *deploy/pipeline/*.
> NB.
> * Do not edit the parameter names in the *parameters.yml* file.
> * File paths can be relative and slashes are not required at the beginning and end of the paths.
> * The whole workflow wrapper will run all scripts in step 1 -> step 6 inclusive. The only script not run is step 7, as it requires interpretation of the results for the purpose of selecting functions of interest to visualise.
> The below changes must be made before starting the docker container

If the user would like to run the scripts separately from the whole workflow wrapper, each script should be run from the command line, specifying the required input parameters. The parameters for each script can be found in the *deploy/pipeline/scripts/parameters_all.tsv* file and in the script *readme.md* files.

To run ViralLink on your own transcriptomics data there are two required input files: a normalised counts table and a metadata table. However it is also possible (although more complicated) to run the workflow using instead a normalised counts table (of only test conditions), a metadata file, a table of prefiltered differentially expressed genes and a table of unfiltered differentially expressed genes. To use the later set of input files see the section *How to skip differential expression step*.

**The input files for ViralLink are as follows:**

1. An unnormalised counts table from a human transcriptomics study. Genes (using gene symbols or UniProt protein IDs) as rows and samples as columns.  (REQUIRED FROM USER)

2. A tab-delimited two-column metadata table specifying test and control sample IDs in the following format. Here the sample names must match the headers in the normalised counts table. For an example metadata file see the *input_data* folder.  (REQUIRED FROM USER)


|   sample_name    |   condition  |
| ------------- | ------------- |
|   sample1    |   test   |
|   sample2    |   test   |
|   sample3    |   control    |

3. Viral - human protein-protein interaction table
  - Interactions for SARS-CoV-2 from [*Gordon et al.*](https://www.nature.com/articles/s41586-020-2286-9) provided: *input_files/sarscov2-human_ppis_gordon_april2020.txt*
  - Tab-delimited with one line per interaction
  - 2 columns named *viral_protein* and *human_protein*
  - An optional 3rd column named *sign* can contain either *+* or *-* to indicate an activator or an inhibitory interaction (respectively). If this column is not provided, all interactions are assumed to be inhibitory.
  - Human proteins in UniProt format
 
4. Gene symbol annotations for all input viral proteins, for ease of data interpretation.
  - Annotations for the Gordon *et al.* SARS-CoV-2 proteins provided: *input_files/sarscov2_protein_annotations.txt*
  - Tab-delimited with one line per protein
  - At least 2 columns named *Accession* and *gene_symbol*

5. Reactome annotations for human Ensembl IDs created specifically for ANUBIX network aware pathway analysis tool
  - Required for network aware pathway analysis using ANUBIX ([*Castresana-Aguirre and Sonnhammer*](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7423893/))
  - Obtained from *https://bitbucket.org/sonnhammergroup/anubix/src/master/anubix_benchmark/* on 05-11-2020 and saved as *input_files/anubix_reactome_pathways.txt*
  - Tab delimited text file with Ensembl gene IDs in column 1 and pathway annotations in column 2.
  
6. Reactome annotations for all human UniProt IDs
  - Only required for the *filter_networks_by_functions.R* script (which is not part of the Python wrapper)
  - Provided based on data downloaded from Reactome on 30/04/2020: *input_files/reactome_annotations_uniprot_300420.txt*
  - Tab-delimited text file with 2 columns: uniprot id column "gene" and a column of Reactome pathway names separated by ";", named "reactome"
 
**Additional required parameters:**

1. Log2 fold change cut off
  - Genes must have log2 fold change more than or equal the modulus of this value to be differentially expressed
 
2. Adjusted p value cut off
  - Genes must have adjusted p value (from differential expression analysis) less than than or equal to this value to be differentially expressed
 
3. Type of ID in the input expression data
  -  Must be *symbol* (for gene symbols) or *uniprot* (for Uniprot IDs)
  
### How to skip the differential expression step


To run ViralLink on your own transcriptomics data there are two required input files: a normalised counts table and a metadata table. However it is also possible (although more complicated) to run the workflow using instead a normalised counts table (of only test conditions), a metadata file, a table of prefiltered differentially expressed genes and a table of unfiltered differentially expressed genes. In order to do this th workflow must skip the differential expression step. Please follow these instructions:

1. Create a blank text file and save as *deploy/pipeline/virallink.out*.

2. Format your normalised counts table and save in "deploy/pipeline/output_directory/1_process_expression_data/counts_filename.txt" (where *output_directory* is specified in the *paramters.yml* file).
  - Genes are rows and samples are columns
  - Tab-delimited file
  - First column should contain gene names/ids and all other columns are counts values for test samples (as expressed genes are calculated only on test samples).   - The first row should contain a header. 
  
3. Format your filtered and unfiltered differential expression tables and save as *deploy/pipeline/output_directory/1_process_expression_data/
unfiltered_degs_filename.csv* and *deploy/pipeline/output_directory/1_process_expression_data/filtered_degs_filename.csv* (where *output_directory* is specified in the *paramters.yml* file).
  - The first column contains gene names/ids with header *Gene*.
  - Additionally columns with header *padj* and *log2FoldChange* must exist in the datasets. 
  - The files must be saved in csv format
  
3. Edit the *deploy/pipeline/virallink.py* file to specify the filepaths of the files from steps 2 and 3. To do this:
  - Replace *1_process_expression_data/counts_normalised_deseq2.txt* with *1_process_expression_data/counts_filename.txt*
  - Replace *"1_process_expression_data/deseq2_res_condition_test_vs_control_filtered.csv* with *1_process_expression_data/filtered_degs_filename.csv* (there are multiple instances that need to be changed)
  - Replace *1_process_expression_data/deseq2_res_condition_test_vs_control.csv* with *1_process_expression_data/unfiltered_degs_filename.csv*


4. Edit the file *deploy/pipeline/virallink.py*"
  - Remove *"diff_expression_deseq2.R"* from lines 8. After doing this lines 8/9 should look like this:

> "1_process_expression_data": ["filter_expression_gaussian.py"],

  - Also remove or comment out these lines:

> if os.path.isfile("virallink.out"):
>       os.remove("virallink.out")

5. The whole pipeline wrapper can now be run as defined previously.

## Outputs of ViralLink

ViralLink outputs a number of different files. The most important are the final network and analysis results files:
1. **The reconstructed intracellular network:**
  - In edge table text format: *4_create_network/final_network.txt*
  - In Cytoscape format: *5_betweenness_and_cluster_analysis/causal_network.cys*
 
2. **Node annotations for each gene/protein in the network:**
  - Without betweenness centrality measures and cluster annotations: *4_create_network/node_table.txt*
  - With betweenness centrality measures and cluster annotations: *5_betweenness_and_cluster_analysis/node_table_betweenness_cluster.txt*
 
3. **Overrepresented functions/pathways:**
  - All related files output to the folder: *6_functional_analysis/*

----
## References

[*Gordon et al.*](https://www.nature.com/articles/s41586-020-2286-9):

> Gordon DE., Jang GM., Bouhaddou M., *et al.*. (2020). A SARS-CoV-2 protein interaction map reveals targets for drug repurposing, *Nature*, https://doi.org/10.1038/s41586-020-2286-9.

[*Castresana-Aguirre and Sonnhammer*](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7423893/):

> Castresana-Aguirre M. and Sonnhammer ELL. (2020). Pathway-specific model estimation for improved pathway annotation by network crosstalk, *Scientific Reports*, https://doi.org/10.1038/s41598-020-70239-z.

