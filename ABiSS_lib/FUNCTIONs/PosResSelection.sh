#!/bin/bash

echo -e "\t > PosResSelection and MakePOSRES_protein.sh"

# This function is adhoc! it must be checked and changed depending on the system and the conditions of simulation
# shellcheck disable=SC2154
function PosResSelection {
# PosResSelection SystemName(Cx, CXCR2, Covid)
  local _system_name=
  local _protein_InFileNAME="system.gro"
  local _md_posres=$POSRES
  local _md_posres_residues=$POSRES_RESIDUES

  while [ $# -gt 0 ]
	do
	    case "$1" in
	  -s)   shift; _system_name=$1;;
		-pf)	shift; _protein_InFileNAME=$1;;
    -mdp) shift; _md_posres=$1;;
    -mdp) shift; _md_posres_residues=$1;;
#		-of)	shift; _posres_OutFileNAME=$1;;		#no extention
#		-tf)	shift; _itpFileNAME=$1;;		      #no extention
#		-fn)	shift; _fragmentNUMBER=$1;;
#		-pr)	shift; _posresRESIDUES=$1;;
#		-fc)	shift; _forceConstants=$1;;
		*)	fatal 1 "PosResSelection () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done

	case "${_system_name}" in
  # NOTE: The Antibody (Ligand) is always supposed to be AFTER the Target (Receptor)
		Cx)
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chA" -tf "topol_Protein_chain_A" -fn  "0 1"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chB" -tf "topol_Protein_chain_B" -fn  "2 3"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chC" -tf "topol_Protein_chain_C" -fn  "4 5"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chD" -tf "topol_Protein_chain_D" -fn  "6 7"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chE" -tf "topol_Protein_chain_E" -fn  "8 9"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chF" -tf "topol_Protein_chain_F" -fn "10 11" \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chH" -tf "topol_Protein_chain_H" -fn   "12"  \
			  -pr "Backbone" -fc "800 800 800"
			if [ "${_md_posres}" != "" ]; then
				msg -pn "PosResSelection.sh" "$(date +%H:%M:%S) --building adhoc POSITION RESTRAINT ($_system_name).. " | tee -a "$LOGFILENAME"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_A" -tf "topol_Protein_chain_A" -fn  "0 1"  \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_B" -tf "topol_Protein_chain_B" -fn  "2 3"  \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_C" -tf "topol_Protein_chain_C" -fn  "4 5"  \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_D" -tf "topol_Protein_chain_D" -fn  "6 7"  \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_E" -tf "topol_Protein_chain_E" -fn  "8 9"  \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_F" -tf "topol_Protein_chain_F" -fn "10 11" \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
#				echo "DONE" | tee -a "$LOGFILENAME";
			fi
			;;
	  Cx43)
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chA" -tf "topol_Protein_chain_A" -fn  "0 1"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chB" -tf "topol_Protein_chain_B" -fn  "2 3"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chC" -tf "topol_Protein_chain_C" -fn  "4 5"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chD" -tf "topol_Protein_chain_D" -fn  "6 7"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chE" -tf "topol_Protein_chain_E" -fn  "8 9"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chF" -tf "topol_Protein_chain_F" -fn "10 11" \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chH" -tf "topol_Protein_chain_H" -fn   "12"  \
			  -pr "Backbone" -fc "800 800 800"
			if [ "${_md_posres}" != "" ]; then
				msg -pn "PosResSelection.sh" "$(date +%H:%M:%S) --building adhoc POSITION RESTRAINT ($_system_name).. " | tee -a "$LOGFILENAME"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_A" -tf "topol_Protein_chain_A" -fn  "0 1"  \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_B" -tf "topol_Protein_chain_B" -fn  "2 3"  \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_C" -tf "topol_Protein_chain_C" -fn  "4 5"  \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_D" -tf "topol_Protein_chain_D" -fn  "6 7"  \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_E" -tf "topol_Protein_chain_E" -fn  "8 9"  \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_F" -tf "topol_Protein_chain_F" -fn "10 11" \
				  -pr "${_md_posres_residues}" -fc "300 300 400"
#				echo "DONE" | tee -a "$LOGFILENAME";
			fi
			;;
		CXCR2)
		  _md_posres_residues="3-222"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chB" -tf "topol_Protein_chain_B" -fn  "0"  \
			  -pr "Backbone" -fc "200 200 200"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chH" -tf "topol_Protein_chain_H" -fn  "1"  \
			  -pr "Backbone" -fc "200 200 200"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chL" -tf "topol_Protein_chain_L" -fn  "2"  \
			  -pr "Backbone" -fc "200 200 200"
			if [ "${_md_posres}" != "" ]; then
				msg -pn "PosResSelection.sh" "$(date +%H:%M:%S) --building adhoc POSITION RESTRAINT ($_system_name).. " | tee -a "$LOGFILENAME"
				# NOT USED WITH CXCR2
        MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_Ca_chH" -tf "topol_Protein_chain_H" -fn  "1"  \
				  -pr "${_md_posres_residues}" -prt "4" -fc "200 200 200"
        MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_Ca_chL" -tf "topol_Protein_chain_L" -fn  "2"  \
				  -pr "${_md_posres_residues}" -prt "4" -fc "200 200 200"
#				echo "DONE" | tee -a "$LOGFILENAME";
			fi
			;;
		Covid-A)
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chS" -tf "topol_Protein_chain_S" -fn  "0"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chA" -tf "topol_Protein_chain_A" -fn  "1"  \
			  -pr "Backbone" -fc "800 800 800"
			if [ "${_md_posres}" != "" ]; then
				msg -pn "PosResSelection.sh" "$(date +%H:%M:%S) --building adhoc POSITION RESTRAINT ($_system_name).. " | tee -a "$LOGFILENAME"
				# NOT USED
				fatal 1 "Function not implemented for this system!!"
#				echo "DONE" | tee -a "$LOGFILENAME";
			fi
			;;
		Covid-H)
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chS" -tf "topol_Protein_chain_S" -fn  "0"  \
			  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chH" -tf "topol_Protein_chain_H" -fn  "1"  \
			  -pr "Backbone" -fc "800 800 800"
			if [ "${_md_posres}" != "" ]; then
				msg -pn "PosResSelection.sh" "$(date +%H:%M:%S) --building adhoc POSITION RESTRAINT ($_system_name).. " | tee -a "$LOGFILENAME"
				# NOT USED
				fatal 1 "function not implemented for this system!!"
#				echo "DONE" | tee -a "$LOGFILENAME";
			fi
			;;
	  HLA_biAB)
	    MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chP" -tf "topol_Protein_chain_P" -fn  "0"  \
	      -pr "Backbone" -fc "200 200 200"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chA" -tf "topol_Protein_chain_A" -fn  "1"  \
			  -pr "Backbone" -fc "200 200 200"
	    MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chH" -tf "topol_Protein_chain_H" -fn  "2"  \
	      -pr "Backbone" -fc "200 200 200"
			MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_BB_chL" -tf "topol_Protein_chain_L" -fn  "3"  \
			  -pr "Backbone" -fc "200 200 200"
			if [ "${_md_posres}" != "" ]; then
				msg -pn "PosResSelection.sh" "$(date +%H:%M:%S) --building adhoc POSITION RESTRAINT ($_system_name).. " | tee -a "$LOGFILENAME"
#				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_P" -tf "topol_Protein_chain_P" -fn  "0"  \
#				  -pr "1-9" -prt "4" -fc "200 200 200"
				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_A" -tf "topol_Protein_chain_A" -fn  "1"  \
				  -pr "1-175" -prt "4" -fc "200 200 200"
#				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_H" -tf "topol_Protein_chain_H" -fn  "2"  \
#				  -pr "1-25\nr33-52\nr58-100\nr111-121" -prt "4" -fc "200 200 200"
#				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_L" -tf "topol_Protein_chain_L" -fn  "3"  \
#				  -pr "1-23\nr35-49\nr57-88\nr99-108" -prt "4" -fc "200 200 200"

#				MakePOSRES_protein -pf "${_protein_InFileNAME}" -of "posres_abiss_A" -tf "topol_Protein_chain_A" -fn  "1"  \
#				  -pr "3 4 5 6 7 8 9 24 25 26 27 32 33 34 35 98 99 100 101 102 103 109 110 111 112 113" -prt "4" -fc "200 200 200"
#				echo "DONE" | tee -a "$LOGFILENAME";
			fi
	    ;;
		*)	fatal 5 "PosResSelection ERROR: $1 is not a valid OPTION!\n";;
	esac


}




MakePOSRES_protein () {
# THIS FUNCTIONS MAKES SPECIFIC POSITION RESTRAINT FOR A SPECIFIC FRAGMENT (default->0). IT CAN ADD THE POSRES KEYWORD WITH THE POSRES TO THE END OF A SPECIFIC .itp FILE
#e.g. -> MakePOSRES_protein -pf "system_EM3.gro" -of "posres_abiss" -tf "topol_Protein_chain_A" -cn "0" -pr "36 37 38 76 77 78 151 152 153 193 194 195" -fc "300 300 400"

	#Other functions/programs:
	#gromacs tools (checked on global variables)
	[[ -x $VMD ]] || { echo "MakeFiles_GMXPBSA ERROR: cannot find vmd($VMD)"; return 1; }

	#GLOBAL VARIABLE USED:
#	VMD, GENRESTR, MAKE_NDX
  $GENRESTR -h &> /dev/null || { echo "MakeFiles_GMXPBSA ERROR: cannot find GENRESTR($GENRESTR)"; return 1; }
  $MAKE_NDX -h &> /dev/null || { echo "MakeFiles_GMXPBSA ERROR: cannot find MAKE_NDX($MAKE_NDX)"; return 1; }

	#LOCAL VARIABLES:
	#local _protein_InfileNAME=
	local _posres_OutFileNAME="proteinFile_pdb2gmx"
	#local _lineDummy=
	local _itpFileNAME=
	local _fragmentNUMBER="0"
	local _forceConstants="200 200 400"
	local _posresRESIDUES=
	local _posres_res_type="2"    # Protein-H
	local _posres_string=
	local _protein_InFileNAME=
	local _protein_InFileNAME_noext=
	local _posresNAME=
#	echo "\n\n############################### MakePOSRES_protein () ###############################" &>> VMDsinglechain.out
	echo "\n\n############################### MakePOSRES_protein () ###############################" &>> MakePOSRES.out
#	echo "\n\n############################### MakePOSRES_protein () ###############################" &>> genrestr.out


	while [ $# -gt 0 ]
	do
	    case "$1" in
		-of)	shift; _posres_OutFileNAME=$1;;		#no extention
		-pf)	shift; _protein_InFileNAME=$1;;
		-tf)	shift; _itpFileNAME=$1;;		      #no extention
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
		Backbone)	  _posres_string="keep 4\n\nq\n"; _posresNAME="POSRES_BB";;
		C-alpha)	  _posres_string="keep 3\n\nq\n"; _posresNAME="POSRES_Ca";;
		Protein-H)	_posres_string="keep 2\n\nq\n"; _posresNAME="POSRES_P-H";;
		All)		    _posres_string="keep 0\n\nq\n"; _posresNAME="POSRES_All";;
		*)		      _posres_string="keep ${_posres_res_type}\nr ${_posresRESIDUES}\n0&1\nkeep 2\n\nq\n";
		            _posresNAME="POSRES_abiss";
		            msg -pn "PosResSelection.sh" "\t ${_itpFileNAME} -> residues: ${_posres_res_type} & ${_posresRESIDUES}";
		            #echo "${_posres_res_type} & ${_posresRESIDUES}"
		            ;;
	esac
	#for i in `seq 1 $_num_his`; do
	#	_posres_string="${_posres_string}1\n"
	#done
	echo -e "\n\nposresNAME:${_posresNAME}\nposres_string: '${_posres_string}'\n\n" &>> MakePOSRES.out
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