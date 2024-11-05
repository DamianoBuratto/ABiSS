#!/bin/bash

echo -e "Sourcing the functions that will be used in the program..."

#SystemName='CXCR2'  # Cx, CXCR2, Covid-Ace; HLA_biAB

# GLOBAL VARIABLE
# shellcheck disable=SC2154
[[ -d ${ABiSS_LIB} ]] || { echo "functions_list ERROR: I cannot find the folder ABiSS_LIB($ABiSS_LIB)"; return 1; }

# I must source this first becaus is used on the other functions
source "${ABiSS_LIB}"/FUNCTIONs/msg_fatal.sh

#############           CHECK functions
source "${ABiSS_LIB}"/FUNCTIONs/findPATH.sh
source "${ABiSS_LIB}"/FUNCTIONs/GROMACS_CheckSet.sh
source "${ABiSS_LIB}"/FUNCTIONs/printCHECKPOINT.sh
source "${ABiSS_LIB}"/FUNCTIONs/stopwatch.sh
####################################################################

#############           Starting the program functions
#source "${ABiSS_LIB}"/FUNCTIONs/Starting_User_Inputs.sh      # DEPRECATE

# source "${ABiSS_LIB}"/FUNCTIONs/Starting_Values.sh
#[[ $SystemName == "HLA_biAB" ]] && source "${ABiSS_LIB}"/FUNCTIONs/Starting_Values_HLA.sh
#[[ $SystemName == "CXCR2" ]] && source "${ABiSS_LIB}"/FUNCTIONs/Starting_Values_CXCR2.sh
#[[ $SystemName == "Cx" ]] && source "${ABiSS_LIB}"/FUNCTIONs/Starting_Values_Cx.sh
#[[ $SystemName == "Cx43" ]] && source "${ABiSS_LIB}"/FUNCTIONs/Starting_Values_Cx43.sh


source "${ABiSS_LIB}"/FUNCTIONs/Set_cluster_variables.sh
####################################################################

#############                 others
source "${ABiSS_LIB}"/FUNCTIONs/BuildFoldersAndPrintHeadingFiles.sh
#source "${ABiSS_LIB}"/FUNCTIONs/MakeNewMutant_Chimera.sh
source "${ABiSS_LIB}"/FUNCTIONs/addTERpdb.sh
source "${ABiSS_LIB}"/FUNCTIONs/MakeTOP_protein.sh
source "${ABiSS_LIB}"/FUNCTIONs/analysis.sh
source "${ABiSS_LIB}"/FUNCTIONs/MakeFiles_GMXPBSA.sh
#[[ $SystemName == "Cx" ]] && source "${ABiSS_LIB}"/FUNCTIONs/MakeFiles_GMXPBSA_Cx.sh
source "${ABiSS_LIB}"/FUNCTIONs/buildBoxWaterIons.sh
source "${ABiSS_LIB}"/FUNCTIONs/run_minim.sh
source "${ABiSS_LIB}"/FUNCTIONs/MakeNewMinimConfig.sh
source "${ABiSS_LIB}"/FUNCTIONs/VMD_function.sh
source "${ABiSS_LIB}"/FUNCTIONs/MDPs_setup.sh
#source "${ABiSS_LIB}"/FUNCTIONs/Custom_mdpFILE.sh
source "${ABiSS_LIB}"/FUNCTIONs/PosResSelection.sh
#source "${ABiSS_LIB}"/FUNCTIONs/MakePOSRES_protein.sh
source "${ABiSS_LIB}"/FUNCTIONs/GRO_to_PDB.sh
source "${ABiSS_LIB}"/FUNCTIONs/all_to_HIS.sh

####################################################################

#source "${ABiSS_LIB}"/FUNCTIONs/namd_config.sh

