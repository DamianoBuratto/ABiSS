import csv
import argparse
from os import access, R_OK
from os.path import isfile


def compute_weights(input_files, resid_chain_list, logfile=None, adhoc_fixing=None, verbose=False):
    residue_dict = {}
    be_contribution_list = []
    if logfile:
        with open(logfile, 'w') as outfile:
            print("input_files" + str(input_files) + "\tresid_chain_list" + str(resid_chain_list), file=outfile)
    # I initialize the residue_dict
    for residue in resid_chain_list:
        residue_dict[residue] = 0.0
    for input_file in input_files:
        with open(input_file, 'r') as csvfile:
            reader = csv.reader(csvfile)
            label_row = 9999
            for ndx, row in enumerate(reader):
                # skip the empty rows
                if not row:
                    # print(row)
                    continue
                # save when the tabled data starts
                if row[0] == "Residue":
                    label_row = ndx
                # skip the rows before the tabled data and with labels
                if ndx - 1 <= label_row:
                    continue
                # skip the residues belonging to the receptor (we want the ligand residues)
                if row[0][0] == 'R':
                    continue
                residue_chain = row[0].split(':')[1]
                residue_id = row[0].split(':')[3]
                #     ############# FIXING FOR THE CONNEXIN SYSTEM WITH 1 LIGAND CHAIN #####################
                if adhoc_fixing == "Cx43" or adhoc_fixing == "Cx":
                    if residue_chain == 'G':
                        residue_chain = 'H'
                #     #############   FIXING FOR THE HLA SYSTEM WITH 2 LIGAND CHAINs   #####################
                if adhoc_fixing == "HLA_biAB":
                    if residue_chain == 'A':
                        residue_chain = 'P'
                    if residue_chain == 'B':
                        residue_chain = 'A'
                    if residue_chain == 'C':
                        residue_chain = 'H'
                    if residue_chain == 'D':
                        residue_chain = 'L'
                residue = residue_id + ':' + residue_chain
                # If the residue is also in the residue list used by the program to select the next mutation, I save it
                if residue in resid_chain_list:
                    residue_dict[residue] += float(row[16])
                    # be_contribution_list.append(float(row[16]))
            # print("\nresidue_dict:" + str(residue_dict))
            # print("be_contribution_list:" + str(be_contribution_list) + "\n")
    # Compute the averages
    for residue in resid_chain_list:
        residue_dict[residue] /= len(input_files)
        be_contribution_list.append(residue_dict[residue])
        if logfile:
            with open(logfile, 'a') as outfile:
                print(str(residue) + "->" + str(residue_dict[residue]) + "", file=outfile)
    min_be = 0.0
    for energy in be_contribution_list:
        if energy < min_be:
            min_be = energy
    # I suppose that the min value is negative. In case is not, I do not translate the binding-energy values
    if min_be < 0:
        for element in residue_dict:
            residue_dict[element] += abs(min_be)
        # print(ndx)
        # print(row)
    # print("residue_dict:" + str(residue_dict) + " be_contribution:" + str(be_contribution_list))
    return residue_dict


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Read the FINAL_DECOMP_MMPBSA.dat file from gmx_mmpbsa and return an '
                                                 'array of float that can be used as weights.')
    parser.add_argument('-i', '--input_files', type=str, nargs='+', default=["FINAL_DECOMP_MMPBSA.dat"],
                        help='Input file name with the per residue energy decomposition '
                             '(Default: FINAL_DECOMP_MMPBSA.dat)')
    parser.add_argument('-r', '--resid_chain_list', type=str, nargs='+',
                        help='list of Residue "position:chain" of the residue you want to mutate')
    parser.add_argument('-l', '--logfile', type=str, default="weights.log",
                        help='Log file used in case of verbose=True (Default: weights.log)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    args = parser.parse_args()

    for file in args.input_files:
        assert isfile(file) and access(file, R_OK), \
            ValueError("You must provide a readable input file! input file:'{}'".format(file))
    print(compute_weights(input_files=args.input_files, resid_chain_list=args.resid_chain_list, logfile=args.logfile))
