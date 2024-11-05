#!/bin/bash

echo -e "\t > MakeFiles_GMXPBSA.sh"
#source "${ABiSS_LIB}"/FUNCTIONs/GRO_to_PDB.sh

function makeNDX_string_GMXPBSA {
  	# the first 2 chain are the antibody chains (ligand), the third chain is the protein (receptor)
	local _receptorFRAG=$1
	local _ABchains=$2
	local _output_variable=$3
	local _makeNDX_string="keep 1\nsplitch 0\n"
	local _flag=""
	local _flag2=""

	# I suppose the receptor comes before the ligand (antibody) in the pdb file
	if [ "$_receptorFRAG" -gt 1 ]; then
		_flag="1"
		_flag2="del 1\n"
		for i in $(seq 2 "$_receptorFRAG"); do
			_flag="${_flag}|$i"
			_flag2="${_flag2}del 1\n"
			#_makeNDX_string="${_makeNDX_string}"
		done
	else
		_flag="0&1"
		_flag2="del 1\n"
	fi
	_makeNDX_string="${_makeNDX_string}${_flag}\n${_flag2}"
	if [ "$_ABchains" -gt 1 ]; then
		_flag="1"
		_flag2="del 1\n"
		for i in $(seq 2 "$_ABchains"); do
			_flag="${_flag}|$i"
			_flag2="${_flag2}del 1\n"
			#_makeNDX_string="${_makeNDX_string}"
		done
		_makeNDX_string="${_makeNDX_string}${_flag}\n${_flag2}del 0\n0|1\n"
	else
		_makeNDX_string="${_makeNDX_string}0&1\ndel 0\ndel 0\n0|1\n"
	fi
	_makeNDX_string="${_makeNDX_string}name 0 receptor\nname 1 ligand\n name 2 complex\n\nq\n"
	echo -e "receptorFRAG->$_receptorFRAG ABchains->$_ABchains \nmakeNDX_string:${_makeNDX_string}" &> make_ndx.temp
	eval "$_output_variable='$_makeNDX_string'"
  # OLD VERSION FOR REFERENCE
	#if [ "$_ABchains" == "2" ]; then
	#	echo -e "keep 1\nsplitch 0\ndel 0\n0|1\ndel 0\ndel 0\n0|1\nname 0 receptor\nname 1 ligand\nname 2 complex\n\nq\n" | make_ndx -f ${_confNAME}_starting_protein.pdb -o ${_rootName}/index.ndx &> make_ndx.temp || { echo " something wrong on MAKE_NDX!! exiting..."; exit; }
	#elif [ "$_ABchains" == "1" ]; then
	#	echo -e "keep 1\nsplitch 0\ndel 0\n0|1\n\nname 0 receptor\nname 1 ligand\nname 2 complex\n\nq\n" | make_ndx -f ${_confNAME}_starting_protein.pdb -o ${_rootName}/index.ndx &> make_ndx.temp || { echo " something wrong on MAKE_NDX!! exiting..."; exit; }
	#else
	#	fatal 2 "MakeFiles_GMXPBSA ERROR: Something wrong with _ABchains ($_ABchains)!!"
	#fi

}

MakeFiles_GMXPBSA () {
# usage: MakeFiles_GMXPBSA

	#Other functions/programs:
	#gromacs

	#GLOBAL VARIABLE USED:
	# it uses msg_fatal
  $GROMPP -h &> /dev/null || { echo "MakeFiles_GMXPBSA ERROR: cannot find GROMPP($GROMPP)"; return 1; }
  $TRJCONV -h &> /dev/null || { echo "MakeFiles_GMXPBSA ERROR: cannot find TRJCONV($TRJCONV)"; return 1; }
  $MAKE_NDX -h &> /dev/null || { echo "MakeFiles_GMXPBSA ERROR: cannot find MAKE_NDX($MAKE_NDX)"; return 1; }
  $CHECK -h &> /dev/null || { echo "MakeFiles_GMXPBSA ERROR: cannot find CHECK($CHECK)"; return 1; }
  [[ -d $DOUBLE_CHECK_FOLDER ]] || { echo "MakeFiles_GMXPBSA ERROR: cannot find DOUBLE_CHECK_FOLDER($DOUBLE_CHECK_FOLDER)"; return 1; }
  [[ -d $TEMP_FILES_FOLDER ]] || { echo "MakeFiles_GMXPBSA ERROR: cannot find DOUBLE_CHECK_FOLDER($TEMP_FILES_FOLDER)"; return 1; }

	#LOCAL VARIABLES:
	local _StartingGro_FILE=
	local _trj_FILE=
	local _tpr_FILE=
	local _top_FILE=
	local _confNAME=
	local _rootName=
	local _runNumber=
	local _mdp_NAME="$SETUP_PROGRAM_FOLDER/EngComp_ff14*custom*.mdp"
#	local _NUMframe="all"               # NOT USED
	local _ForceField="6"
	local _np="1"
	local _precF="2"
	local _pdie="4"
	local _linearized="n"
	local _ABchains="2"
	local _receptorFRAG="1"
	local _NDX_string=
	local _flag=
	local _flag2=
	local _startingFrame="0"
	local _multichain="n"
	local _num_his=
	local _his_string=
#	local _merge=                 # NOT USED
  local _mergeC=
  local _mergeR=
  local _mergeL=
	local _minimization="n"
	local _NO_topol_ff="n"
	local _use_tpbcon="n"

	while [ $# -gt 0 ]
	do
	    case "$1" in
		-gro)			shift; _StartingGro_FILE=$1;;			# starting frame of the long simulation
		-s_pdb)   shift; _original_pdb_file=$1;;    # starting pdb file with the original chain names
		-xtc)			shift; _trj_FILE=$1;;			 	      # MD simulation trajectory
		-tpr)			shift; _tpr_FILE=$1;;				      # MD simulation tpr file
		-top)			shift; _top_FILE=$1;;				      # topology used for the long simulation
		-s)    		shift; _startingFrame=$1;;        # starting frame [ps] for the Energy computation (Deafault=0 -> all the trajectory)
		-r)				shift; _runNumber=$1;;            # run number to set gmxmmpbsa
		-cn)			shift; _confNAME=$1;;             # configuration name used in the gmxmmpbsa run
		-rn)			shift; _rootName=$1;;             # rootname used for gmxmmpbsa folder
		-m)				shift; _mdp_NAME=$1;;             # mdp used to make the only_protein tpr configuration
#		-n)				shift; _NUMframe=$1;;
		-ff)			shift; _ForceField=$1;;        # forcefield used by gmxmmpbsa
		-np)			shift; _np=$1;;
		-pF)			shift; _precF=$1;;
		-pd)			shift; _pdie=$1;;
		-ac)			shift; _ABchains=$1;;             # Number of chains in the antibody (ligand)
		-rf)			shift; _receptorFRAG=$1;;         # Number of fragment in the receptor (supposedly 1)
		-mergeC)	shift; _mergeC=$1;;
		-mergeR)	shift; _mergeR=$1;;
		-mergeL)	shift; _mergeL=$1;;
		-min)			shift; _minimization=$1;;
		-noTF)		_NO_topol_ff="y";;
		-utc)			_use_tpbcon="y";;
		-l)				_linearized="y";;
		*)				if [ "$1" == "" ]; then
		            shift
		            continue
		          fi
		          fatal 1 "MakeFiles_GMXPBSA ERROR: $1 is not a valid OPTION!\n MakeFiles_GMXPBSA $*\n";;
	    esac
	    shift
	done
	# set up _confNAME and _rootName in case they are not customised
	if [ "$_confNAME" == "" ] || [ "$_rootName" == "" ]; then
		[ "$_runNumber" == "" ] && _rootName="1"
		_confNAME="conf${_runNumber}"
		_rootName="config${_runNumber}_prot"
	elif ! [ "$_runNumber" == "" ]; then
		_confNAME="conf${_runNumber}"
		_rootName="config${_runNumber}_prot"
	fi
  # CHECK for the mandatory files
	if ! [ -r "${_StartingGro_FILE}.gro" ] || ! [ -r "${_trj_FILE}.xtc" ] || ! [ -r "${_tpr_FILE}.tpr" ] || ! [ -r "${_top_FILE}.top" ]; then
		fatal 2 "MakeFiles_GMXPBSA ERROR: one of the input file is missing! \nGROfile:${_StartingGro_FILE}.gro \
		TRJfile:${_trj_FILE}.xtc TPRfile:${_tpr_FILE}.tpr TOPfile:${_top_FILE}.top"
	fi

	if [ "${_receptorFRAG}" -gt 1 ]; then
	# This is needed to change the pdb file and add TER at the end of every fragment. Not necessary if the fragment change with the chain.
		_multichain="y"
	fi

	#====================================================================================================================================================
	#msg "                            --MAKE THE FILES-- 			"
	#====================================================================================================================================================

	mkdir -p "${_rootName}"
	rm "${_rootName}"/* 2> /dev/null
	#rm *out 2> /dev/null

	#make index adhoc									ONLY 1 PROTEIN AND 1 MOLECULE ALLOWED FOR NOW
	echo -e "keep 1\n\nq\n" | $MAKE_NDX -f "${_StartingGro_FILE}.gro" -o index.ndx 		\
	  &> make_ndx.temp || { echo " something wrong on 1st MAKE_NDX!! exiting..."; return 3; }

	# TRJCONV to make starting frame .pdb
	#$(date +%H:%M:%S)
	msg "\t\t --running TRJCONV to make first frame .pdb.. "
#	echo "0" | $TRJCONV -n index.ndx -f "${_trj_FILE}.xtc" -o "${_confNAME}_starting.pdb" -s "${_tpr_FILE}.tpr" -sep -e 0 		\
#  	&> trjconv.temp || { echo " something wrong on TRJCONV!! exiting..."; return 4; }
#	mv "${_confNAME}_starting0.pdb" "${_confNAME}_starting_protein.pdb"
  # I want to have the same chain name of the starting pdb file it is better to start from the GRO and use my
  # GRO_to_PDB function.
  _path=${_original_pdb_file%/*}
  _name=${_original_pdb_file##*/}
  _name=${_name%.*}
  GRO_to_PDB -gn "${_StartingGro_FILE}" -pp "$_path" -pn "$_name" -o "${_confNAME}_starting_protein"
  [[ -r "${_confNAME}_starting_protein.pdb" ]] || { echo "Error running GRO_to_PDB!! exiting..."; return 4; }
	# TRJCONV to remove the pbc from the trajectory
	msg "\t\t --running TRJCONV to remove the pbc from the trajectory.. "
	echo "0" | $TRJCONV -n index.ndx -f "${_trj_FILE}.xtc" -o ./nptMD_nojump_temp.xtc -s "${_tpr_FILE}.tpr" -pbc nojump -b "${_startingFrame}"		\
  	&>> trjconv.temp || { echo " something wrong on 1st TRJCONV!! exiting..."; return 5; }
	echo -e "1\n0" | $TRJCONV -n index.ndx -f ./nptMD_nojump_temp.xtc -o ./"${_rootName}/${_confNAME}_noPBC.xtc" -s "${_tpr_FILE}.tpr" -pbc mol -center 	\
  	&>> trjconv.temp || { echo " something wrong on 2nd TRJCONV!! exiting..."; return 6; }
  $CHECK -f ./"${_rootName}/${_confNAME}_noPBC.xtc" &> trj_check.out || { echo "gmx check problem!! exiting..."; return 6; }

	# MAKE_NDX for the receptor(pept/protein), ligand(ab/mol), complex (exactly in this order and with these names)
	msg "\t\t --running MAKE_NDX to make index with only receptor, ligand and complex.. "
	makeNDX_string_GMXPBSA "$_receptorFRAG" "$_ABchains" '_NDX_string'
	echo '_NDX_string' >> make_ndx.temp
	echo -e "${_NDX_string}" | $MAKE_NDX -f "${_confNAME}_starting_protein.pdb" -o "${_rootName}/index.ndx" \
	  &>> make_ndx.temp || { echo " something wrong on 2nd MAKE_NDX!! exiting..."; return 7; }
	cp make_ndx.temp "${DOUBLE_CHECK_FOLDER}"/Make_ndx_gmxmmpbsa.out

	# HEAD to make a temporary new only-protein top
	msg "\t\t --using HEAD to make a only-protein top.. "
	head -n -3 "${_top_FILE}.top" > "${_top_FILE}_protein.top"
	# GROMPP to make a protein tpr (gromacs version used by the old GMXMMPBSA)
	msg "\t\t --GROMPP to make a protein tpr.. "
	$GROMPP -v -f "${_mdp_NAME}" -c "${_confNAME}_starting_protein.pdb" -p "${_top_FILE}_protein.top" -o "${_rootName}/${_confNAME}.tpr" -maxwarn "1" \
	  &>> grompp_OP.temp || { echo " something wrong on GROMPP!! exiting..."; return 8; }
	# repeat using the latest version of gromacs for the new gmx_MMPBSA
	$GROMPP -v -f "${_mdp_NAME}" -c "${_confNAME}_starting_protein.pdb" -p "${_top_FILE}_protein.top" -o "${_rootName}/${_confNAME}_newGRO.tpr" -maxwarn "1" \
	  &>> grompp_OP.temp || { echo " something wrong on GROMPP_newGRO!! exiting..."; return 9; }

  # inside the ${_rootName} folder I have index.ndx(receptor, ligand, complex), ${_confNAME}.tpr and ${_confNAME}_noPBC.xtc
	_his_string=""
	_num_his=$(grep -E -c "(HIS     CA)|(HID     CA)|(HIE     CA)|(HIP     CA)|(HSD     CA)|(HSE     CA)|(HSP     CA)|(CA  HIS)|(CA  HID)|(CA  HIE)|(CA  HIP)|(CA  HSD)|(CA  HSE)|(CA  HSP)" "${confNAME}_starting_protein.pdb")
	for i in $(seq 1 "$_num_his"); do
		_his_string="${_his_string}1\n"
	done
	############################ BUILD the INPUT FILE for GMXPBSA #######################################
	echo "
#GENERAL VARIABLES
root      		    ${_rootName}
multitrj          n

run			          1                 #options: integer
RecoverJobs		    y                 #options: y,n
backup			      y                 #options: y,n

Cpath   		      ${CPATH}
Apath   		      ${APATH}
Gpath			        ${GPATH}

name_xtc		      ${_confNAME}_noPBC
name_tpr		      ${_confNAME}

multichain		    ${_multichain}
Histidine		      ${_his_string}
min			          ${_minimization}		#perform minimiz before compute the energy
use_tpbcon		    ${_use_tpbcon}
mergeC			      ${_mergeC}
mergeR			      ${_mergeR}
mergeL			      ${_mergeL}
#protein_alone		possibility to perform DeltaG CAS calculation on a single protein Default n

NO_topol_ff		    ${_NO_topol_ff}
#FFIELD
ffield			      ${_ForceField}
use_nonstd_ff     n                     #options: y,n

#GROMACS VARIABLE
complex	          complex
receptor          receptor
ligand            ligand

skip              1                      #options: integer
double_p          n                      #options: y,n
read_vdw_radii    n                      #options: y,n
coulomb			      gmx           	        #options: coul,gmx

#APBS VARIABLE
linearized              ${_linearized}                               #options: y,n (Def: n)
precF                   ${_precF}                               #options: integer 0,1,2,3 (Def: 1)
temp                    300				#(Def: 293)
bcfl                    mdh                             #options: sdh,mdh,focus (Def: mdh)
pdie                    ${_pdie}                               #options: integer, usually between 2 and 20 (Def: 2)

#QUEQUE VARIABLE
cluster                 n                             	#options: y,n
#Q                       ...                           	#necessary only if cluster=y!!
#budget_name
#walltime
mnp                     ${_np}                           	#options: integer

#OUTPUT VARIABLE
pdf                     n                               #options: y,n

# ALANINE SCANNING
cas                     n                               #options: y,n
	" > INPUT.dat

	rm ./*# ./*~ &> /dev/null
	return 0
}

