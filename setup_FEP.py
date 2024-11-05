#!/bin/python3

# This program is used in the corresponding .sh script
#  - It makes all the necessary folders (FEP_folder, Forward'/'Reverse);
#  - reads the conf_RUN*.dat fine, 
#  - detect the mutations for a specific mutant-configuration, 
#  - write the pmx mutation file (mutations_For.txt, mutations_Rev.txt).
# e.g.
# python ${ABiSS_folder}/setup_FEP.py -i "${INPUT_CONF_RUN}" -m "${MUTATION}" -d "${COMPUTER}RUN${RUN}_M${MUTATION}"

import argparse
import os
import shutil
import glob
import sys

# import matplotlib.pyplot as plt
# import matplotlib.ticker as ticker
# import numpy as np

aa_notation_pmx_3to1 = {
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
    "HIS": "X"
}


def read_confout(input_file):
    # reads the conf_RUN1.out file and gives a list of row as output
    print("reading " + input_file + "..")
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
    print("len(rows[-1]): " + str(len(rows[-1])))
    try:
        print("len(rows[2]): " + str(len(rows[2])))
        while len(rows[-1]) < len(rows[2]):
            print("Last Mutation wasn't completed.. ")
            print("delete: " + str(rows[-1]))
            del rows[-1]
            print("new last row: " + str(rows[-1]))
    except:
        print("Probably only WT..")

    return rows


def print_pmx_mut(input_file, mutation_num, output_file):
    rows = read_confout(input_file)
    first_row_len = len(rows[0])
    # second_row_len = len(rows[1])
    system_name = [item[0] for item in rows]
    del system_name[0]
    last_accepted_row = 1
    for row_index, row in enumerate(rows):
        if row_index < 2: continue
        if row[0] != "M" + mutation_num: continue
        for column_index, value in enumerate(row):
            if column_index == 0 or column_index >= first_row_len: continue
            if row_index >= 2 and value != rows[1][column_index]:
                # print(str(rows[1][column_index]) + '\t' + rows[0][column_index] + '\t' + str(value))
                # system_name[row_index - 1] = rows[1][column_index] + rows[0][column_index][:-2] + value \
                #                             + "(" + rows[0][column_index][-1:] + ") " + system_name[row_index - 1]
                # H 28 S
                resid_chain = rows[0][column_index].split(':')
                if len(resid_chain) == 1:
                    resid_chain.append('H')
                print(resid_chain, rows[1][column_index] + " to " + value)

                FEP_mutation = str(resid_chain[1]) + " " + str(resid_chain[0]) + " " + aa_notation_pmx_3to1[value]
                with open(output_file + "_For.txt", 'a') as f:
                    print(FEP_mutation, file=f)

                FEP_mutation = str(resid_chain[1]) + " " + str(resid_chain[0]) + " " + \
                               aa_notation_pmx_3to1[rows[1][column_index]]
                with open(output_file + "_Rev.txt", 'a') as f:
                    print(FEP_mutation, file=f)


def make_folders_and_copy_files(folder_name, file_name):
    '''
    Makes the FEP folders: 'folder_name', 'Forward'/'Reverse'
    and copy all the files in 'file_name' inside 'folder_name'
    '''
    if not os.path.exists(folder_name):
        os.makedirs(folder_name)
    forward_folder = os.path.join(folder_name, 'Forward')
    reverse_folder = os.path.join(folder_name, 'Reverse')
    if not os.path.exists(forward_folder):
        os.makedirs(forward_folder)
    if not os.path.exists(reverse_folder):
        os.makedirs(reverse_folder)
    for file in file_name:
        shutil.copy(file, folder_name)


def find_pdb_file_name(path, pattern):
    pdb_file_patter = os.path.join(path, pattern)
    pdb_file = glob.glob(pdb_file_patter)
    if len(pdb_file) != 1:
        print(f"setup_FEP.py: Something wrong with the pdb file search.. '{pdb_file}' -> Could not find anything with {pdb_file_patter} \nexit")
        sys.exit(2)
    return pdb_file[0]


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Data analysis for ABiSS program')
    parser.add_argument('-i', '--input_file', type=str, default="conf_RUN1.out",
                        help='Input file name with residues list and BE (Default: conf_RUN1.out)')
    parser.add_argument('-o', '--output_name', type=str, default="mutations",
                        help='Name of the output file for pmx (Default: mutations)')
    parser.add_argument('-m', '--mutation_num', type=str, default="1",
                        help='Number of the mutation that have to be analysed. '
                             'It will identify the mutant e.g. M1 (Default: 1)')
    parser.add_argument('-d', '--destination_folder', type=str, default=None,
                        help='Name of the folder used to make the FEP. '
                             'If not specified it will be in the format hzRUN?_M??')
    parser.add_argument('-f', '--forward_pdb', type=str, default="HLA_BiAB_beforeMD.pdb",
                        help='PDB file that will be used for the forward simulation (Default: HLA_BiAB_beforeMD.pdb)')
    parser.add_argument('-r', '--reverse_pdb', type=str, default=None,
                        help='PDB file that will be used for the reverse simulation '
                             '(Default: Mutant+mt_num+_cycle*.pdb)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    args = parser.parse_args()

    # VERBOSE NOT IMPLEMENTED YET
    verbose = args.verbose
    input_file_with_path = os.path.realpath(args.input_file)
    [input_path, input_name] = os.path.split(input_file_with_path)
    if (not os.path.exists(input_file_with_path)) or (args.input_file == ""):
        print(f"setup_FEP.py: Something wrong with the input file.. {input_file_with_path} \nexit")
        sys.exit(1)
    print(f" input_file: {args.input_file}\n input_file_with_path: {input_file_with_path}\n input_path: {input_path}\n ")
    
    destination_folder = args.destination_folder
    if args.destination_folder is None:
        destination_folder = 'hz'+input_file_with_path.split('/')[-3]+"_M"+str(args.mutation_num)
    
    forward_pdb_pattern = args.forward_pdb
    forward_pdb = find_pdb_file_name(input_path, forward_pdb_pattern)
    
    reverse_pdb_pattern = args.reverse_pdb
    if args.reverse_pdb is None:
        reverse_pdb_pattern = "*Mutant" + str(args.mutation_num) + "_cycle*.pdb"
    reverse_pdb = find_pdb_file_name(input_path, reverse_pdb_pattern)

    print(f" destination_folder: {destination_folder}\n forward_pdb_file: {forward_pdb}\n "
          f"reverse_pdb_file: {reverse_pdb}\n\n")

    make_folders_and_copy_files(folder_name=destination_folder, file_name=[forward_pdb, reverse_pdb])
    os.chdir(destination_folder)

    # if args.input_file_list:
    #     load_molecules_results(input_file_list=args.input_file_list)
    #     exit()
    print_pmx_mut(input_file=input_file_with_path, mutation_num=args.mutation_num, output_file=args.output_name)
    shutil.copy(args.output_name + "_For.txt", 'Forward')
    shutil.copy(forward_pdb, 'Forward')
    shutil.copy(args.output_name + "_Rev.txt", 'Reverse')
    shutil.copy(reverse_pdb, 'Reverse')
    
    
    
    
    
