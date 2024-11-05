#!/usr/bin/env python3


"""
This script use Chimera to perform a single point mutation.
Author: Damiano Buratto
Date: NOV/2019
"""

import os
import sys
import argparse
from chimera import runCommand as rc # use 'rc' as shorthand for runCommand
from chimera import replyobj # for emitting status messages

"""
# change to folder with data files
os.chdir("/Users/pett/data")

# gather the names of .pdb files in the folder
file_names = [fn for fn in os.listdir(".") if fn.endswith(".pdb")]

# loop through the files, opening, processing, and closing each in turn
for fn in file_names:
    replyobj.status("Processing " + fn) # show what file we're working on
    rc("open " + fn)
    rc("align ligand ~ligand") # put ligand in front of remainder of molecule
    rc("focus ligand") # center/zoom ligand
    rc("surf") # surface receptor
    rc("preset apply publication 1") # make everything look nice
    rc("surftransp 15") # make the surface a little bit see-through
    # save image to a file that ends in .png rather than .pdb
    png_name = fn[:-3] + "png"
    rc("copy file " + png_name + " supersample 3")
    rc("close all")
# uncommenting the line below will cause Chimera to exit when the script is done
rc("stop now")
# note that indentation is significant in Python; the fact that
# the above command is exdented means that it is executed after
# the loop completes, whereas the indented commands that
# preceded it are executed as part of the loop.
"""

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='Run Chimera to upload a pdb and mutate a single aminoacid',
        epilog="All work and no play makes Jack a dull boy.")

    parser.add_argument('pdb_file', help='path to the pdb file containing the protein that has to be mutated',
                        type=argparse.FileType('r'))

    parser.add_argument('-o', '--out_file', help='path and name to the output file', default="output.pdb", type=str)
    parser.add_argument('-n', '--residueNUN', help='Number of the residue you want to change', type=int)
    parser.add_argument('-c', '--residueCHAIN', help='Chain of the residue you want to change', type=str)
    parser.add_argument('-r', '--NEWresidue', help='Name of the new residue you want', type=str)
    """
    parser.add_argument('-np', '--nprocesses', metavar='NPROCS', type=check_positive, default=2,
                        help='defines the number of processes used to compute the distance matrix and multidimensional representation (default = 2)')
    parser.add_argument('-n', '--no-hydrogen', action='store_true',
                        help='ignore hydrogens when doing the Kabsch superposition and calculating the RMSD')
    parser.add_argument('-p', '--plot', action='store_true',
                        help='enable the multidimensional scaling and dendrogram plot saving the figures in pdf format (filenames use the same basename of the -oc option)')
    parser.add_argument('-m', '--method', metavar='METHOD', default='average',
                        help="method used for clustering (see valid methods at https://docs.scipy.org/doc/scipy-0.19.1/reference/generated/scipy.cluster.hierarchy.linkage.html) (default: average)")
    parser.add_argument('-cc', '--clusters-configurations', metavar='EXTENSION',
                        help='save superposed configurations for each cluster in EXTENSION format (basename based on -oc option)')
    parser.add_argument('-oc', '--outputclusters', default='clusters.dat', metavar='FILE',
                        help='file to store the clusters (default: clusters.dat)')

    io_group = parser.add_mutually_exclusive_group()
    io_group.add_argument('-i', '--input', type=argparse.FileType('rb'), metavar='FILE',
                          help='file containing input distance matrix in condensed form')
    io_group.add_argument('-od', '--outputdistmat', metavar='FILE',
                          help='file to store distance matrix in condensed form (default: distmat.dat)')
    """

    if len(sys.argv) < 1:
        parser.print_help()
        sys.exit(1)

    args = parser.parse_args()

    NEWresidue = args.NEWresidue
    residueNUN = args.residueNUN
    residueCHAIN = args.residueCHAIN

    replyobj.status("Processing " + args.pdb_file.name)
    rc("open " + args.pdb_file.name)
    rc("preset apply publication 1")
    replyobj.status("Changing residue " + repr(args.residueNUN) + " of chain " + repr(args.residueCHAIN))
    replyobj.status("Changing residue " + repr(residueNUN) + " of chain " + repr(residueCHAIN) + " in residue " + repr(NEWresidue))

    #residuePosition="#0:" + repr(args.residueNUN) + "." + repr(args.residueCHAIN)
    rc("swapaa " + args.NEWresidue + " #0:" + repr(args.residueNUN) + "." + args.residueCHAIN + " lib dynameomics")
    #rc("swapaa ala #0:100.H lib dynameomics")

    rc("write format pdb #0 " + args.out_file)
    rc("close all")
    rc("stop now")

    print()
