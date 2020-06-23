import subprocess
import os


scripts_folders = {
    "1_process_expression_data": ["diff_expression_deseq2.R",
                                  "filter_expression_gaussian.py"],
    "2_process_a_prior_networks": ["Downloading_omnipath_dorothea.R",
                                   "filter_network_expressed_genes.R",
                                   "get_regulator_deg_network.R"],
    "3_network_diffusion": ["prepare_tiedie_input.R",
                            "tiedie.py"],
    "4_create_network": ["combined_edge_node_tables.R"],
    "5_betweenness_and_cluster_analysis": ["betweenness_and_clustering.R",
                                           "cytoscape_visualisation.R"],
    "6_functional_analysis": ["network_functional_analysis.R",
                              "cluster_functional_analysis.R",
                              "reformat_functional_result.R"]
}
output_folders = [
    "1_process_expression_results",
    "2_process_a_priori_networks",
    "3_network_diffusion",
    "4_create_network",
    "5_betweenness_and_cluster_analysis",
    "6_functional_analysis"
]


def get_parameters(step, script):
    """
    Get the given parameters for the given script from the parameters file
    """
    parameter_file = "parameters.tsv"
    scripts_parameters = []

    with open(parameter_file, 'r') as param:

        param.readline()

        for line in param:
            line = line.strip().split('\t')

            step_name = line[0]
            script_name = line[1]
            parameter_name = line[2]
            parameter = line[3]

            if script_name.endswith(".R"):
                if step == step_name and script == script_name:
                    scripts_parameters.append(parameter)

            elif script_name.endswith(".py"):
                if step == step_name and script == script_name:
                    scripts_parameters.append(parameter_name)
                    scripts_parameters.append(parameter)

            if parameter_name == "outdir":
                output_directory = parameter

    return scripts_parameters, output_directory


def main():
    """
    Main function of the script
    """
    print(f'\n*** ViralLink pipeline starting... ***\n')

    if os.path.isfile("all.Rout"):
        os.remove("all.Rout")

    for step in scripts_folders:

        step_name_array = step.split("_")[1:]
        step_number = step.split("_")[0].strip()
        step_name = " ".join(step_name_array).upper()

        print(f"\n*** Step {step_number}/6 - {step_name} ***\n")
        for script in scripts_folders[step]:

            print(f"*** {script} is running... ***")
            parameters_of_the_script, output_directory = get_parameters(step, script)
            command_parameters = []

            if script.endswith(".R"):
                script_command = "Rscript"
                command_parameters.append(script_command)

                command_parameters.append(f"scripts/{step}/{script}")
                for parameters in parameters_of_the_script:
                    if parameters.split("/")[0] in output_folders:
                        new_parameters = f"{output_directory}/{parameters}"
                        command_parameters.append(new_parameters)
                    else:
                        command_parameters.append(parameters)

                command = command_parameters
                run = subprocess.Popen(command, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
                my_stdout, my_stderr = run.communicate()

            elif script.endswith(".py"):
                for parameters in parameters_of_the_script:
                    if parameters.split("/")[0] in output_folders:
                        new_parameters = f"{output_directory}/{parameters}"
                        command_parameters.append(new_parameters)
                    else:
                        command_parameters.append(parameters)

                if script == "tiedie.py":
                    os.system(f"python3 scripts/{step}/TieDie/{script} {' '.join(command_parameters)}")
                else:
                    os.system(f"python3 scripts/{step}/{script} {' '.join(command_parameters)}")

            print(f"*** {script} finished successfully... ***\n")

    print(f'\n*** ViralLink pipeline was successfully finished! ***\n')


if __name__ == '__main__':
    main()
