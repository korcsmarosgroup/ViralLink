from time import strftime
import subprocess
import sys
import os


scripts_folders = {
    "1_process_expression_data": ["diff_expression_deseq2.R",
                                  "filter_expression_gaussian.py"],
    "2_process_a_priori_networks": ["Downloading_omnipath_dorothea.R",
                                   "filter_network_expressed_genes.R",
                                   "get_regulator_deg_network.R"],
    "3_network_diffusion": ["prepare_tiedie_input.R",
                            "tiedie.py"],
    "4_create_network": ["combined_edge_node_tables.R"],
    "5_betweenness_and_cluster_analysis": ["betweenness_and_clustering.R",
                                           "cytoscape_visualisation.R"],
    "6_functional_analysis": ["network_functional_analysis.R",
                              "cluster_functional_analysis.R",
                              "network_aware_functional_analysis.R",
                              "reformat_functional_result.R"]
}
scripts_parameters = {
    "diff_expression_deseq2.R": ["counts",
                                 "meta",
                                 "outdir",
                                 "lfccutoff",
                                 "pcutoff"],
    "filter_expression_gaussian.py": ["-i","1_process_expression_data/counts_normalised_deseq2_test.txt",
                                      "-of", "outdir"],
    "Downloading_omnipath_dorothea.R": ["outdir"],
    "filter_network_expressed_genes.R": ["1_process_expression_data/expressed_genes.txt",
                                         "2_process_a_priori_networks/unprocessed_networks/dorothea_abc_signed_directed.txt",
                                         "2_process_a_priori_networks/unprocessed_networks/omnipath_signed_directed.txt",
                                         "id_type",
                                         "outdir"],
    "get_regulator_deg_network.R": ["2_process_a_priori_networks/dorothea_contextualised_network.txt",
                                    "1_process_expression_data/deseq2_res_condition_test_vs_control_filtered.csv",
                                    "id_type",
                                    "outdir"],
    "prepare_tiedie_input.R": ["2_process_a_priori_networks/omnipath_contextualised_network.txt",
                               "2_process_a_priori_networks/contextualised_regulator-deg_network.txt",
                               "1_process_expression_data/deseq2_res_condition_test_vs_control_filtered.csv",
                               "hbps",
                               "outdir"],
    "tiedie.py": ["-u", "3_network_diffusion/input_files/upstream.input",
                  "-d", "3_network_diffusion/input_files/downstream.input",
                  "-n", "3_network_diffusion/input_files/pathway.sif",
                  "-o", "3_network_diffusion/TieDIE"],
    "combined_edge_node_tables.R": ["3_network_diffusion/TieDIE/tiedie.cn.sif",
                                    "3_network_diffusion/TieDIE/heats.NA",
                                    "hbps",
                                    "sars",
                                    "2_process_a_priori_networks/contextualised_regulator-deg_network.txt",
                                    "1_process_expression_data/deseq2_res_condition_test_vs_control.csv",
                                    "id_type",
                                    "outdir"],
    "betweenness_and_clustering.R": ["4_create_network/final_network.txt",
                                     "4_create_network/node_table.txt",
                                     "outdir"],
    "cytoscape_visualisation.R": ["4_create_network/final_network.txt",
                                  "5_betweenness_and_cluster_analysis/node_table_betweenness_clusters.txt",
                                  "outdir"],
    "network_functional_analysis.R": ["4_create_network/node_table.txt",
                                      "2_process_a_priori_networks/omnipath_contextualised_network.txt",
                                      "2_process_a_priori_networks/dorothea_contextualised_network.txt",
                                      "outdir"],
    "cluster_functional_analysis.R": ["5_betweenness_and_cluster_analysis/node_table_betweenness_clusters.txt",
                                      "2_process_a_priori_networks/omnipath_contextualised_network.txt",
                                      "outdir"],
    "network_aware_functional_analysis.R": ["4_create_network/node_table.txt",
                                      "2_process_a_priori_networks/omnipath_contextualised_network.txt",
                                      "anubixreactome",
                                      "outdir"],
    "reformat_functional_result.R": ["outdir"]
}


def checking_input_parameters(script_parameters):
    """
    Checking the parameters
    """
    if not os.path.isfile("parameters.yml"):
        sys.stdout.write(f" WARNING: There is no appropriate parameter file! It should be parameters.yml\n")
        sys.exit(1)

    neccessary_parameters = ["counts", "meta", "lfccutoff", "pcutoff", "id_type", "hbps", "sars", "outdir", "anubixreactome"]
    for nec_param in neccessary_parameters:
        if nec_param not in script_parameters:
            sys.stdout.write(f" WARNING: A parameter is missing from the parameters.yml file: {nec_param}\n\n")
            sys.exit(2)


def get_parameters():
    """
    Get all of the parameters from the parameter.yml file
    """
    parameter_file = "parameters.yml"
    parameters = {}

    with open(parameter_file, 'r') as param:

        for line in param:
            line = line.strip().split(": ")

            parameter_name = line[0]
            parameter = line[1]

            if parameter_name not in parameters:
                parameters[parameter_name] = parameter

    return parameters


def checking_parameters_of_the_scripts(call_command):
    """
    Checking that the parameter files for the given script exists or not
    """
    for param in call_command:

        if param.split("/")[-1] == "TieDIE":
            continue

        if "/" in param and not param.endswith(".R") and not param.endswith(".py"):
            if not os.path.isfile(param):
                sys.stdout.write(f" WARNING: One of the parameters of the script does not exist: "
                                 f"{param}\n\n")
                sys.exit(3)


def checking_errors():
    """
    Checking that the scripts have errors or not
    """
    with open("virallink.out", 'r') as log:

        for line in log:
            line = line.strip()

            if "Execution halted" in line:
                sys.stdout.write(f" WARNING: There was an error during the running! Please check the 'virallink.out' "
                                 f"file for more details.\n\n")
                sys.exit(4)


def run_script(script_parameters, parameters_for_the_script, script, step, call_script):
    """
    Function to run the given script
    """
    if script == "tiedie.py":
        call_command = [call_script, f"scripts/{step}/TieDie/{script}"]
    else:
        call_command = [call_script, f"scripts/{step}/{script}"]

    for p in parameters_for_the_script:
        if p in script_parameters:
            call_command.append(script_parameters[p])
        elif len(p) < 4 and p not in script_parameters:
            call_command.append(p)
        else:
            new_parameter = f"{script_parameters['outdir']}/{p}"
            call_command.append(new_parameter)

    checking_parameters_of_the_scripts(call_command)

    run = subprocess.Popen(call_command, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    run.communicate()

    checking_errors()

    print(f'*** [{strftime("%H:%M:%S")}] {script} finished successfully... ***\n')


def main():
    """
    Main function of the script
    """
    print(f'\n*** ViralLink pipeline ***')

    if os.path.isfile("virallink.out"):
        os.remove("virallink.out")

    script_parameters = get_parameters()
    print(f'\n*** Checking input parameters... ***')
    checking_input_parameters(script_parameters)
    print(f'*** Input parameters are fine, starting... ***\n')

    for step in scripts_folders:

        step_name_array = step.split("_")[1:]
        step_number = step.split("_")[0].strip()
        step_name = " ".join(step_name_array).upper()

        print(f"\n*** Step {step_number}/6 - {step_name} ***\n")
        for script in scripts_folders[step]:

            print(f'*** [{strftime("%H:%M:%S")}] {script} is running... ***')
            parameters_for_the_script = scripts_parameters[script]

            if script.endswith(".R"):
                call_script = "Rscript"
                run_script(script_parameters, parameters_for_the_script, script, step, call_script)

            elif script.endswith(".py"):
                call_script = "python3"
                run_script(script_parameters, parameters_for_the_script, script, step, call_script)

    print(f'\n*** ViralLink pipeline was successfully finished! ***\n')


if __name__ == '__main__':
    main()
