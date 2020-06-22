# Script to filter a normalised counts table only for genes which are expressed
#
# Input: Normalised counts matrix with genes as rows and samples as columns, tab delimited. First column contains gene
#        names/ids, all other columns are counts values.
#
# Output: Tab delimited text file containing all genes deemed expressed with columns: "Gene", "mean_expression",
#         "log2_mean_expression" and "zscore".

# Packages
from scipy.stats import gaussian_kde
import argparse
import numpy as np
import math
import sys
import os


def parse_args(args):
    help_text = \
        """
        === Filter Expression Gaussian ===
        
        Script to filter a normalised counts table only for genes which are expressed.
        """

    parser = argparse.ArgumentParser(description=help_text)

    parser.add_argument("-i", "--input-file",
                        help="<path to the data file> [mandatory]",
                        type=str,
                        dest="input_file",
                        action="store",
                        required=True)

    parser.add_argument("-o", "--output-folder",
                        help="<path to the output folder> [mandatory]",
                        type=str,
                        dest="output_folder",
                        action="store",
                        required=True)

    results = parser.parse_args(args)
    return results.input_file, results.output_folder


def main():

    input_file, output_folder = parse_args(sys.argv[1:])

    with open(input_file) as value_list:
        value_list.readline() # Skip first line / header
        log_mean = [] # generated here
        gene_names = []
        expression_value = [] # raw from input table
        for line in value_list:
            line = line.strip().split("\t")
            mean_ex = sum(map(float,line[1:]))/(len(line) - 1) # Calculate mean of all count values
            #print(mean_ex)

            if mean_ex == 0:
                continue

            #print(type(mean_ex))
            log_val = math.log(mean_ex+1,2) # log2
            log_mean.append(log_val)
            expression_value.append(mean_ex)
            gene_names.append(line[0])

    log_mean = np.array(log_mean)

    # Creating the Gauss-curve,
    kernel = gaussian_kde(log_mean)

    # Creating X axis -> divide the list for 100 units, xi numpy lists contains that 100 values --> expected value = most oftest value, middle of Gaus-curve
    xi = np.linspace(log_mean.min(), log_mean.max(), 100)

    # Calculate y for each x point
    yi = kernel.evaluate(xi)

    # Expected value calculation, which x is by the max y value? (np.argmax(yi) = position)
    mu = xi[np.argmax(yi)]

    # log_mean > mu  = list of boolean values; mean of values right from the expected value
    U = log_mean[log_mean > mu].mean()

    #calculation of standard deviation
    sigma = (U - mu) * np.sqrt(np.pi / 2)

    #new score: deviancy from the mean divided by sigma (standard deviation)
    #z-value: relative value: deviation from the mean in the st.dev in the data ---> Gaus-curve:  0.001 - 3 deviation (sigma)
    zscore= (log_mean - mu) / sigma

    # Save results
    outputname = os.path.join(output_folder, '1_process_expression_data', 'expressed_genes.txt')
    with open(outputname, 'w') as output_file:
        output_file.write('Gene' + "\t" + 'mean_expression' + "\t" + "Log2_mean_expression" + "\t" + "zscore" + "\n")
        result = np.where(zscore > -3)
        for i in np.nditer(result):
            output_file.write(str(gene_names[i]) + '\t' + str(expression_value[i]) + '\t' + str(log_mean[i]) + "\t" + str(zscore[i]) + "\n")


if __name__ == "__main__":
    main()
