#!/bin/python3
# The program has been made to analyze the data of ABiSS program.
# It returns a plot of the BE with STD for every mutation (black WT, blue accepted, red declined)
# Use it inside the RUN folder
# Use conda activate gmxMMPBSA
# e.g. python collect_json_csv.py -i conf_RUN1.out -l Config0/RESULTS/MoleculesResults.dat Mutant?/RESULTS/MoleculesResults.dat  Mutant??/RESULTS/MoleculesResults.dat -u "KCal/mol"
import argparse

import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np
import pandas as pd
import os
import glob
import json

aa_notation_3to1 = {
    "GLY": "G",
    "ALA": "A",
    "VAL": "V",
    "LEU": "L",
    "ILE": "I",
    "MET": "M",
    "PHE": "F",
    "TRP": "W",
    "PRO": "P",

    "SER": "S",
    "THR": "T",
    "CYS": "C",
    "TYR": "Y",
    "ASN": "N",
    "GLN": "Q",

    "ASP": "D",
    "GLU": "E",

    "LYS": "K",
    "ARG": "R",
    "HIS": "H"
}


def load_molecules_results(input_file_list, convertion, energy_ndx=1):
    # Open the 'Config0/RESULTS/MoleculesResults.dat' data file and read the data as a list of row. Compute avg and std
    print(f"=> load_molecules_results from {input_file_list}")
    average_list = []
    std_list = []
    first_file_length = 0
    conv_coeff = 1
    if convertion:
        conv_coeff = 0.24
    for input_file in input_file_list:
        with open(input_file) as f:
            rows = [line.split() for line in f]
        if not first_file_length:
            first_file_length = len(rows)
            print("\tfirst_file_length=" + str(first_file_length))
        if len(rows) != first_file_length:
            print("\t" + input_file + " (rows=" + str(len(rows)) + "): NOT FINISHED")
            continue
        binding_eng = [float(item[energy_ndx]) for item in rows[1:]]
        # create a numpy array
        binding_eng_array = np.array(binding_eng)
        average = np.mean(binding_eng_array)
        average = np.round(average, 1)
        std = np.std(binding_eng_array)
        std = np.round(std, 1)
        average_list.append(average * conv_coeff)
        std_list.append(std * conv_coeff)
        # print("\t"+input_file + ": " + str(binding_eng))
        print("\t" + input_file + ": " + str(average) + " +/- " + str(std))
    return [average_list, std_list]


def read_confout_file(input_file):
    print("=> read_confout_file.. ")
    # Open the data file and read the data into a list of row
    with open(input_file) as f:
        rows = [line.split() for line in f if len(line.strip()) > 0]

    # There is an error on old file that cause the dy to be in the same column with kj/mol.
    # I am going to strip kj/mol from every value. Similarly for "(" and ")"
    # I also fix the error that makes a new column with ")" from the second row on
    for line in rows:
        while line.count(')'):
            line.remove(')')
        for ndx, value in enumerate(line):
            if "kJ/mol" in value:
                line[ndx] = value.replace("kJ/mol", "")
                value = line[ndx]
            if "(" in value:
                line[ndx] = value.replace("(", "")
                value = line[ndx]
            if ")" in value:
                line[ndx] = value.replace(")", "")
            # if ndx == first_row_len or ndx == first_row_len + 2:
            #     line[ndx] = float(value)

    # Delete the last row if it is incomplete
    print("\tlen(rows[-1]): " + str(len(rows[-1])))
    try:
        print("\tlen(rows[2]): " + str(len(rows[2])))
        print("\tlen(rows): " + str(len(rows)))
        if len(rows) == 3:
            print("\tThe simulation STOPPED at mutant1.. skipping this simulation")
            del rows[-1]
            return rows
        while len(rows[-1]) < len(rows[2]):
            print("\tLast Mutation wasn't completed.. ")
            print("\tdelete: " + str(rows[-1]))
            del rows[-1]
            print("\tnew last row: " + str(rows[-1]))
    except:
        print("\tProbably only WT..")

    return rows


def print_json_and_csv(confout_input_file_rows, output_file_name, convertion, run_number,
                       binding_eng_2, std_binding_eng_2):
    print(f'=> print_json_and_csv..')
    first_row_len = len(confout_input_file_rows[0])
    conv_coeff = 1
    if convertion:
        conv_coeff = 0.24
    # system_name -> WT, M1, M2, ...
    system_name = [item[0] for item in confout_input_file_rows[1:]]
    # system_sequence -> [MET, MET, TRP ...], [...]
    system_sequence = [item[1:first_row_len] for item in confout_input_file_rows[1:]]
    binding_eng = [float(item[first_row_len]) * conv_coeff for item in confout_input_file_rows[1:]]
    delta_binding_eng = [float(item[first_row_len]) * conv_coeff - float(confout_input_file_rows[1][first_row_len])
                         for item in confout_input_file_rows[1:]]
    std_binding_eng = [float(item[first_row_len + 2]) * conv_coeff for item in confout_input_file_rows[1:]]
    delta_binding_eng2 = np.round([item - binding_eng_2[0] for item in binding_eng_2], 1)
    delta_binding_eng2 = np.round(delta_binding_eng2, 1)

    print(f'\tfirst line example for RUN{run_number}:\n\t\t{system_name[0]} '
          f'{system_sequence[0]} {binding_eng[0]} {std_binding_eng[0]} {delta_binding_eng[0]} {delta_binding_eng2[0]}')
    # Make a dictionary with the sequences sampled during the run

    run_dic = {f'RUN{run_number}': []}
    run_list = []
    # for name, seq, BE, STD in zip(system_name, system_sequence, binding_eng, std_binding_eng):
    for name, seq, condBE, confSTD, confDBE, BE, STD, DBE in zip(system_name, system_sequence,
                                                                 binding_eng, std_binding_eng, delta_binding_eng,
                                                                 binding_eng_2, std_binding_eng_2,
                                                                 delta_binding_eng2):
        run_list.append({'run': f'RUN{run_number}', 'mutation': name, 'sequence': seq,
                         'binding_energy': f'{condBE:.2f}', 'std': f'{confSTD:.2f}',
                         'delta_binding_energy': f'{confDBE:.2f}', 'binding_energy_2s': f'{BE:.2f}',
                         'std_2s': f'{STD:.2f}', 'delta_binding_energy_2s': f'{DBE:.2f}'})
        run_dic[f'RUN{run_number}'].append({'mutation': name, 'sequence': seq, 'binding_energy': condBE, 'std': confSTD,
                                            'delta_binding_energy': f'{confDBE:.2f}', 'binding_energy_2s': f'{BE:.2f}',
                                            'std_2s': f'{STD:.2f}', 'delta_binding_energy_2s': f'{DBE:.2f}'})
    with open(output_file_name + ".json", 'w') as json_file:
        json.dump(run_dic, json_file, indent=4)
    with open(output_file_name + "_2.json", 'w') as json_file:
        json.dump(run_list, json_file, indent=4)
    df_run_list = pd.DataFrame(run_list)
    df_run_list.to_csv(output_file_name + ".csv", index=False)  # index=false means do not write rox indexes

    return run_list, run_dic


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Data analysis for ABiSS program')
    parser.add_argument('-f', '--input_folder_list', type=str, nargs='+', default="RUN1",
                        help='List of folder where the conf input file (-i opt) can be found (Default: RUN1)')
    parser.add_argument('-i', '--input_conf_file', type=str, default="conf_RUN?.out",
                        help='Conf input file name with residues list and BE (Default: conf_RUN?.out)')
    parser.add_argument('-l', '--input_BE_file_list', type=str, nargs='+', default=None,
                        help='List of MoleculesResults.dat input file name (Default: None)')
    parser.add_argument('-o', '--output_name', type=str, default=None,
                        help='Name of the excel output file (Default: same as input_conf_file)')
    parser.add_argument('-u', '--be_unit', type=str, default="kJ/mol",
                        help='Unit used to measure the binding energy. It will be used as label (Default: kJ/mol)')
    parser.add_argument('-c', '--convertion', action='store_true', default=False,
                        help='Convert the BE from KJ/mol (old MMPBSA) to KCal/mol. Converting coefficient: 0.24)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    args = parser.parse_args()
    output_name = args.output_name

    base_directory = os.getcwd()
    comulative_list = []
    comulative_dic = []
    input_conf_file_glob = []
    print(f'Folders: {args.input_folder_list}')
    for folder in args.input_folder_list:
        # First construct the full path of the directory
        dir_path = os.path.join(base_directory, folder)
        # Change the working directory
        os.chdir(dir_path)
        # try to identify the RUN number
        current_run_number = folder[3:-5]
        print(f'\n** Processing folder {dir_path}.. (run_number={current_run_number})')

        # VERBOSE NOT IMPLEMENTED YET
        verbose = args.verbose
        # it will search for all the files with the specified name/wild cards and return a LIST
        input_conf_file_glob = glob.glob(args.input_conf_file)
        if len(input_conf_file_glob) == 0:
            raise ValueError(f"Could not fined any {args.input_conf_file} file in {folder}")
        print(f"\t({args.input_conf_file}) input_conf_file_glob: {input_conf_file_glob}")
        if output_name is None:
            output_name = input_conf_file_glob[0][:-4]

        input_BE_file_list_glob = []
        for file in args.input_BE_file_list:
            # print(f"file: {file}->{glob.glob(file)}")
            input_BE_file_list_glob.extend(sorted(glob.glob(file)))
        print(f"\t({args.input_BE_file_list}) input_BE_file_list_glob: {input_BE_file_list_glob}")

        # if args.input_BE_file_list:
        #     load_molecules_results(input_BE_file_list=args.input_BE_file_list)
        #     exit()
        confout_file_rows = read_confout_file(input_conf_file_glob[0])
        if len(confout_file_rows) <= 2:
            print(f'{dir_path}/{input_conf_file_glob[0]} contain only WT.. skipping!')
            continue
        binding_eng2 = []
        std_binding_eng2 = []
        if input_BE_file_list_glob:
            # The average will be slightly different with the conf_RUN values because
            # I am using the 2d filtered data (energy_ndx=10)
            binding_eng2, std_binding_eng2 = load_molecules_results(input_BE_file_list_glob, args.convertion,
                                                                    energy_ndx=10)

        printed_list, print_dic = print_json_and_csv(confout_input_file_rows=confout_file_rows,
                                                     output_file_name=input_conf_file_glob[0][:-4],
                                                     convertion=args.convertion,
                                                     run_number=current_run_number,
                                                     binding_eng_2=binding_eng2,
                                                     std_binding_eng_2=std_binding_eng2)
        comulative_list.extend(printed_list)
        comulative_dic.append(print_dic)

    os.chdir(base_directory)
    with open(output_name + ".json", 'w') as json_f:
        json.dump(comulative_dic, json_f, indent=4)
    with open(output_name + "_2.json", 'w') as json_f:
        json.dump(comulative_list, json_f, indent=4)
    df = pd.DataFrame(comulative_list)
    # Sort the DataFrame by the frequency of the column 'sequence'
    column_of_interest = 'sequence'
    df[f'{column_of_interest}_str'] = df[column_of_interest].apply(lambda x: ', '.join(x))

    frequency = df[f'{column_of_interest}_str'].value_counts()
    df['freq'] = df[f'{column_of_interest}_str'].map(frequency)
    df_sorted = df.sort_values(by=['freq', f'{column_of_interest}_str'], ascending=[False, True])
    # df_sorted.drop('freq', axis=1, inplace=True)
    # Print the DataFrame into a csv file
    df_sorted.to_csv(output_name + ".csv", index=False)  # index=false means do not write rox indexes

    unique_runs = df['run'].nunique()
    unique_sequences = df['sequence_str'].nunique()
    print(f'The final DataFrame contains {unique_runs} runs with {len(comulative_list)} total sequences '
          f'and {unique_sequences} unique sequences')

