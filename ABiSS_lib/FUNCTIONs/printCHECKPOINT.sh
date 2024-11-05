#!/bin/bash

echo -e "\t > printCHECKPOINT.sh"

# shellcheck disable=SC2154
function printCHECKPOINT {
	local _logFileName=$1
	[ -r "${_logFileName}" ] || { fatal 12 "printCHECKPOINT ERROR: log file ('${_logFileName}') can not be found or read"; }
	
	echo -e "\n\t RUNNING ${PN} ver${VER}		\n\n\t **INPUT and OPTIONS:" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "GROMACS version" "${GROMACSver}" | tee -a "${_logFileName}"

	printf "\t %-40s -> %-80s\n" "GPATH" "${GPATH}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "CPATH" "${CPATH}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "APATH" "${APATH}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "folder" "${fd}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "SYSTEM_NAME" "${SYSTEM_NAME}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "complex_FILE" "${complex_FILE} ($complex_EXT)" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "EnergyCalculation" "${EnergyCalculation}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n\n" "mmpbsa_inFILE" "${mmpbsa_inFILE}" | tee -a "${_logFileName}"

	printf "\t %-40s -> %-80s\n" "ResiduePool_list" "${ResiduePool_list}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "ABchains" "${ABchains}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "receptorFRAG" "${receptorFRAG} " | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "POSRES" "${POSRES}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "POSRES_RESIDUES" "${POSRES_RESIDUES}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "TargetResidueList[*]" "${TargetResidueList[*]}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "TargetChainName" "${TargetChainName}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "mergeFragments" "${mergeFragments}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "mergeC" "${mergeC}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "mergeR" "${mergeR}" | tee -a "${_logFileName}"
	printf "\t %-40s -> %-80s\n" "mergeL" "${mergeL}" | tee -a "${_logFileName}"

	# shellcheck disable=SC2016
#	echo -e '\n\t MakeFiles_GMXPBSA -gro system_Compl_MD -xtc \"${trjNAME}\" -tpr \"${tprFILE}\" -top \"${topName}\" -cn \"${confNAME}\"
#		  \t\t-rn \"${rootName}\" -ff \"$ForceField\" -mnp \"$MNP\" -pF \"$precF\" -pd \"$pdie\" -ac \"$ABchains\"
#		  \t\t-rf \"$receptorFRAG\" -s \"${startingFrameGMXPBSA}\" -min \"${GMXPBSAminim}\" -m \"${Protein_MD_EngComp_ff14sb_NAME}\"
#		  \t\t\"${GMXPBSA_use_tpbcon}\" \"${linearizedPB}\" \"${GMXPBSA_NO_topol_ff}\" || exit' | tee -a "${_logFileName}"
#	echo -e "\n\t MakeFiles_GMXPBSA -gro system_Compl_MD -xtc \"${trjNAME}\" -tpr \"${tprFILE}\" -top \"${topName}\" -cn \"${confNAME}\" \
#		  \n\t\t\t-rn \"${rootName}\" -ff \"$ForceField\" -mnp \"$MNP\" -pF \"$precF\" -pd \"$pdie\" -ac \"$ABchains\" -rf \"$receptorFRAG\" -s \"${startingFrameGMXPBSA}\" -min \"${GMXPBSAminim}\" \
#		  \n\t\t\t-m \"${Protein_MD_EngComp_ff14sb_NAME}\" \
#		  \n\t\t\t\"${GMXPBSA_use_tpbcon}\" \"${linearizedPB}\" \"${GMXPBSA_NO_topol_ff}\" || exit" | tee -a "${_logFileName}"

	echo -e "\n" | tee -a "${_logFileName}"
  { echo -e "  Every other variable that will be used:";
	printf "\t %-40s -> %-80s\n" "DEBUG" "${DEBUG}";
	printf "\t %-40s -> %-80s\n" "FAST" "${FAST}";
	printf "\t %-40s -> %-80s\n" "GsourcePATH" "${GsourcePATH}";
	printf "\t %-40s -> %-80s\n" "RestartEnergy" "${RestartEnergy}";
	printf "\t %-40s -> %-80s\n" "ComputeOnlyEnergy" "${ComputeOnlyEnergy}";
	printf "\t %-40s -> %-80s\n" "NUMframe" "${NUMframe}";
	printf "\t %-40s -> %-80s\n" "JerkwinPATH" "${JerkwinPATH}";
	printf "\t %-40s -> %-80s\n" "ProgramPATH" "${ProgramPATH}";
	printf "\t %-40s -> %-80s\n" "STARTING_FOLDER" "${STARTING_FOLDER}";
	printf "\t %-40s -> %-80s\n" "ABiSS_LIB" "${ABiSS_LIB}";
	printf "\t %-40s -> %-80s\n" "RUN_FOLDER" "${RUN_FOLDER}";
	printf "\t %-40s -> %-80s\n" "LOGFILENAME" "${LOGFILENAME}";
	printf "\t %-40s -> %-80s\n" "CONFOUT_FILENAME" "${CONFOUT_FILENAME}";
	printf "\t %-40s -> %-80s\n" "SETUP_PROGRAM_FOLDER" "${SETUP_PROGRAM_FOLDER}";
	printf "\t %-40s -> %-80s\n" "DOUBLE_CHECK_FOLDER" "${DOUBLE_CHECK_FOLDER}";
	printf "\t %-40s -> %-80s\n" "minim_NAME" "${minim_NAME}";
	printf "\t %-40s -> %-80s\n" "SAMD_NAME" "${SAMD_NAME}";
	printf "\t %-40s -> %-80s\n" "NVT_NAME" "${NVT_NAME}";
	printf "\t %-40s -> %-80s\n" "NPT_NAME" "${NPT_NAME}";
	printf "\t %-40s -> %-80s\n" "MD_EngComp_ff14sb_NAME" "${MD_EngComp_ff14sb_NAME}";
	printf "\t %-40s -> %-80s\n" "Protein_MD_EngComp_ff14sb_NAME" "${Protein_MD_EngComp_ff14sb_NAME}";
	printf "\t %-40s -> %-80s\n" "AWK" "${AWK}";
	printf "\t %-40s -> %-80s\n" "VMD" "${VMD}";
	printf "\t %-40s -> %-80s\n" "CHIMERA" "${CHIMERA}";
	printf "\t %-40s -> %-80s\n" "GROMPP" "${GROMPP}";
	printf "\t %-40s -> %-80s\n" "PDB2GMX" "${PDB2GMX}";
	printf "\t %-40s -> %-80s\n" "EDITCONF" "${EDITCONF}";
	printf "\t %-40s -> %-80s\n" "GENBOX" "${GENBOX}";
	printf "\t %-40s -> %-80s\n" "GENION" "${GENION}";
	printf "\t %-40s -> %-80s\n" "MAKE_NDX" "${MAKE_NDX}";
	printf "\t %-40s -> %-80s\n" "TRJCONV" "${TRJCONV}";
	printf "\t %-40s -> %-80s\n" "GENRESTR" "${GENRESTR}";
	printf "\t %-40s -> %-80s\n" "MDRUN_md" "${MDRUN_md}";
	printf "\t %-40s -> %-80s\n" "MPI_RUN" "${MPI_RUN}";
	printf "\t %-40s -> %-80s\n" "source_GMX" "${source_GMX}";
	printf "\t %-40s -> %-80s\n" "groMDslow_NAME" "${groMDslow_NAME}";
	printf "\t %-40s -> %-80s\n" "trjNAME" "${trjNAME}";
	printf "\t %-40s -> %-80s\n" "tprFILE" "${tprFILE}";
	printf "\t %-40s -> %-80s\n" "topName" "${topName}";
	printf "\t %-40s -> %-80s\n" "nameCHAIN[*]" "${nameCHAIN[*]}";
	printf "\t %-40s -> %-80s\n" "protein_ITPname[*]" "${protein_ITPname[*]}";
	printf "\t %-40s -> %-80s\n" "StartingMutant" "${StartingMutant}";
	printf "\t %-40s -> %-80s\n" "Stored_AVG" "${Stored_AVG}";
	printf "\t %-40s -> %-80s\n" "MaxMutant" "${MaxMutant}";
	printf "\t %-40s -> %-80s\n" "TotRunningNum" "${TotRunningNum} # number of repetition for each configuration";
	printf "\t %-40s -> %-80s\n" "(nsteps)" "$(head -n 19 "$MD_EngComp_ff14sb_NAME" | tail -n 1)";	# nsteps
	printf "\t %-40s -> %-80s\n" "(nstxout-compressed)" "$(head -n 29 "$MD_EngComp_ff14sb_NAME" | tail -n 1)"; # nstxout-compressed
	printf "\t %-40s -> %-80s\n" "GMXPBSA_NO_topol_ff" "${GMXPBSA_NO_topol_ff}" ;
	printf "\t %-40s -> %-80s\n" "GMXPBSA_NO_top_ff" "${GMXPBSA_NO_top_ff}" ;
	printf "\t %-40s -> %-80s\n" "NO_top_ff" "${NO_top_ff}" ;
	printf "\t %-40s -> %-80s\n" "GMXPBSA_use_tpbcon" "${GMXPBSA_use_tpbcon}" ;
	printf "\t %-40s -> %-80s\n" "linearizedPB" "${linearizedPB}" ;
	printf "\t %-40s -> %-80s\n" "precF, pdie" "${precF} / ${pdie}" ;
	printf "\t %-40s -> %-80s\n" "GMXPBSApath" "${GMXPBSApath}" ;
	printf "\t %-40s -> %-80s\n" "ForceField" "${ForceField}" ;
	printf "\t %-40s -> %-80s\n" "EnergyFunction " "${EnergyFunction} # 3: dG | 8: ScoreF | 9:ScoreF2 | 10: CanonicalAVG | 11: Median";
	printf "\t %-40s -> %-80s\n" "cluster,MDRUN,NP_value" "${cluster} / ${MDRUN} / ${NP_value}" ;
	printf "\t %-40s -> %-80s\n" "GMXPBSAminim (minimization)" "${GMXPBSAminim}" ;
	printf "\t %-40s -> %-80s\n" "trjconvOPT" "${trjconvOPT}" ;
	printf "\t %-40s -> %-80s\n" "editconf_opt" "${editconf_opt}" ;
	printf "\t %-40s -> %-80s\n" "startingFrameGMXPBSA" "${startingFrameGMXPBSA}" ;
	printf "\t %-40s -> %-80s\n" "TargetResidueList_num" "${TargetResidueList_num}" ;
	printf "\t %-40s -> %-80s\n" "Metropolis_flag" "${Metropolis_flag}" ;
	printf "\t %-40s -> %-80s\n" "Metropolis_Temp" "${Metropolis_Temp}" ;
	printf "\t %-40s -> %-80s\n" "AcceptProb" "${AcceptProb}" ;

	printf "\t %-40s -> %-80s\n" "KEY_annealing" "${KEY_annealing}" ;
	printf "\t %-40s -> %-80s\n" "KEY_SA_npoints" "${KEY_SA_npoints}" ;
	printf "\t %-40s -> %-80s\n" "KEY_SA_temp" "${KEY_SA_temp}" ;
	printf "\t %-40s -> %-80s\n" "KEY_SA_time[@]" "${KEY_SA_time[*]}";
	printf "\t %-40s -> %-80s\n" "KEY_nsteps[@](min,SA,NVT,NPT,MD)" "${KEY_nsteps[*]}";
	printf "\t %-40s -> %-80s\n" "KEY_nstouts[@](min,SA,NVT,NPT,MD)" "${KEY_nstouts[*]}";
	printf "\t %-40s -> %-80s\n" "KEY_define_SAMD" "${KEY_define_SAMD}";
	printf "\t %-40s -> %-80s\n" "KEY_define_MD" "${KEY_define_MD}";
	printf "\t %-40s -> %-80s\n" "KEY_pcoupl" "${KEY_pcoupl}";
	printf "\t %-40s -> %-80s\n" "KEY_compressed" "${KEY_compressed}";
	echo -e "  **** FEP     	 ";
	printf "\t %-40s -> %-80s\n" "KEY_dt" "${KEY_dt}";
	printf "\t %-40s -> %-80s\n" "KEY_comm_mode" "${KEY_comm_mode}";
	printf "\t %-40s -> %-80s\n" "KEY_refcoord_scaling" "${KEY_refcoord_scaling}";
	printf "\t %-40s -> %-80s\n" "KEY_couple_moltype" "${KEY_couple_moltype}";
	printf "\t %-40s -> %-80s\n" "KEY_couple_lambda0" "${KEY_couple_lambda0}";
	printf "\t %-40s -> %-80s\n" "KEY_couple_lambda1" "${KEY_couple_lambda1}";
	printf "\t %-40s -> %-80s\n" "KEY_sc_coul" "${KEY_sc_coul}";
	printf "\t %-40s -> %-80s\n" "KEY_fep_lambdas" "${KEY_fep_lambdas}";
	printf "\t %-40s -> %-80s\n" "KEY_bonded_lambdas" "${KEY_bonded_lambdas}";
	printf "\t %-40s -> %-80s\n" "KEY_coul_lambdas" "${KEY_coul_lambdas}";
	printf "\t %-40s -> %-80s\n" "KEY_vdw_lambdas" "${KEY_vdw_lambdas}";
	printf "\t %-40s -> %-80s\n" "KEY_nstdhdl" "${KEY_nstdhdl}";
	printf "\t %-40s -> %-80s\n" "KEY_calc_lambda_neighbors" "${KEY_calc_lambda_neighbors}";	} >> "${_logFileName}"
##
  echo -e "\n" | tee -a "${_logFileName}"

  printenv > "${SETUP_PROGRAM_FOLDER}"/Variables.out

	# printenv
}







