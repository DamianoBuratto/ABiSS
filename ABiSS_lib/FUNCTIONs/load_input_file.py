"""
This function contains a dictionary with all the keywords of the ABiSS program associated with their default value.
It takes an input-file as input, read each line skipping the comments (the line start with #), and retrieve all the
pairs keyword/value (in the form keyword = value). It than update the dictionary with the values from the input file.
A second function print a sh file that can be imported in the bash program to get all the variables value.
"""
import argparse
from warnings import warn
from os import access, R_OK
from os.path import isfile

keywords_variable_dict = {
    'TEMP_FILES_FOLDER': {"Value": "", "Array": "no",
                          "Default": "",
                          "Comment": "path and name of the temp file folder. Set by the program to ${RUN_FOLDER}/tempFILES"},
    'SystemName': {"Value": "CXCR2", "Array": "no",
                   "Default": "CXCR2",
                   "Comment": "Name of the system that is going to be run."},
    'Complex_file_name': {"Value": "", "Array": "no",
                          "Default": "",
                          "Comment": "Name of the file with the complex structure. MANDATORY."},
    'tprFILE': {"Value": "system_Compl_MD", "Array": "no",
                "Default": "system_Compl_MD",
                "Comment": "Name (with no ext) of the tpr FILE used for the production MD and compute BE"},
    'trjNAME': {"Value": "traj_MD", "Array": "no",
                "Default": "traj_MD",
                "Comment": "Name (with no ext) of the xtc FILE from production MD and used to compute BE"},
    'topName': {"Value": "topol", "Array": "no",
                "Default": "topol",
                "Comment": "Name (with no ext) of the top FILE"},
    'receptorFRAG': {"Value": "1", "Array": "no",
                     "Default": "1",
                     "Comment": "Number of Fragment in the receptor (FIRST molecule in the starting pdb file)"},
    'ABchains': {"Value": "2", "Array": "no",
                 "Default": "2",
                 "Comment": "Number of Fragment in the antibody (SECOND molecule in the starting pdb file)"},
    'mergeFragments': {"Value": "", "Array": "no",
                       "Default": "",
                       "Comment": "Use the merge interactive to make topology of the protein." +
                                  "If set to -merge, the mergeC, mergeR and mergeL need to be set accordingly."},
    'mergeC': {"Value": "", "Array": "no",
               "Default": "",
               "Comment": r"Merge string for Receptor only (Cx: r'y\nn\ny\nn\ny\nn\ny\nn\ny\nn\ny\n')."},
    'mergeR': {"Value": "", "Array": "no",
               "Default": "",
               "Comment": r"Merge string for Receptor only (Cx: r'y\nn\ny\nn\ny\nn\ny\nn\ny\nn\ny\n')."},
    'mergeL': {"Value": "", "Array": "no",
               "Default": "",
               "Comment": r"Merge string for Ligand (antibody) only."},
    'EnergyFunction': {"Value": "3 12", "Array": "no",
                       "Default": "3 12",
                       "Comment": "List of the Energy function that will be printed in output. " +
                                  "The last one will be used by Metropolis. " +
                                  "3: dG | 8: ScoreF | 9:ScoreF2 | 10: CanonicalAVG | 11: Median | 12: dG_2sigma"},
    'average_all_frames': {"Value": "False", "Array": "no",
                           "Default": "False",
                           "Comment": "False-> the final energy is computed as average of the single cycles." +
                                      "True -> all the single energies are used to compute the final value."},
    'FAST': {"Value": "False", "Array": "no",
             "Default": "False",
             "Comment": "If the program will run a fast test or not."},
    'VERBOSE': {"Value": "False", "Array": "no",
                "Default": "False",
                "Comment": "If the program will be talkative or not."},
    'EnergyCalculation': {"Value": "gmxMMPBSA", "Array": "no",
                          "Default": "gmxMMPBSA",
                          "Comment": "Method used to compute the BE. OPTs: GMXPBSA(old), Jmmpbsa, gmxMMPBSA"},
    'GMXPBSApath': {"Value": "${ProgramPATH}/gmxpbsa-master", "Array": "no",
                    "Default": "${ProgramPATH}/gmxpbsa-master",
                    "Comment": "gmxpbsa program inside ABISS folder (PPATH). DO NOT CHANGE"},
    'CPATH': {"Value": "/usr/bin", "Array": "no",
              "Default": "/usr/bin",
              "Comment": "(NEVER USED) path to the 'Coulomb' program"},
    'APATH': {"Value": "findPATH", "Array": "no",
              "Default": "findPATH",
              "Comment": "Path to the 'APBS' program"},
    'GPATH': {"Value": "/home/iqb/anaconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/bin", "Array": "no",
              "Default": "/home/iqb/anaconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/bin",
              "Comment": "Path to the 'Gromacs4.6.7' program"},
    'linearizedPB': {"Value": "-l", "Array": "no",
                     "Default": "-l",
                     "Comment": "Used with GMXPBSA. '-l' to use APBS with linearize PB"},
    'precF': {"Value": "0", "Array": "no",
              "Default": "0",
              "Comment": "Used with GMXPBSA."},
    'pdie': {"Value": "2", "Array": "no",
             "Default": "2",
             "Comment": "Used with GMXPBSA."},
    'GMXPBSAminim': {"Value": "n", "Array": "no",
                     "Default": "n",
                     "Comment": "Used with GMXPBSA. 'y' if you want to run minim before BE calculations"},
    'GMXPBSA_use_tpbcon': {"Value": "", "Array": "no",
                           "Default": "",
                           "Comment": "Used with GMXPBSA. (e.g. -utc)"},
    'GMXPBSA_NO_topol_ff': {"Value": "", "Array": "no",
                            "Default": "",
                            "Comment": "Used with GMXPBSA. (e.g. -noTF)"},
    'JerkwinPROGRAM': {"Value": "${ABiSS_LIB}/Jerkwin_mmpbsa.bsh", "Array": "no",
                       "Default": "${ABiSS_LIB}/Jerkwin_mmpbsa.bsh",
                       "Comment": "Jerkwin program inside ABISS folder (PPATH). DO NOT CHANGE"},
    'trjconvOPT': {"Value": "-skip 100", "Array": "no",
                   "Default": "-skip 100",
                   "Comment": "Used with Jerkwin. To set the option of trjconv."},
    'GsourcePATH': {"Value": "/usr/local/gromacs/bin/GMXRC", "Array": "no",
                    "Default": "/usr/local/gromacs/bin/GMXRC",
                    "Comment": "Used with Jerkwin. Path to gromacs"},
    'mmpbsa_inFILE': {"Value": "mmpbsa_noLinearPB_amber99SB_ILDN.in", "Array": "no",
                      "Default": "mmpbsa_noLinearPB_amber99SB_ILDN.in",
                      "Comment": "Used with gmxMMPBSA. Pre-built input file to use."},
    'use_decomp_as_weights': {"Value": "False", "Array": "no",
                              "Default": "False",
                              "Comment": "Set to True to select the residue to mutate using weight probability."
                                         "The weights are derived from energy decomposition. (Must use MMGBSA_decomp)"},
    'resid_be_decomp_files': {"Value": "None", "Array": "no",
                              "Default": "None",
                              "Comment": "Name with path of the files with the per-residue binding energy decomposition"},
    'startingFrameGMXPBSA': {"Value": "500", "Array": "no",
                             "Default": "500",
                             "Comment": "Time of first frame to read {ps} when the xtc is prepared to compute BE " +
                                        "(Default: 500ps)"},
    'NUMframe': {"Value": "all", "Array": "no",
                 "Default": "all",
                 "Comment": "Number of frames (starting from the last) on which the energy will be averaged " +
                            "(default: all) -almost computational costless-"},
    'RunningNum_PerSystem': {"Value": "10", "Array": "no",
                             "Default": "10",
                             "Comment": "Number of cycle per system. e.g. '1' will run only one time every "
                                        "configuration"},
    'Restart_calculations': {"Value": "no", "Array": "no",
                             "Default": "no",
                             "Comment": "'yes' if the program have to restart a previous calculations"},
    'reuse_MD': {"Value": "False", "Array": "no",
                 "Default": "False",
                 "Comment": "Set to True if you want to use previously computed trajectories. "
                            "You must set the reuse_MD_PATH variable."},
    'reuse_MD_PATH': {"Value": "", "Array": "no",
                      "Default": "",
                      "Comment": "Set to the path where the $cycle_number_MD_FOLDER of the previous MD can be found"},
    'reuse_MD_abiss_settings': {"Value": "", "Array": "no",
                                "Default": "",
                                "Comment": "Set to the path where the abiss_settings of the previous run is."},
    'MaxMutant': {"Value": "100", "Array": "no",
                  "Default": "100",
                  "Comment": "Max number of mutation that will be attempted during the maturation"},
    'ForceField': {"Value": "6", "Array": "no",
                   "Default": "6",
                   "Comment": "Which ForceField to use for the MD and energy calculations"},
    'POSRES_RESIDUES': {"Value": "", "Array": "no",
                        "Default": "",
                        "Comment": "Residues that will be restraint during MD. Generally used with Cx"},
    'ResiduePool_list': {"Value": "ALA ARG ASN ASP GLN GLU ILE LYS PHE PRO SER THR VAL TRP TYR LEU MET", "Array": "no",
                         "Default": "ALA ARG ASN ASP GLN GLU ILE LYS PHE PRO SER THR VAL TRP TYR LEU MET",
                         "Comment": "Pool of residues from witch choose for the mutation."},
    'TargetResidueList': {"Value": "100:H 101:H 102:H 103:H", "Array": "no",
                          "Default": "100:H 101:H 102:H 103:H",
                          "Comment": "List of the antibody RESIDUE:CHAIN that are allowed to be mutated"},
    'editconf_opt': {"Value": "-d 1.2 -bt triclinic -c", "Array": "no",
                     "Default": "-d 1.2 -bt triclinic -c",
                     "Comment": "Option of editconf to be used when building the systems" +
                                "NOTE that the long range interactions cut-off is set at 1.2nm"},
    'editconf_opt2': {"Value": "", "Array": "no",
                      "Default": "",
                      "Comment": "Option for a possible 2nd editconf "},
    'editconf_opt3': {"Value": "", "Array": "no",
                      "Default": "",
                      "Comment": "Option for a possible 3rd editconf"},
    'POSRES': {"Value": "_posres", "Array": "no",
               "Default": "_posres",
               "Comment": "If position restraint will be used or not"},
    'KEY_pcoupl': {"Value": "Parrinello-Rahman", "Array": "no",
                   "Default": "Parrinello-Rahman",
                   "Comment": "Pressure Coupling keyword to use during simulations"},
    'KEY_annealing': {"Value": "single", "Array": "no",
                      "Default": "single",
                      "Comment": "Simulated annealing keyword to use during simulations"},
    'KEY_SA_npoints': {"Value": "4", "Array": "no",
                       "Default": "4",
                       "Comment": "Number of points in the Simulated annealing simulations"},
    'KEY_SA_temp': {"Value": "310 380 380 310", "Array": "no",
                    "Default": "310 380 380 310",
                    "Comment": "Temperatures in the Simulated annealing simulations"},
    'KEY_SA_time': {"Value": "0 100 150 250", "Array": "no",
                    "Default": "0 100 150 250",
                    "Comment": "Time steps during the Simulated annealing simulations"},
    # KEYs for number of steps
    'KEY_nsteps_minim': {"Value": 50000, "Array": "no",
                         "Default": "50000",
                         "Comment": ""},
    'KEY_nsteps_SAMD': {"Value": int((250 * 1000 + 100000) / 2), "Array": "no",
                        "Default": "(int) (250 * 1000 + 100000)/2",
                        "Comment": ""},
    'KEY_nsteps_NVT': {"Value": 50000, "Array": "no",
                       "Default": "50000",
                       "Comment": ""},
    'KEY_nsteps_NPT': {"Value": 50000, "Array": "no",
                       "Default": "50000",
                       "Comment": ""},
    'KEY_nsteps_MD': {"Value": 750000, "Array": "no",
                      "Default": "750000",
                      "Comment": ""},
    # KEY for center of mass motion removal
    'KEY_commmode': {"Value": 'none', "Array": "no",
                     "Default": "none",
                     "Comment": "Removing the Center of Mass Motion in combination with PosRes may lead to artifacts"},
    # KEYs for how often to save the data during the simulations
    'KEY_nstouts_SAMD': {"Value": int((250 * 1000 + 100000) / 2 / 50), "Array": "no",
                         "Default": "(int) (250 * 1000 + 100000) / 2 / 50",
                         "Comment": ""},  # nstouts for SAMD
    'KEY_nstouts_NVT': {"Value": int(50000 / 10), "Array": "no",
                        "Default": "(int) 50000 / 10",
                        "Comment": ""},  # nstouts for NVT
    'KEY_nstouts_NPT': {"Value": int(75000 / 10), "Array": "no",
                        "Default": "(int) 75000 / 10",
                        "Comment": ""},  # nstouts for NPT
    'KEY_nstouts_MD': {"Value": int(20000), "Array": "no",
                       "Default": "(int) 20000",
                       "Comment": ""},  # 40ps nstouts for MD production -> with 1.5ns I have tot 38 frames
    'KEY_compressed': {"Value": "nstxtcout", "Array": "no",
                       "Default": "nstxtcout",
                       "Comment": ""},
    'KEY_define_SAMD': {"Value": "-DPOSRES_abiss", "Array": "no",
                        "Default": "-DPOSRES_abiss or -DPOSRES_BB",
                        "Comment": "Set it to KEY_ to not use it"},
    'KEY_define_MD': {"Value": "-DPOSRES_abiss", "Array": "no",
                      "Default": "-DPOSRES_abiss",
                      "Comment": "Set it to KEY_ to not use it"},
    'keep_hydration': {"Value": "", "Array": "no",
                       "Default": "",
                       "Comment": "Use a different method to select the new residue type (Carol K. paper)"},
    'cluster': {"Value": "no", "Array": "no",
                "Default": "no",
                "Comment": "This option will activate the 'cluster' starting variables"},
    'NP_value': {"Value": "4", "Array": "no",
                 "Default": "4",
                 "Comment": "Number of OpenMP threads per MPI rank to start (-ntomp option on gmx mdrun)"},
    'CONDA_activate_path': {"Value": "/home/iqb/anaconda3/bin/", "Array": "no",
                            "Default": "/home/iqb/anaconda3/bin/",
                            "Comment": "Path to the conda 'activate' program"},
    'CONDA_gmxmmpbsa_name': {"Value": "gmxMMPBSA-1.6.1", "Array": "no",
                             "Default": "gmxMMPBSA-1.6.1",
                             "Comment": "Name of the conda environment for gmxMMPBSA"},
    'source_GMX': {"Value": "", "Array": "no",
                   "Default": "",
                   "Comment": "PATH to the gromacs GMXRC that you want to use."},
    'CONDA_modeller_name': {"Value": "modeller", "Array": "no",
                            "Default": "modeller",
                            "Comment": "Name of the conda environment for modeller"},
    'CUDA_visible_devices': {"Value": "0", "Array": "no",
                             "Default": "0",
                             "Comment": "Name of the CUDA devices that can be used."},
    'metropolis_correction': {"Value": "True", "Array": "no",
                              "Default": "True",
                              "Comment": "True-> Take into account the STD of results for the Metropolis algorithm"},
    'Metropolis_Temp': {"Value": "2", "Array": "no",
                        "Default": "2",
                        "Comment": "Metropolis Temperature"},
    'Metropolis_Temp_cap': {"Value": "4", "Array": "no",
                            "Default": "4",
                            "Comment": "Metropolis Temperature top limit"},
    # --------------------------------------------------------------------------------------------------------------
    # DYNAMIC PARAMETERS
    'Eff_Metropolis_Temp': {"Value": "", "Array": "no",
                            "Default": "",
                            "Comment": "Metropolis Temperature Used during the calculations. It could change."},
    'Consecutive_DISCARD_Count': {"Value": "0", "Array": "no",
                                  "Default": "0",
                                  "Comment": "Number of consecutive discarded results."},
    'complex_FILE': {"Value": "", "Array": "no",
                     "Default": "",
                     "Comment": "Name of the configuration in use."},
    'complex_EXT': {"Value": "", "Array": "no",
                    "Default": "",
                    "Comment": "Extension of the configuration in use."},
    'Stored_system_FILE': {"Value": "", "Array": "no",
                           "Default": "",
                           "Comment": "Name of the last configuration accepted."},
    'SEQUENCE': {"Value": "", "Array": "no",
                 "Default": "",
                 "Comment": "Current configuration number."},
    'PN': {"Value": "", "Array": "no",
           "Default": "",
           "Comment": "Program name. Retrieve at the beginning of the program."},
    'ProgramPATH': {"Value": "", "Array": "no",
                    "Default": "",
                    "Comment": "Program PATH. Retrieve at the beginning of the program."},
    'STARTING_FOLDER': {"Value": "", "Array": "no",
                        "Default": "",
                        "Comment": "Starting folder. Retrieve at the beginning of the program."},
    'ABiSS_LIB': {"Value": "", "Array": "no",
                  "Default": "",
                  "Comment": "PATH to ABiSS_lib folder. Retrieve at the beginning of the program."},
    'FUNCTIONs_FOLDER': {"Value": "", "Array": "no",
                         "Default": "",
                         "Comment": "PATH to FUNCTIONs_FOLDER folder. Retrieve at the beginning of the program."},
    'MDPs_FOLDER': {"Value": "", "Array": "no",
                    "Default": "",
                    "Comment": "PATH to MDPs_FOLDER folder. Retrieve at the beginning of the program."},
    'VER': {"Value": "", "Array": "no",
            "Default": "",
            "Comment": "Version of the Program. Retrieve at the beginning of the program."},
    'Make_new_mutation': {"Value": "False", "Array": "no",
                          "Default": "False",
                          "Comment": "Used to determine if you do a new mutation or not."},
    'AcceptProb': {"Value": "", "Array": "no",
                   "Default": "",
                   "Comment": "Could be used instead of the Random number to have a fixed acceptance probability."},
    'Starting_Configuration': {"Value": "0", "Array": "no",
                               "Default": "0",
                               "Comment": "Configuration from witch to start (or restart). 0->WT"},
    'Stored_AVG': {"Value": "no", "Array": "no",
                   "Default": "no",
                   "Comment": "Stored Average BE from the last configuration."},
    'Stored_STD': {"Value": "no", "Array": "no",
                   "Default": "no",
                   "Comment": "Stored BE standard deviation from the last configuration."},
    'RUN_FOLDER': {"Value": "", "Array": "no",
                   "Default": "",
                   "Comment": ""},
    'LOGFILENAME': {"Value": "", "Array": "no",
                    "Default": "",
                    "Comment": ""},
    'CONFOUT_FILENAME': {"Value": "", "Array": "no",
                         "Default": "",
                         "Comment": ""},
    'SETUP_PROGRAM_FOLDER': {"Value": "", "Array": "no",
                             "Default": "",
                             "Comment": ""},
    'DOUBLE_CHECK_FOLDER': {"Value": "", "Array": "no",
                            "Default": "",
                            "Comment": ""},
    'SELFAVOIDING_FILENAME': {"Value": "", "Array": "no",
                              "Default": "",
                              "Comment": ""},
    'current_conf_PATH': {"Value": "", "Array": "no",
                          "Default": "",
                          "Comment": ""},
    # PROGRAMS names with paths and starting options
    'GROMPP': {"Value": "", "Array": "no",
               "Default": "",
               "Comment": ""},
    'MDRUN': {"Value": "", "Array": "no",
              "Default": "",
              "Comment": ""},
    'MDRUN_md': {"Value": "", "Array": "no",
                 "Default": "",
                 "Comment": ""},
    'PDB2GMX': {"Value": "", "Array": "no",
                "Default": "",
                "Comment": ""},
    'EDITCONF': {"Value": "", "Array": "no",
                 "Default": "",
                 "Comment": ""},
    'GENBOX': {"Value": "", "Array": "no",
               "Default": "",
               "Comment": ""},
    'GENION': {"Value": "", "Array": "no",
               "Default": "",
               "Comment": "S"},
    'MAKE_NDX': {"Value": "", "Array": "no",
                 "Default": "",
                 "Comment": ""},
    'TRJCONV': {"Value": "", "Array": "no",
                "Default": "",
                "Comment": ""},
    'GENRESTR': {"Value": "", "Array": "no",
                 "Default": "",
                 "Comment": ""},
    'CHECK': {"Value": "", "Array": "no",
              "Default": "",
              "Comment": ""},
    'ENERGY': {"Value": "", "Array": "no",
               "Default": "",
               "Comment": ""},
    'RMS': {"Value": "", "Array": "no",
            "Default": "",
            "Comment": ""},
    'GROMACSver': {"Value": "", "Array": "no",
                   "Default": "",
                   "Comment": ""},
    'PYTHON': {"Value": "", "Array": "no",
               "Default": "",
               "Comment": ""},
    'AWK': {"Value": "", "Array": "no",
            "Default": "",
            "Comment": ""},
    'VMD': {"Value": "", "Array": "no",
            "Default": "",
            "Comment": ""},
    'CHIMERA': {"Value": "", "Array": "no",
                "Default": "",
                "Comment": ""},
    # MDPs_FOLDER names with path
    'minim_NAME': {"Value": "", "Array": "no",
                   "Default": "",
                   "Comment": ""},
    'SAMD_NAME': {"Value": "", "Array": "no",
                  "Default": "",
                  "Comment": ""},
    'NVT_NAME': {"Value": "", "Array": "no",
                 "Default": "",
                 "Comment": ""},
    'NPT_NAME': {"Value": "", "Array": "no",
                 "Default": "",
                 "Comment": ""},
    'MD_EngComp_ff14sb_NAME': {"Value": "", "Array": "no",
                               "Default": "",
                               "Comment": ""},
    'Protein_MD_EngComp_ff14sb_NAME': {"Value": "", "Array": "no",
                                       "Default": "",
                                       "Comment": ""},

}


def read_input_file(input_file, verbose):
    if verbose:
        print("\tload_input_file.py: Reading input file and updating the variable dict.. ")
    with open(input_file, 'r') as f:
        for line in f:
            # ignore comment lines
            if line.startswith('#') or not line.strip():
                continue

            # Parse keywords and value from line
            parts = line.strip().split('=')
            if len(parts) != 2:
                raise ValueError("Invalid line in input file: {}".format(line))

            keyword = parts[0].strip()
            value = parts[1].strip().strip("\"").strip("(").strip(")")

            # if verbose:
            #    print("keyword:" + str(keyword) + " value:" + str(value))
            # Update the keyword dictionary
            if keyword in keywords_variable_dict:
                keywords_variable_dict[keyword]["Value"] = str(value)
            else:
                raise ValueError("Unknown keyword in the input file: {}".format(keyword))


def print_shell_file(input_output_file):
    with open(input_output_file, 'w') as f:
        for keyword, values in keywords_variable_dict.items():
            # Write the description first (as a comment)
            f.write("#" + str(values["Comment"]) + " - Default: " + str(values["Default"]) + "\n")
            if values["Array"] == "no":
                f.write(r'{0:s}="{1}"'.format(str(keyword), values["Value"]) + "\n\n")
                # print("kewyword:" + str(keyword) + " value:" + str(value))
            if values["Array"] == "yes":
                f.write(r'{0:s}=({1})'.format(str(keyword), values["Value"]) + "\n\n")


def run_variable_dict_check(input_output_file):
    read_input_file(input_output_file, False)
    for keyword, values in keywords_variable_dict.items():
        if not values["Value"]:
            print("WARING: \tThe variable {0:s} is not assigned!! (Value: '{1:s}' Default: '{2:s}')".format(
                keyword, values["Value"], values["Default"]))


def update_sh(input_output_file, updated_keys_values, dictionary=None, verbose=False):
    if dictionary is None:
        dictionary = keywords_variable_dict
    # if verbose:
    #     print("\tUpdating values.. \n" + str(updated_keys_values))

    # Update the dictionary with the file first
    read_input_file(input_output_file, verbose)

    # collect the values and keys that needs to be updated
    for item in updated_keys_values:
        parts = item.strip().split('=')
        keyword = parts[0].strip().strip("\"")
        value = parts[1].strip().strip("\"")
        if keyword in dictionary:
            if not value:
                if verbose:
                    print("load_input_file.py: \tSkip item with no value-> \t%-30s\tDic_Value:%-12s\tDic_Default:%-12s"
                          % (str(item), str(dictionary[keyword]["Value"]), str(dictionary[keyword]["Default"])))
                continue
            # if verbose:
            #     if value != dictionary[keyword]["Value"]:
            #         print("\t" + str(keyword) + ": " + str(dictionary[keyword]["Value"]) + " -> " + str(value))
            dictionary[keyword]["Value"] = value
        else:
            raise ValueError("Unknown keyword in the input file: {}".format(keyword))

    # Print the file again with the updated values
    print_shell_file(input_output_file)


def read_keyword_from_file(input_file, in_key_word):
    with open(input_file, 'r') as f:
        for line in f:
            # ignore comment lines
            if line.startswith('#') or not line.strip():
                continue

            # Parse keywords and value from line
            parts = line.strip().split('=')
            if len(parts) != 2:
                raise ValueError("Invalid line in input file: {}".format(line))

            keyword = parts[0].strip()
            value = parts[1].strip().strip("\"")

            # if verbose:
            #     print("keyword:" + str(keyword) + " value:" + str(value))
            # Update the keyword dictionary
            if keyword == in_key_word:
                print(value)
                break


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Load input file and print them in a bash format')
    parser.add_argument('-i', '--input_file', type=str, default="INPUT.in",
                        help='Input file name (Default: INPUT.in)')
    parser.add_argument('-o', '--output_name', type=str, default="abiss_settings.sh",
                        help='Name of the excel output file (Default: abiss_settings.sh)')
    parser.add_argument('-u', '--update', type=str, nargs='+',
                        help='Update the variable in the output file with values given by the user.' +
                             'input format must be "KEY_WORD=VALUE KEY_WORD2=VALUE2 [...]" ')
    parser.add_argument('-c', '--check', action='store_true',
                        help='Run a check of the variable dictionary.')
    parser.add_argument('-k', '--in_key_word', type=str, default=False,
                        help='Use this option if you want to extract a specific keyword value from the input file')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    args = parser.parse_args()
    # list of KEY_WORD=VALUE
    update = args.update
    check = args.check
    in_key_word = args.in_key_word

    # assert check if the first argument is True and execute the second argument if it is False
    # isfile check if the argument is a file and access check that is readable
    assert isfile(args.input_file) and access(args.input_file, R_OK), \
        ValueError("You must provide a readable input file! input file:'{}'".format(args.input_file))
    if check:
        run_variable_dict_check(input_output_file=args.input_file)
        exit()
    if update is not None:
        # print(update)
        update_sh(input_output_file=args.input_file, updated_keys_values=update, verbose=args.verbose)
        exit()
    if in_key_word:
        # print(in_key_word)
        read_keyword_from_file(input_file=args.input_file, in_key_word=in_key_word)
        exit()
    read_input_file(input_file=args.input_file, verbose=args.verbose)
    print_shell_file(input_output_file=args.output_name)

    # while True:
    #     with open("inpipe") as f:
    #         try:
    #             print(exec(f.read()))
    #         except Exception as e:
    #             print(e)
