#!/bin/bash

echo -e "\t > MakePOSRES_protein.sh"


MakePOSRES_protein () {
# THIS FUNCTIONS MAKES SPECIFIC POSITION RESTRAINT FOR A SPECIFIC FRAGMENT (default->0). IT CAN ADD THE POSRES KEYWORD WITH THE POSRES TO THE END OF A SPECIFIC .itp FILE
#e.g. -> MakePOSRES_protein -pf "system_EM3.gro" -of "posres_abiss" -tf "topol_Protein_chain_A" -cn "0" -pr "36 37 38 76 77 78 151 152 153 193 194 195" -fc "300 300 400"

	#Other functions/programs:
	#gromacs tools (checked on global variables)
	[[ -x $VMD ]] || { echo "MakeFiles_GMXPBSA ERROR: cannot find vmd($VMD)"; return 1; }

	#GLOBAL VARIABLE USED:
	if ! printenv | grep -q "VMD"; then echo "MakeFiles_GMXPBSA ERROR: cannot find GROMPP on printenv"; return 1; fi
	if ! printenv | grep -q "GENRESTR"; then echo "MakeFiles_GMXPBSA ERROR: cannot find GROMPP on printenv"; return 1; fi
	if ! printenv | grep -q "MAKE_NDX"; then echo "MakeFiles_GMXPBSA ERROR: cannot find GROMPP on printenv"; return 1; fi

	#LOCAL VARIABLES:
	#local _protein_InfileNAME=
	local _posres_OutFileNAME="proteinFile_pdb2gmx"
	#local _lineDummy=
	local _itpFileNAME=
	local _fragmentNUMBER="0"
	local _forceConstants="200 200 400"
	local _posresRESIDUES=
	local _posres_res_type="2"
	local _posres_string=
	local _protein_InFileNAME=
	local _protein_InFileNAME_noext=
	local _posresNAME=
#	echo "############################ MakePOSRES_protein () ###############################" &>> VMDsinglechain.out
	echo "############################ MakePOSRES_protein () ###############################" &>> MakePOSRES.out
#	echo "############################ MakePOSRES_protein () ###############################" &>> genrestr.out


	while [ $# -gt 0 ]
	do
	    case "$1" in
		-of)	shift; _posres_OutFileNAME=$1;;		#no extention
		-pf)	shift; _protein_InFileNAME=$1;;
		-tf)	shift; _itpFileNAME=$1;;		#no extention
		-fn)	shift; _fragmentNUMBER=$1;;
		-pr)	shift; _posresRESIDUES=$1;;
    -prt) shift; _posres_res_type=$1;;
		-fc)	shift; _forceConstants=$1;;
		*)	fatal 1 "MakePOSRES_protein () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done

	_protein_InFileNAME_noext=${_protein_InFileNAME%.*}
	echo -e "$(date +%H:%M:%S)\n  INPUT protein->$_protein_InFileNAME \n INPUT protein noext->$_protein_InFileNAME_noext \n itpFileNAME->$_itpFileNAME
		 \r fragmentNUMBER->$_fragmentNUMBER \n posresRESIDUES->$_posresRESIDUES"  >> MakePOSRES.out

	echo -e > ${TEMP_FILES_FOLDER}/VMDsinglechain.temp "
	mol new $_protein_InFileNAME waitfor all
	set Sel [atomselect top \"fragment $_fragmentNUMBER\"]
	\$Sel writepdb Single${_protein_InFileNAME_noext}.pdb
	\$Sel delete
	exit"
	$VMD -dispdev none -e ${TEMP_FILES_FOLDER}/VMDsinglechain.temp &>> MakePOSRES.out

	[ -r "Single${_protein_InFileNAME_noext}.pdb" ] || { fatal 99 "MakePOSRES_protein () ERROR: cannot read the file Single${_protein_InFileNAME_noext}.pdb. Check ${PWD}/MakePOSRES.out"; }

	# make_ndx normal list -> 0 System | 1 Protein | 2 Protein-H | 3 C-alpha | 4 Backbone | 5 MainChain | 6 MainChain+Cb | 7 MainChain+H | 8 SideChain | 9 SideChain-H
	case "${_posresRESIDUES}" in
	# 0 System      1 Protein     2 Protein-H   3 C-alpha     4 Backbone
		Backbone)	_posres_string="keep 4\n\nq\n"; _posresNAME="POSRES_BB";;
		C-alpha)	_posres_string="keep 3\n\nq\n"; _posresNAME="POSRES_Ca";;
		Protein-H)	_posres_string="keep 2\n\nq\n"; _posresNAME="POSRES_P-H";;
		All)		_posres_string="keep 0\n\nq\n"; _posresNAME="POSRES_All";;
		*)		_posres_string="keep ${_posres_res_type}\nr ${_posresRESIDUES}\n0&1\nkeep 2\n\nq\n"; _posresNAME="POSRES_abiss";;
	esac
	#for i in `seq 1 $_num_his`; do
	#	_posres_string="${_posres_string}1\n"
	#done
	echo -e "posresNAME:${_posresNAME}\nposres_string: ${_posres_string}\n\n" &>> MakePOSRES.out
	echo -e "${_posres_string}" | $MAKE_NDX -f "Single${_protein_InFileNAME_noext}.pdb" -o index_posres.ndx	&>> MakePOSRES.out || { echo "something wrong with make_ndx!!";exit; }
	echo -e "0\n" | $GENRESTR -f "Single${_protein_InFileNAME_noext}.pdb" -n index_posres.ndx -o "${_posres_OutFileNAME}.itp" -fc ${_forceConstants}	&>> MakePOSRES.out || { echo "something wrong with genrestr!!!";exit; }

	# there is a proble/bug with the name of the starting file that is reported on the first line with simbols and may go to new line without be commented
	tail -n +3 "${_posres_OutFileNAME}.itp" > flag.itp
	mv flag.itp "${_posres_OutFileNAME}.itp"

	if [ "${_itpFileNAME}" != "" ]; then
		for ITPname in $_itpFileNAME; do
			echo -e "\n
			\n; Include Position restraint file\
			\n#ifdef ${_posresNAME}\
			\n#include \"${_posres_OutFileNAME}.itp\"\
			\n#endif
			" >> "${ITPname}.itp"
		done
	fi

}