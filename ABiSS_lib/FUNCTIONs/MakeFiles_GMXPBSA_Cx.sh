#!/bin/bash

echo -e "\t > MakeFiles_GMXPBSA_Cx.sh"


MakeFiles_GMXPBSA () {
# usage: MakeFiles_GMXPBSA

	#Other functions/programs:
	#gromacs

	#GLOBAL VARIABLE USED:
	if ! printenv | grep -q "GROMPP"; then echo "MakeFiles_GMXPBSA ERROR: cannot find GROMPP on printenv"; return 1; fi
	if ! printenv | grep -q "TRJCONV"; then echo "MakeFiles_GMXPBSA ERROR: cannot find TRJCONV on printenv"; return 1; fi
	if ! printenv | grep -q "MAKE_NDX"; then echo "MakeFiles_GMXPBSA ERROR: cannot find MAKE_NDX on printenv"; return 1; fi

	#LOCAL VARIABLES:
	local _StartingGro_FILE=
	local _trjNAME=
	local _tprFILE=
	local _topName=
	local _confNAME=
	local _rootName=
	local _runNumber=
	local _mdp_NAME="$SETUP_PROGRAM_FOLDER/EngComp_ff14*custom*.mdp"
	local _NUMframe="all"
	local _ForceField="1"
	local _mnp="1"
	local _precF="2"
	local _pdie="4"
	local _linearized="n"
	local _ABchains="2"
	local _receptorFRAG="1"
	local _makeNDX_string=
	local _flag=
	local _flag2=
	local _startingFrame="0"
	local _multichain="n"
	local _num_his=
	local _his_string=
	local _merge=
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
		-xtc)			shift; _trjNAME=$1;;			 	    # MD simulation trajectory
		-tpr)			shift; _tprFILE=$1;;				    # MD simulation tpr file
		-top)			shift; _topName=$1;;				    # topology used for the long simulation
		-s)    		shift; _startingFrame=$1;;      # starting frame [ps] for the Energy computation (Deafault=0 -> all the trajectory)
		-r)				shift; _runNumber=$1;;
		-cn)			shift; _confNAME=$1;;
		-rn)			shift; _rootName=$1;;
		-m)				shift; _mdp_NAME=$1;;
		-n)				shift; _NUMframe=$1;;
		-ff)			shift; _ForceField=$1;;
		-mnp)			shift; _mnp=$1;;
		-pF)			shift; _precF=$1;;
		-pd)			shift; _pdie=$1;;
		-ac)			shift; _ABchains=$1;;
		-rf)			shift; _receptorFRAG=$1;;
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
	if ! [ -r "${_StartingGro_FILE}.gro" ] || ! [ -r "${_trjNAME}.xtc" ] || ! [ -r "${_tprFILE}.tpr" ] || ! [ -r "${_topName}.top" ]; then
		fatal 2 "MakeFiles_GMXPBSA ERROR: one of the input file is missing! \nGROfile:${_StartingGro_FILE}.gro TRJfile:${_trjNAME}.xtc TPRfile:${_tprFILE}.tpr TOPfile:${_topName}.top"
	fi

	if [ "${_receptorFRAG}" -gt 1 ]; then
	# This is needed to chenge the pdb file and add TER at the end of every fragment. Not necessary if the fragment change with the chain.
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
				&> make_ndx.temp || { echo " something wrong on MAKE_NDX!! exiting..."; exit; }

	#protein_NAME=`ls *rotein_*.itp`
	#numCHAIN=0
	#for i in `echo $protein_NAME`; do
	#	[[ $i == posre*.itp ]] && continue
	#
	#	((numCHAIN+=1))
	#	protein_ITPname[$numCHAIN]=$i
	#	nameCHAIN[$numCHAIN]=${i##*_}
	#	nameCHAIN[$numCHAIN]=${nameCHAIN%.itp}
		#cp $i ./${_rootName}/receptor_chain${nameCHAIN[$numCHAIN]}.itp
	#done


	# TRJCONV to make starting frame .pdb
	#$(date +%H:%M:%S)
	msg -n "\t\t --running TRJCONV to make first frame .pdb.. "
	echo "0" | $TRJCONV -n index.ndx -f "${_trjNAME}.xtc" -o "${_confNAME}_starting.pdb" -s "${_tprFILE}.tpr" -sep -e 0 		\
  	&> trjconv.temp || { echo " something wrong on TRJCONV!! exiting..."; exit; }
	mv "${_confNAME}_starting0.pdb" "${_confNAME}_starting_protein.pdb"
	echo "DONE";
	# TRJCONV to remove the pbc from the trajectory
	msg -n "\t\t --running TRJCONV to remove the pbc from the trajectory.. "
	echo "0" | $TRJCONV -n index.ndx -f "${_trjNAME}.xtc" -o ./nptMD_nojump.xtc -s "${_tprFILE}.tpr" -pbc nojump -b "${_startingFrame}"		\
  	&>> trjconv.temp || { echo " something wrong on 1st TRJCONV!! exiting..."; exit; }
	echo -e "1\n0" | $TRJCONV -n index.ndx -f ./nptMD_nojump.xtc -o ./"${_rootName}/${_confNAME}_noPBC.xtc" -s "${_tprFILE}.tpr" -pbc mol -center 	\
  	&>> trjconv.temp || { echo " something wrong on 2nd TRJCONV!! exiting..."; exit; }
	echo "DONE";
	# MAKE_NDX for the ligand(ab/mol), receptor(pept/protein), complex
	msg -n "\t\t --running MAKE_NDX to make index with only receptor, ligand and complex.. "
		# the first 2 chain are the antibody chains (ligand), the third chain is the protein (receptor)

	_makeNDX_string="keep 1\nsplitch 0\n"
	_flag=""
	_flag2=""
	# I suppose the receptor comes before the ligand in the pdb file (it doesn't change much anyway)
	if [ "$_receptorFRAG" -gt 1 ]; then
		_flag="1"
		_flag2="del 1\n"
		for i in $(seq 2 "$_receptorFRAG"); do
			_flag="${_flag}|$i"
			_flag2="${_flag2}del 1\n"
			#_makeNDX_string="${_makeNDX_string}"
		done
	else
		_flag="0&1\ndel 1"
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
	echo -e "${_makeNDX_string}" | $MAKE_NDX -f "${_confNAME}_starting_protein.pdb" -o "${_rootName}/index.ndx" \
	  &>> make_ndx.temp || { echo " something wrong on MAKE_NDX!! exiting..."; exit; }
  echo "DONE";

	#if [ "$_ABchains" == "2" ]; then
	#	echo -e "keep 1\nsplitch 0\ndel 0\n0|1\ndel 0\ndel 0\n0|1\nname 0 receptor\nname 1 ligand\nname 2 complex\n\nq\n" | make_ndx -f ${_confNAME}_starting_protein.pdb -o ${_rootName}/index.ndx &> make_ndx.temp || { echo " something wrong on MAKE_NDX!! exiting..."; exit; }
	#elif [ "$_ABchains" == "1" ]; then
	#	echo -e "keep 1\nsplitch 0\ndel 0\n0|1\n\nname 0 receptor\nname 1 ligand\nname 2 complex\n\nq\n" | make_ndx -f ${_confNAME}_starting_protein.pdb -o ${_rootName}/index.ndx &> make_ndx.temp || { echo " something wrong on MAKE_NDX!! exiting..."; exit; }
	#else
	#	fatal 2 "MakeFiles_GMXPBSA ERROR: Something wrong with _ABchains ($_ABchains)!!"
	#fi


	# HEAD to make a temporary new only-protein top
	msg -n "\t\t --using HEAD to make a only-protein top.. "
	head -n -3 "${_topName}.top" > "${_topName}_protein.top"
	echo "DONE"; [ "$debug" == "true" ] && read -r GoAhead
	# GROMPP to make a protein tpr
	msg -n "\t\t --GROMPP to make a protein tpr.. "
	"$GPATH/grompp" -v -f "${_mdp_NAME}" -c "${confNAME}_starting_protein.pdb" -p "${_topName}_protein.top" -o "${_rootName}/${_confNAME}.tpr" -maxwarn "1" \
	  &>> grompp_OP.temp || { echo " something wrong on GROMPP!! exiting..."; exit; }
	echo "DONE"; [ "$debug" == "true" ] && read -r GoAhead

	_his_string=""
	_num_his=$(grep -E -c "(HIS     CA)|(HID     CA)|(HIE     CA)|(HIP     CA)|(HSD     CA)|(HSE     CA)|(HSP     CA)|(CA  HIS)|(CA  HID)|(CA  HIE)|(CA  HIP)|(CA  HSD)|(CA  HSE)|(CA  HSP)" "${confNAME}_starting_protein.pdb")
	for i in $(seq 1 "$_num_his"); do
		_his_string="${_his_string}1\n"
	done
	rm ./*# ./*~ &> /dev/null

	############################ BUILD the INPUT FILE for GMXPBSA #######################################
	echo "
#GENERAL VARIABLES
root      		${_rootName}
multitrj      		n

run			1                               #options: integer
RecoverJobs		y                               #options: y,n
backup			y                               #options: y,n

Cpath   		$CPATH
Apath   		$APATH
Gpath			  $GPATH

name_xtc		${_confNAME}_noPBC
name_tpr		${_confNAME}

multichain		${_multichain}
Histidine		${_his_string}
min			${_minimization}		#perform minimiz before compute the energy
use_tpbcon		${_use_tpbcon}
mergeC			${_mergeC}
mergeR			${_mergeR}
mergeL			${_mergeL}
#protein_alone		possibility to perform DeltaG CAS calculation on a single protein Default n

NO_topol_ff		${_NO_topol_ff}
#FFIELD
ffield			${_ForceField}
use_nonstd_ff           n                               #options: y,n

#GROMACS VARIABLE
complex	                complex
receptor                receptor
ligand                  ligand

skip                    1                               #options: integer
double_p                n                               #options: y,n
read_vdw_radii		n                               #options: y,n
coulomb			gmx              	        #options: coul,gmx

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
mnp                     ${_mnp}                           	#options: integer

#OUTPUT VARIABLE
pdf                     n                               #options: y,n

# ALANINE SCANNING
cas                     n                               #options: y,n
	" > INPUT.dat

}

