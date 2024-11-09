#!/bin/bash

# How to Read a File Line By Line in Bash
# input="/path/to/txt/file"; while IFS= read -r line; do ls -l "$line"; done < "$input"
# How to increment letter variables
# y=b; echo "$y"  # this shows 'b'; y=$(echo "$y" | tr "0-9a-z" "1-9a-z_"); echo "$y"  # this shows 'c' WARNING this is case sensitive!!

echo "LOADED functions.sh"

msg () {
	local _StartingNewLine="0"
	local _StartingName="1"		#0=false 
	local _NewLineEOF="1"
	local _CarriageReturn="0"
	while [ $# -gt 0 ]
	do
		case "$1" in
			-t)	_StartingNewLine="1";;		# use this optio to start with a newline
			-s)	_StartingName="0";;		# use this option to NOT start the line with the header
			-n)	_NewLineEOF="0";;		# use this option to NOT end the line with a newline
			-r)	_CarriageReturn="1";;
			*)	break;;
	    	esac
	    	shift
	done
	[[ $_StartingNewLine == 1 ]] && echo -e -n "\n"
	[[ $_CarriageReturn == 1 ]] && echo -e -n "\r"
	[[ $_StartingName == 1 ]] && echo -e -n "$PN:\t\t"
	echo -e -n "$@"; 
	[[ $_NewLineEOF == 1 ]] && echo -e ""
}

fatal () { 
	err=$1; shift; 
	msg "\n($err) $* (TRY_AGAIN=$TRY_AGAIN ATTEMPTS_NUM=$ATTEMPTS_NUM)" >&2;
	echo "LAST_COMMAND='$LAST_COMMAND'"
	
	if [ "$LAST_COMMAND" != "" ]; then
		[ "$TRY_AGAIN" == "" ] && let TRY_AGAIN=0
		[ "$ATTEMPTS_NUM" == "" ] && let ATTEMPTS_NUM=0
		if [ "$TRY_AGAIN" -lt "$ATTEMPTS_NUM" ]; then
			msg -t "ONE more try!! JiaYou!!"
			let TRY_AGAIN++
			#$LAST_COMMAND
			return 0
		fi
	fi
	exit $err; 
}

Run_GMXtools () {
# usage: Run_GMXtools "answers to the prompts" "GMX tool" "comands" -o _outfile
	
	#Other functions/programs
	#gromacs
	
	#GLOBAS VARIABLES USED:
	#USE_EXPECT
	#EXPECT
	LAST_COMMAND="Run_GMXtools $@"
	
	#LOCAL VARIABLES:
	local _prompt_answers="$1"
	local _GMX_tool="$2"
	local _GMX_tool_commands="$3"
	declare -a _expect_answers=
	local _outfile="expect.out"
	local _exit_value=
	local _errors=
	
	shift;shift;shift
	while [ $# -gt 0 ]
	do
		case "$1" in
			-o)	shift; _outfile="$1";;
			*)	fatal 1 "Run_GMXtools() ERROR: $1 is not a valid OPTION!\n";;
		esac
		shift
	done
	
	if [ "${_prompt_answers}" == "" ]; then
		echo "[\"$USE_EXPECT\" == \"true\"] && [ \"${_prompt_answers}\" == \"\" ]" &>$_outfile
		$_GMX_tool $_GMX_tool_commands 	&>$_outfile || { fatal "$?" " something wrong on $_GMX_tool!! exiting..."; }
	elif [ "$USE_EXPECT" == "true" ] && [ "${_prompt_answers}" != "" ]; then
		#_expect_answers=$( sed -e 's/\\n/\\r/g' <<< $_prompt_answers )
		mapfile -t _expect_answers <<< "$(echo -e "$_prompt_answers")"
		#declare -p _expect_answers
		
		for keys in "${!_expect_answers[@]}"; do _expect_answers[$keys]="{${_expect_answers[$keys]}}"; done
		#declare -p _expect_answers
		
		$EXPECT &>$_outfile <<-EOF
		#exp_internal 1         ;# Use expects debug mode by putting the line "exp_internal 1" at the top of your script.
		set timeout 120
		#log_user 0
		
		set l [list ${_expect_answers[@]}]
		send_user " ${_expect_answers[@]} \n"
		set count 0
		foreach UserCommand \$l {
			set value [ lindex \$UserCommand \$count ]
		        send_user "\$UserCommand (\$count -> \$value)\n"
		        set count [ expr \$count+1 ]
		}
        
		spawn $_GMX_tool $_GMX_tool_commands
		expect "*$_GMX_tool"
		
		if { "$_GMX_tool" == "gmx pdb2gmx" } {
			send_user "SPECIAL->$_GMX_tool \n"
			foreach UserCommand \$l {
				expect {
					"Select the Force Field:" {
						sleep 1
						send -- "\$UserCommand\r"
						send -- "\r"
					}
					"Select the Water Model:" {
						sleep 1
						send -- "\$UserCommand\r"
						send -- "\r"
					}
					"Which HISTIDINE type*" {
						sleep 1
						send -- "\$UserCommand\r"
						send -- "\r"
					}
					"Split the chain*" {
						sleep 1
						send -- "\$UserCommand\r"
						send -- "\r"
					}
					"Merge chain ending*" {
						sleep 1
						send -- "\$UserCommand\r"
						send -- "\r"
					}
		        		eof { send_user "\n\nunexpected expect exit. Exit value:$? \n"; exit 1 }
				}
			}		
		} elseif { "$_GMX_tool" == "gmx make_ndx" } {
			send_user "SPECIAL->$_GMX_tool \n"
			foreach UserCommand \$l {
				expect {
					">" {
						sleep 1
						send -- "\$UserCommand\r"
						send -- "\r"
					}
		        		eof { send_user "\n\nunexpected expect exit. Exit value:$? \n"; exit 1 }
				}
			}			
		} elseif { "$_GMX_tool" == "gmx editconf" } {
			send_user "SPECIAL->$_GMX_tool \n"
			foreach UserCommand \$l {
				expect {
					"Select a group*" {
						sleep 1
						send -- "\$UserCommand\r"
						send -- "\r"
					}
		        		eof { send_user "\n\nunexpected expect exit. Exit value:$? \n"; exit 1 }
				}
			}
		} else {
			foreach UserCommand \$l {
				sleep 4
				send -- "\$UserCommand\r"
				send -- "\r"
			}
		}
		
		expect {
		        timeout { send_user "\nFailed! (timeout) \n"; exit 1 }
		        eof { send_user "\n\nunexpected expect exit. Exit value:$? \n"; exit 1 }
		        "GROMACS reminds you: " { send_user "\n\nexpect DONE \n" }
		        "Abort(*\n" { send_user "\n\nexpect ERROR \n"; exit 1 }
		}
		close
		exit 0
		EOF
		
		#echo -e " after expect. \$? value: $?"
		#_exit_value="$?"
		if [ $? -gt 0 ]; then
			fatal "$?" " something wrong on $_GMX_tool!! Exiting..."
		fi
		_errors=$( grep -v "GROMACS reminds you" $_outfile | egrep -ci "(error)|(abort)|(segmentation fault)" )
		if [ "$_errors" -gt 0 ]; then
			fatal "000$_errors" " something wrong on $_GMX_tool!! Exiting..."
		fi
		
		
	else
		echo "no conditions -> [\"$USE_EXPECT\" == \"true\"] [ \"${_prompt_answers}\" == \"\" ]" &>$_outfile
		echo -e "$_prompt_answers" | $_GMX_tool $_GMX_tool_commands 	&>$_outfile || { fatal "$?" " something wrong on $_GMX_tool!! exiting..."; }
	fi
	
	LAST_COMMAND=""; 
	TRY_AGAIN="0"
}



# Do a small MD or different kind of simulation to find a minimum in the structure with the new amino acid
MutantRearangement () {
# usage: MutantRearangement 

	#Other functions/programs:
	#gromacs
		
	#GLOBAL VARIABLE USED:
	#GROMPP
	#MDRUN
	#LOGFILENAME
	
	#LOCAL VARIABLES:
	local _input_fileNAME=
	local _mode="MDgromacs"
	local _MD_NAME=
	local _MDslow_NAME=
	local _topName="topol.top"
	local _OUTPUTgro=

	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-i)	shift; _input_fileNAME=$1;;
		-m) 	shift; _mode=$1;;
		-md)	shift; _MD_NAME=$1;;
		-mds)	shift; _MDslow_NAME=$1;;
		-t)	shift; _topName=$1;;
		-og)	shift; _OUTPUTgro=$1;;
		*)	fatal 1 "MutantRearangement() ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done	
	
	#TODO add different option and input controll
	if [ $_mode == "MDgromacs" ]; then
		msg -n "$(date +%H:%M:%S) --running 50ps slow MOLECULAR DYNAMICS for MutantRearangement.. " | tee -a $LOGFILENAME
		$GROMPP -f ${_MDslow_NAME} -c ${_input_fileNAME} -p ${_topName} -o system_Compl_MDslow.tpr 						&> output.temp || { echo " something wrong on GROMPP!! exiting..."; exit; }
		$MDRUN -s system_Compl_MDslow.tpr -c groMDslow.gro -v -cpo state_MDslow.cpt								&> output.temp || { echo " something wrong on MDRUN!! exiting..."; exit; }
		echo "DONE" | tee -a $LOGFILENAME; [ $DEBUG == "true" ] && read GoAhead

		msg -n "$(date +%H:%M:%S) --running 200ps MOLECULAR DYNAMICS for MutantRearangement.. " | tee -a $LOGFILENAME
		$GROMPP -f ${_MD_NAME} -c groMDslow.gro -p ${_topName} -o relaxMD.tpr -t state_MDslow.cpt		 				&> output.temp || { echo " something wrong on GROMPP!! exiting..."; exit; }
		$MDRUN -s relaxMD.tpr -c ${_OUTPUTgro}.gro -x relaxMD.xtc -v 										&> mdrun_MD.out || { echo " something wrong on MDRUN!! exiting..."; exit; }
		echo "DONE" | tee -a $LOGFILENAME; [ $DEBUG == "true" ] && read GoAhead
	fi
	
}

Custom_stdAMBER () {
	cp "${ABiSS_lib}/EngComp_AMBER-09-2019_custom.mdp" ${PWD}/SETUP_PROGRAM_FILES
	local _stdAMBER_NAME="${PWD}/SETUP_PROGRAM_FILES/EngComp_AMBER-09-2019_custom.mdp"
	local _leftKEY=
	local _KEYword=
	
	while [ $# -gt 0 ]
	do
	    # KEY words: KEY_define	KEY_nsteps	KEY_nstouts
	    _KEYword=$1
	    _KEYword=${_KEYword#-}
	    grep -c "${_KEYword}" ${_stdAMBER_NAME} > /dev/null || { fatal 1 "The KEY word $1 is not in the $_stdAMBER_NAME file!!"; exit; }
	    sed -i -e "s/${_KEYword}/$2/g" ${_stdAMBER_NAME}
	    
	    shift; shift
	done
	
	sed -n '/KEY_/d' ${_stdAMBER_NAME}
	
}

Custom_mdpFILE () {
# usage: Custom_mdpFILE CustomMDP_FILENAME -KEY_define -DPOSRES
# e.g. Custom_mdpFILE ${LIB_PATH}/${dynamic}_custom.mdp -KEY_nsteps "${NumberSteps[${flag}]}" -KEY_dt "0.002" -KEY_nstdhdl "$nstdhdl" -KEY_calc-lambda-neighbors "$calc_lambda_neighbors" -KEY_fep-lambdas "$fep_lambdas" -KEY_coul-lambdas "$coul_lambdas" -KEY_vdw-lambdas "$vdw_lambdas" -KEY_define "${definePOSRES}" -KEY_sc-coul "yes"

	
	local _KEYvalue=
	local _KEYword=
	local _flag=
	local _mdpFILE=$1
	#echo "Custom_mdpFILE $@"
	shift
	cp ${_mdpFILE} ./
	_flag=${_mdpFILE##*/}
	_mdpFILE="${PWD}/${_flag}"
	
	while [ $# -gt 0 ]
	do
	    # KEY words: KEY_define	KEY_nsteps	KEY_nstouts	KEY_dt	KEY_nstdhdl	KEY_calc-lambda-neighbors	KEY_fep-lambdas	KEY_coul-lambdas	KEY_vdw-lambdas	KEY_sc-coul
	    _KEYword="$1"
	    _KEYvalue="$2"
	    #echo "_KEYword->$_KEYword		_KEYvalue->$_KEYvalue"
	    shift; shift
	    if [ "$_KEYvalue" == "" ]; then
		msg -s -t -n "\t$0 $* \n\tWARNING: The variable associated with KEY word \"${_KEYword}\" is empty (\"${_KEYvalue}\")!!\t\n"
		continue
	    fi
	    _KEYword=${_KEYword#-}
	    grep -c "${_KEYword}" ${_mdpFILE} > /dev/null || { msg -s -t -n "\t$0 $* \n\tWARNING: The KEY word \"${_KEYword}\" is not in the \"${_mdpFILE}\" file!!\t\n"; continue; }
	    sed -i -e "s/${_KEYword}/${_KEYvalue}/g" ${_mdpFILE}
	    if [ "${_KEYword}" == "KEY_define" ]; then 
		sed -i -e "s/KEY_refcoord_scaling/all/g" ${_mdpFILE}		# if I use position restraint, set the reference coordinates to be scaled with the scaling matrix of the pressure coupling.
		sed -i -e "s/KEY_comm-mode/None/g" ${_mdpFILE}
	    fi
	    
	done
	
	sed -i -e "s/KEY_comm-mode/Linear/g" ${_mdpFILE}
	sed -i '/KEY_/d' ${_mdpFILE}
	
}

# keep all the informations of the original PDB and change only the coordinates (taking them from a gro file)
GROtoPDB_andFIXER () {
	local _startingPDB=
	local _coordinatesGRO=
	local _OUTPUTpdb=
	local _editconf="$EDITCONF"
	local _make_ndx="$MAKE_NDX"
	local _stringCOORD=
	local _stringSTART=

	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-s)	shift; _startingPDB=$1;;
		-c) 	shift; _coordinatesGRO=$1;;
		-op)	shift; _OUTPUTpdb=$1;;
		-e) 	shift; _editconf=$1;;
		-n) 	shift; _make_ndx=$1;;
		*)	fatal 1 "GROtoPDB_andFIXER() ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done	
	
	msg -n "$(date +%H:%M:%S) --creating a new starting pdb.. " | tee -a $LOGFILENAME
	Run_GMXtools "keep 1\n\nq\n" "$_make_ndx" "-f ${_coordinatesGRO} -o index_PRO.ndx" -o "make_ndx.out"
	${_editconf} -f ${_coordinatesGRO} -n index_PRO.ndx -o coordinates_temp.pdb		&>> editconf.out || { echo " something wrong on editconf!! exiting..."; exit; }
	grep "^ATOM" coordinates_temp.pdb > coordinates_temp_atoms.pdb
	grep "^ATOM" ${_startingPDB} > starting_temp_atoms.pdb
	
	cut -b 1-20 coordinates_temp_atoms.pdb > fileCOORD.temp
	cut -b 1-20 starting_temp_atoms.pdb > fileSTART.temp
	#`diff -q -w -y fileSTART.temp fileCOORD.temp`
	for i in $( seq 1 $( cat fileSTART.temp | wc -l ) ); do
		_stringCOORD=$( echo $( head -n $i fileCOORD.temp | tail -n 1 ) )
		_stringSTART=$( echo $( head -n $i fileSTART.temp | tail -n 1 ) )
		if [ "$_stringCOORD" != "$_stringSTART" ]; then
			fatal 2 "GROtoPDB_andFIXER() ERROR: THERE ARE DIFFERENCES IN THE FILES!!!! CHECK LINE $i\n"
		fi
	done
	
	cut -b 21-31 starting_temp_atoms.pdb > fileSTART_part2.temp
	cut -b 32-66 coordinates_temp_atoms.pdb > fileCOORD_part3.temp
	cut -b 67- starting_temp_atoms.pdb > fileSTART_part4.temp
	
	paste -d "" fileSTART.temp fileSTART_part2.temp fileCOORD_part3.temp fileSTART_part4.temp > ${_OUTPUTpdb}.pdb
	rm fileCOORD*.temp fileSTART*.temp coordinates_temp*.pdb starting_temp*.pdb
	echo "DONE" | tee -a $LOGFILENAME; [ $DEBUG == "true" ] && read GoAhead
	
}

MakePDB_fromComplexToMolProt () {
# usage: MakePDB_fromComplexToMolProt
#

	#Other functions/programs:
	#gromacs
		
	#GLOBAL VARIABLE USED:
	#EDITCONF
	#LOGFILENAME
	
	#LOCAL VARIABLES:
	local _input_fileNAME=
	local _path_input="."
	local _molecule_OutfileNAME=
	local _molecule_ndxNAME="MOL"
	local _protein_OutfileNAME=
	echo "############################ MakePDB_fromComplexToMolProt () ###############################" &>> make_ndx.out
	echo "############################ MakePDB_fromComplexToMolProt () ###############################" &>> editconf.out
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-pi)	shift; _path_input=$1;;
		-fi) 	shift; _input_fileNAME=$1;;
		-mf)	shift; _molecule_OutFileNAME=$1;;
		-mn)	shift; _molecule_ndxNAME=$1;;
		-pf)	shift; _protein_OutfileNAME=$1;;
		*)	fatal 1 "MakePDB_startingFiles () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done	
	
	[[ `cut -b 18-20 ${_path_input}/${_input_fileNAME} | grep "$_molecule_ndxNAME" | wc -l` == 0 ]] && { echo "MakePDB_fromComplexToMolProt: cannot find the molecule name $_molecule_ndxNAME!! exiting..."; exit; }
	
	Run_GMXtools "keep 1\nr $_molecule_ndxNAME\n0|1\n\nq\n" "$MAKE_NDX" "-f ${_path_input}/${_input_fileNAME} -o index_temp.ndx" -o "make_ndx.out"
	Run_GMXtools "0\n" "$EDITCONF" "-f ${_path_input}/${_input_fileNAME} -n index_temp.ndx -o ${_protein_OutfileNAME}.pdb" -o "editconf.out"
	Run_GMXtools "1\n" "$EDITCONF" "-f ${_path_input}/${_input_fileNAME} -n index_temp.ndx -o ${_molecule_OutFileNAME}.pdb" -o "editconf.out"
	Run_GMXtools "2\n" "$EDITCONF" "-f ${_path_input}/${_input_fileNAME} -n index_temp.ndx -o ${_input_fileNAME}" -o "editconf.out"

	rm *temp* &> /dev/null

}

MakeTOP_protein () {
# THIS FUNCTION MAKES THE TOPOLOGY FILES ( .top .itp ) FROM THE INPUT FILE
# TODO change the adhoc option on the -merge
	local _protein_InfileNAME=
	local _protein_OutFileNAME="proteinFile_pdb2gmx"
	local _ForceFielf_number=
	local _num_his=
	local _pdb2gmx_string=
	local _lineDummy=
	local _topFileNAME="topol"
	local _ABchains="2"
	local _receptorFRAG="1"
	local _merge=""
	local _mergeSTRING="y\nn\n"
	echo "############################ MakeTOP_protein () ###############################" &>> pdb2gmx.out
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-of)	shift; _protein_OutFileNAME=$1;;
		-ff)	shift; _ForceFielf_number=$1;;
		-pf)	shift; _protein_InFileNAME=$1;;
		-tf)	shift; _topFileNAME=$1;;
		-ac)	shift; _ABchains=$1;;			# NOT USED
		-rf)	shift; _receptorFRAG=$1;;		# NOT USED
		-merge)	shift; _merge="-merge interactive"; _mergeSTRING=$1;;
		*)	fatal 1 "MakePDB_startingFiles () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done	
	
	#egrep "(^ATOM)|(^HETATM)" ${_protein_InFileNAME}.pdb > dummy_temp.pdb
	#echo "TER
#ATOM    650  N   GLY Z   1      53.800  27.720  48.110  0.00  0.00            
#ATOM    651  H   GLY Z   1      52.120  27.070  47.470  0.00  0.00            
#ATOM    652  CA  GLY Z   1      51.040  27.170  49.310  0.00  0.00            
#ATOM    653  HA1 GLY Z   1      50.750  26.140  49.100  0.00  0.00            
#ATOM    654  HA2 GLY Z   1      50.140  27.740  49.510  0.00  0.00            
#ATOM    655  C   GLY Z   1      51.870  27.150  50.610  0.00  0.00            
#ATOM    656  O   GLY Z   1      51.360  26.730  51.640  0.00  0.00     
#ATOM    650  N   GLY Z   2      51.750  27.720  48.110  0.00  0.00            
#ATOM    651  H   GLY Z   2      52.120  27.070  47.470  0.00  0.00            
#ATOM    652  CA  GLY Z   2      51.040  27.170  49.310  0.00  0.00            
#ATOM    653  HA1 GLY Z   2      50.750  26.140  49.100  0.00  0.00            
#ATOM    654  HA2 GLY Z   2      50.140  27.740  49.510  0.00  0.00            
#ATOM    655  C   GLY Z   2      51.870  27.150  50.610  0.00  0.00            
#ATOM    656  O   GLY Z   2      51.360  26.730  51.640  0.00  0.00      
#END" >> dummy_temp.pdb
	
	_protein_OutFileNAME=${_protein_OutFileNAME%.*}
	
	cat ./${_protein_InFileNAME}.pdb > test.temp
	_num_his=$(egrep -c "(HIS     CA)|(HID     CA)|(HIE     CA)|(HIP     CA)|(HSD     CA)|(HSE     CA)|(HSP     CA)|(CA  HIS)|(CA  HID)|(CA  HIE)|(CA  HIP)|(CA  HSD)|(CA  HSE)|(CA  HSP)" ./${_protein_InFileNAME}.pdb)
	_pdb2gmx_string="${_ForceFielf_number}\n1\n"
	if [ "${_merge}" == "-merge interactive" ]; then
		_pdb2gmx_string="${_pdb2gmx_string}${_mergeSTRING}"
		# y\nn\ny\nn\ny\nn\ny\nn\ny\nn\ny\nn\n
	fi
	for i in `seq 1 $_num_his`; do
		_pdb2gmx_string="${_pdb2gmx_string}1\n"
	done
	echo -e "(egrep \"(HIS     CA)|(HID     CA)|(HIE     CA)|(HIP     CA)|(HSD     CA)|(HSE     CA)|(HSP     CA)|(CA  HIS)|(CA  HID)|(CA  HIE)|(CA  HIP)|(CA  HSD)|(CA  HSE)|(CA  HSP)\" ${_protein_InFileNAME}.pdb )" &> pdb2gmx.out
	echo -e "num hist: ${_num_his} \npdb2gmx_string:\n${_pdb2gmx_string}\n\n" &>> pdb2gmx.out
	#sed -i_OLD '/OC2/a\TER' ${_protein_InFileNAME}.pdb
	Run_GMXtools "${_pdb2gmx_string}" "$PDB2GMX" "-f ${_protein_InFileNAME}.pdb -o ${_protein_InFileNAME}_temp.pdb -p $_topFileNAME.top -ignh -his ${_merge}" -o "pdb2gmx.out"
	
	#_lineDummy=$( echo "x=`sed -n '/N    GLY Z   1      53.800/=' ${_protein_InFileNAME}_temp.pdb`-1; print x;" | bc -l )
	#head -n ${_lineDummy} ${_protein_InFileNAME}_temp.pdb > ${_protein_OutFileNAME}.pdb
	cp ${_protein_InFileNAME}_temp.pdb system.pdb
	rm *_temp.pdb *_Z.itp &> /dev/null
	
	# CREATE THE BOX ( deafult -> -bt triclinic -d 1.5 )
	$EDITCONF -f system.pdb $editconf_opt -o ${_protein_OutFileNAME}.gro 					&> output.temp || { echo " something wrong on EDITCONF!! exiting..."; exit; }
	
}

MakePOSRES_protein () {
# THIS FUNCTIONS MAKES SPECIFIC POSITION RESTRAINT FOR A SPECIFIC FRAGMENT (default->0). IT CAN ADD THE POSRES KEYWORD WITH THE POSRES TO THE END OF A SPECIFIC .itp FILE
#e.g. -> MakePOSRES_protein -pf "system_EM3.gro" -of "posres_abiss" -tf "topol_Protein_chain_A" -cn "0" -pr "36 37 38 76 77 78 151 152 153 193 194 195" -fc "300 300 400"

	#Other functions/programs:
	#gromacs
	#vmd
		
	#GLOBAL VARIABLE USED:
	#VMD
	#GENRESTR
	#MAKE_NDX
	#LOGFILENAME
	
	#LOCAL VARIABLES:
	local _protein_InfileNAME=
	local _posres_OutFileNAME="proteinFile_pdb2gmx"
	local _lineDummy=
	local _itpFileNAME=
	local _fragmentNUMBER="0"
	local _forceConstants="200 200 400"
	local _posresRESIDUES=
	local _posres_string=
	local _protein_InFileNAME=
	local _protein_InFileNAME_noext=
	local _posresNAME=
	echo "############################ MakePOSRES_protein () ###############################" &>> VMDsinglechain.out
	echo "############################ MakePOSRES_protein () ###############################" &>> makePOSRES_ndx.out
	echo "############################ MakePOSRES_protein () ###############################" &>> genrestr.out
	
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-of)	shift; _posres_OutFileNAME=$1;;		#no extention
		-pf)	shift; _protein_InFileNAME=$1;;
		-tf)	shift; _itpFileNAME=$1;;		#no extention
		-fn)	shift; _fragmentNUMBER=$1;;
		-pr)	shift; _posresRESIDUES=$1;;
		-fc)	shift; _forceConstants=$1;;
		*)	fatal 1 "MakePOSRES_protein () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	
	_protein_InFileNAME_noext=${_protein_InFileNAME%.*}
	echo -e "$(date +%H:%M:%S)\n  INPUT protein->$_protein_InFileNAME \n INPUT protein noext->$_protein_InFileNAME_noext \n itpFileNAME->$_itpFileNAME 
		 \r fragmentNUMBER->$_fragmentNUMBER \n posresRESIDUES->$_posresRESIDUES"  >> MakePOSRES_protein.out
	
	echo -e > tempFILES/VMDsinglechain.temp "
	mol new $_protein_InFileNAME waitfor all
	set Sel [atomselect top \"fragment $_fragmentNUMBER\"]
	\$Sel writepdb Single_${_protein_InFileNAME_noext}_{$_fragmentNUMBER}.pdb
	\$Sel delete
	exit"
	$VMD -dispdev none -e tempFILES/VMDsinglechain.temp &>> VMDsinglechain.out
	
	[ -r "Single_${_protein_InFileNAME_noext}_{$_fragmentNUMBER}.pdb" ] || { fatal 99 "MakePOSRES_protein () ERROR: cannot read the file Single_${_protein_InFileNAME_noext}_{$_fragmentNUMBER}.pdb. Check ${PWD}/VMDsinglechain.out"; }
	
	# make_ndx normal list -> 0 System | 1 Protein | 2 Protein-H | 3 C-alpha | 4 Backbone | 5 MainChain | 6 MainChain+Cb | 7 MainChain+H | 8 SideChain | 9 SideChain-H
	case "${_posresRESIDUES}" in
		Backbone)	_posres_string="keep 4\n\nq\n"; _posresNAME="POSRES_BB";;
		C-alpha)	_posres_string="keep 3\n\nq\n"; _posresNAME="POSRES_Ca";;
		Protein-H)	_posres_string="keep 2\n\nq\n"; _posresNAME="POSRES_P-H";;
		All)		_posres_string="keep 0\n\nq\n"; _posresNAME="POSRES_All";;
		*)		_posres_string="keep 2\nr ${_posresRESIDUES}\n0&1\nkeep 2\n\nq\n"; _posresNAME="POSRES_abiss";;
	esac
	#for i in `seq 1 $_num_his`; do
	#	_posres_string="${_posres_string}1\n"
	#done
	echo -e "posresNAME:${_posresNAME}\nposres_string: ${_posres_string}\n\n" &>> makePOSRES_ndx.out
	Run_GMXtools "${_posres_string}" "$MAKE_NDX" "-f Single_${_protein_InFileNAME_noext}_{$_fragmentNUMBER}.pdb -o index_posres.ndx" -o "makePOSRES_ndx.out"
	Run_GMXtools "0\n" "$GENRESTR" "-f Single_${_protein_InFileNAME_noext}_{$_fragmentNUMBER}.pdb -n index_posres.ndx -o ${_posres_OutFileNAME}.itp -fc ${_forceConstants}" -o "genrestr.out"
	
	# there is a proble/bug with the name of the starting file that is reported on the first line with simbols and may go to new line without be commented
	tail -n +3 ${_posres_OutFileNAME}.itp > flag.itp
	mv flag.itp ${_posres_OutFileNAME}.itp
	
	if [ "${_itpFileNAME}" != "" ]; then
		for ITPname in $_itpFileNAME; do
			echo -e "\n
			\n; Include Position restraint file\
			\n#ifdef ${_posresNAME}\
			\n#include \"${_posres_OutFileNAME}.itp\"\
			\n#endif
			" >> ${ITPname}.itp
		done
	fi
	
}

Make_BoxOfWater () {
# usage: Make_BoxOfWater 

	#Other functions/programs:
	#gromacs
		
	#GLOBAL VARIABLE USED:
	#GROMPP
	#GENBOX
	#GENION
	#MAKE_NDX
	#LOGFILENAME
	
	#LOCAL VARIABLES:
	local _InSysFile=
	local _OutFileNAME="system_ions"
	local _InTopFile="topol"
	local _gromppOutput="grompp.out"
	
	local _ChargeValue=
	local _WaterMolecules=
	local _IonsNumber=
	local _KNumber=
	local _ClNumber=
	local _flag=

	while [ $# -gt 0 ]
	do
	    case "$1" in
		-of)	shift; _OutFileNAME=$1;;
		-tf)	shift; _InTopFile=$1;;
		-sf)	shift; _InSysFile=$1;;
		-go)	shift; _gromppOutput=$1;;
		*)	fatal 1 "MakePDB_startingFiles () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done	
	
	
	$GENBOX -cp $_InSysFile.gro -cs spc216.gro -o system_water_temp.gro -p $_InTopFile.top			&> genbox.out || { echo " something wrong on GENBOX!! exiting..."; exit; }

	# COMPUTE THE NUMBER OF IONS NEEDED IN THE BOX
	_flag=`grep "System has non-zero total charge" $_gromppOutput`
	if [ "$_flag" == "" ]; then
		_ChargeValue="0"
	else
		_ChargeValue=$( gawk '/System has non-zero total charge/ {  x=$NF+0.5; printf "%2i", x  }' $_gromppOutput )
	fi
	_WaterMolecules=$( gawk '$1 ~ /SOL/ { print $NF }' $_InTopFile.top )
	_IonsNumber=$( echo "scale=4; x=$_WaterMolecules*0.00271; print x;" | bc -l );		# 150nM of solt

	_KNumber=$( echo "scale=0; x=(0.5+$_WaterMolecules*0.00271)/1; print x;" | bc -l );
	_ClNumber=$( echo "scale=0; x=(0.5+$_ChargeValue+$_WaterMolecules*0.00271)/1; print x;" | bc -l );

	#echo -e "\nChargeValue->$_ChargeValue   WaterMolecules->$_WaterMolecules   IonsNumber->$_IonsNumber   KNumber->$_KNumber   ClNumber->$_ClNumber"
	Run_GMXtools "keep 0\nr SOL\nkeep 1\n\nq\n" "$MAKE_NDX" "-f system_water_temp.gro -o index_SOL_temp.ndx" -o "make_ndx.out"
	$GROMPP -f minim.mdp -c system_water_temp.gro -p $_InTopFile.top -o system_ions_temp.tpr		&> output.temp || { echo " something wrong on GROMPP!! exiting..."; exit; }
	Run_GMXtools "0\n" "$GENION -s system_ions_temp.tpr -n index_SOL_temp.ndx -o $_OutFileNAME.gro -p $_InTopFile.top -nn ${_ClNumber} -nname CL -np ${_KNumber} -pname K" -o "output.temp"
	
	rm system_water_temp.gro index_SOL_temp.ndx system_ions_temp.tpr
}


AvgANDStd () {
	local _AllData="AllData.out"
	local _DeltaG=
	local _Coul=
	local _vdW=
	local _PolSol=
	local _NpoSol=
	local _ScoreFunct=
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-if)	shift; _AllData=$1;;
		*)	fatal 1 "AvgANDStd () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done	

	#msg -n "Runnig AvgANDStd..."
	grep -v "^#" $_AllData | gawk '
		BEGIN { 
			DeltaG     = 0
			Coul       = 0
			vdW        = 0
			PolSol     = 0
			NpoSol     = 0
			Population = 0
			ScoreFunct = 0
		} 
		{ 
			Population = Population + 1
			DeltaG     = DeltaG + $3
			Coul       = Coul   + $4
			vdW        = vdW    + $5
			PolSol     = PolSol + $6
			NpoSol     = NpoSol + $7
			ScoreFunct = $4/10 - $6/10 + $7*10 +150
		}
		END { 
			DeltaG     = DeltaG / Population
			Coul       = Coul   / Population
			vdW        = vdW    / Population
			PolSol     = PolSol / Population
			NpoSol     = NpoSol / Population
			ScoreFunct = Coul/10 - PolSol/10 + NpoSol*10 +150
			printf "%-10s \t%9.3f \t%9.3f \t%9.3f \t%9.3f \t%9.3f \t\t%9.3f \n", "#Average", DeltaG, Coul, vdW, PolSol, NpoSol, ScoreFunct
		} 
	'  > AllData.temp
	
	_DeltaG=$( tail -n 1 AllData.temp | cut -f 2 )
	_Coul=$( tail -n 1 AllData.temp | cut -f 3 )
	_vdW=$( tail -n 1 AllData.temp | cut -f 4 )
	_PolSol=$( tail -n 1 AllData.temp | cut -f 5 )
	_NpoSol=$( tail -n 1 AllData.temp | cut -f 6 )
	_ScoreFunct=$( tail -n 1 AllData.temp | cut -f 8 )
	
	grep -v "^#" $_AllData | gawk -v DeltaG="${_DeltaG}" -v Coul="${_Coul}" -v vdW="${_vdW}" -v PolSol="${_PolSol}" -v NpoSol="${_NpoSol}" -v ScoreFunct="${_ScoreFunct}" '
		BEGIN { 
			Population = 0
			STD_DeltaG     = 0
			STD_Coul       = 0
			STD_vdW        = 0
			STD_PolSol     = 0
			STD_NpoSol     = 0
			STD_ScoreFunct = 0
		} 
		{ 
			Population = Population + 1
			STD_DeltaG     = STD_DeltaG + ($3 - DeltaG) * ($3 - DeltaG)
			STD_Coul       = STD_Coul + ($4 - Coul)   * ($4 - Coul)
			STD_vdW        = STD_vdW + ($5 - vdW)    * ($5 - vdW)
			STD_PolSol     = STD_PolSol + ($6 - PolSol) * ($6 - PolSol)
			STD_NpoSol     = STD_NpoSol + ($7 - NpoSol) * ($7 - NpoSol)
			#STD_ScoreFunct = $4/10 - $6/10 + $7*10 +150
		}
		END { 
			STD_DeltaG     = sqrt(STD_DeltaG / (Population-1))
			STD_Coul       = sqrt(STD_Coul   / (Population-1))
			STD_vdW        = sqrt(STD_vdW    / (Population-1))
			STD_PolSol     = sqrt(STD_PolSol / (Population-1))
			STD_NpoSol     = sqrt(STD_NpoSol / (Population-1))
			STD_ScoreFunct = STD_Coul/10 - STD_PolSol/10 + STD_NpoSol*10 
			printf "%-10s \t%9.3f \t%9.3f \t%9.3f \t%9.3f \t%9.3f \t\t%9.3f \n", "#STD", STD_DeltaG, STD_Coul, STD_vdW, STD_PolSol, STD_NpoSol, STD_ScoreFunct
		} 
	'  >> AllData.temp
	cat AllData.temp >> $_AllData
	rm AllData.temp
	#msg -s "\t\tComputed Average and STD values  -> AllData.out"
}

AvgANDStd2 () {
	local _AllData="AllData.out"
	local _idx=
	local _awkSTRING=
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-if)	shift; _AllData=$1;;
		*)	fatal 1 "AvgANDStd () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done	
	
	
	
	_NLine=$( grep -v "^#" ${_AllData} | wc -l )
	((_floor_NLine=(_NLine+1)/2))
	((_ceiling_NLine=(_NLine+2)/2))
	
	# gawk 'BEGIN{start=1} {if(start==1){for(i=1; i<NF;i++){print $i}; start=0; }}' RUN2_Cx43/Config0/AllData.out
	#msg -n "Runnig AvgANDStd..."
	#configNum      frame   dG(kJ/mol)      Coul(kJ/mol)      vdW(kJ/mol)    PolSol(kJ/mol)    NpoSol(kJ/mol)     SF=C/10-PS/10+NpS*10     SF2=3*C+PS      C_AVG=norm(SUM Gi*e^BGi)      Median DeltaG 
	grep -v "^#" ${_AllData} | gawk -v floor_NLine=${_floor_NLine} -v ceiling_NLine=${_ceiling_NLine} '
		BEGIN { 
			Population 	= 0
			Canonica_AVG    = 0
			Canonica_AVG_w  = 0
			MedianDG    	= 0
			for(idx=3; idx<=NF; idx++) {
				value[idx]     = 0
			}
		} 
		{ 
			Population 	= Population + 1
			for(idx=3; idx<=NF; idx++) {
				value[idx]     = value[idx] + $idx
				print "index "idx"\t (partialSUM)value->"value[idx]
			}
			DG[Population]	= $3
			Canonica_AVG   	= Canonica_AVG + $3 * exp( -1 * $3 / 2.479 )	# 1KT=2.479KJ/mol
			Canonica_AVG_w 	= Canonica_AVG_w + exp( -1 * $3 / 2.479 )
			
		}
		END { 
			Canonica_AVG	= Canonica_AVG / Canonica_AVG_w
			printf "%-10s \t", "Ordered DG"
			for(idx1=1; idx1<Population; idx1++){
				for(idx2=idx1+1; idx2<=Population; idx2++){
					if( DG[idx2] < DG[idx1] ) {
						flag = DG[idx2]
						DG[idx2] = DG[idx1] 
						DG[idx1] = flag
					}
				}
				printf "%8.3f \t", DG[idx1]
			}
			printf "%8.3f \n", DG[Population]
			MedianDG = MedianDG + DG[floor_NLine]
			MedianDG = MedianDG + DG[ceiling_NLine]
			MedianDG = MedianDG / 2
			
			printf "%-18s \t \t", "#AVG"
			for(idx=3; idx<=NF; idx++) {
				value[idx]     = value[idx] / Population
				printf "%15.3f \t", value[idx]
			}
			printf "%15.3f \t %15.3f \n", Canonica_AVG, MedianDG
			
			
			
			# printf "%-10s \t%15.3f \t%15.3f \t%15.3f \t%15.3f \t%15.3f \t\t%15.3f \n", "#Average", DeltaG, Coul, vdW, PolSol, NpoSol, ScoreFunct
		} 
	'  > AllData.temp
	
	let _idx=2
	_awkSTRING=""
	for AVG in `tail -n 1 AllData.temp | cut -f 2-`; do
		#_AVG_${ndx}=${AVG}
		let _idx++
		_awkSTRING=${_awkSTRING}"${AVG} "
	done
	_awkSTRING="${_idx} AVGs "${_awkSTRING}
	#echo "AvgANDStd2: _awkSTRING->$_awkSTRING"
	
	grep -v "^#" $_AllData | gawk -v txt="${_awkSTRING}" '
		BEGIN { 
			Population 	= 0
			Canonica_AVG_w 	= 0
			for(idx=3; idx<=NF; idx++) {
				STD_value[idx]     = 0
			}
			
			split(txt, value)
			printf "%-25s \t", "imported AVG values"
			for (idx=1; idx<=value[1]; idx++) { 
				printf "%15.3f \t", value[idx] 
			}
			printf "\n"
		} 
		{ 
			Population = Population + 1
			Canonica_AVG_w 	= Canonica_AVG_w + exp( -1 * $3 / 2.479 )
			for(idx=3; idx<=NF; idx++) {
				STD_value[idx]     = STD_value[idx] + ($idx - value[idx]) * ($idx - value[idx])
				print "index "idx"\t (AVGs)value->"value[idx]"\tSTD_value->"STD_value[idx]
			}
		}
		END { 
			STDCanonica_AVG	= 1 / sqrt( Canonica_AVG_w )
			printf "%-18s \t \t", "#STD"
			for(idx=3; idx<=NF; idx++) {
				STD_value[idx]     = sqrt(STD_value[idx] / (Population-1))
				printf "%15.3f \t", STD_value[idx]
			}
			STD_MedianDG	= 1.2533 * STD_value[3]
			printf "%15.3f \t %15.3f \n", STDCanonica_AVG, STD_MedianDG
			
			
			
			# STD_ScoreFunct = STD_Coul/10 - STD_PolSol/10 + STD_NpoSol*10 
			# printf "%-10s \t%9.3f \t%9.3f \t%9.3f \t%9.3f \t%9.3f \t\t%9.3f \n", "#STD", STD_DeltaG, STD_Coul, STD_vdW, STD_PolSol, STD_NpoSol, STD_ScoreFunct
		} 
	'  >> AllData.temp
	grep "^#" AllData.temp >> $_AllData
	cp AllData.temp "$envStartingFOLDER"
	rm AllData.temp
	#msg -s "\t\tComputed Average and STD values  -> AllData.out"
}



test_random () {
	# $1 must be the number of rand number you want as output
	# $2 select if the output are (i) integers between [MIN_value,MAX_value] or (d) double between [0,1)
	# $3 must be the min value
	# $4 must be the max value
	local numRand="$1"
	local typeRand="$2"
	local MIN_value="$3"
	local MAX_value="$4"
	local bin_MIN=
	local bin_MAX=
	local BIN=
	local mid_bin=
	
	case "$typeRand" in
		-i)	echo -e "\t Integer between $MIN_value and $MAX_value"
			num_bin="$(($MAX_value-$MIN_value+1))"
			bin_width="1"
			for num in `seq 0 $(($num_bin-1))`; do
				bin_value[$num]="0"
			done
			for RNum in `seq 1 $numRand`; do
				[ "$(( $RNum%($numRand/10) ))" -eq "0" ] && echo -n -e "\r\t"$(( $RNum/($numRand/10) ))"0%"
				BIN="0"
				RandNum="$(dd if=/dev/urandom count=1 2>/dev/null | od -t u  | head -1 | gawk -v max="$MAX_value" -v min="$MIN_value" '{ r=($2%max)+min; print r }' )"
				for nBIN in `seq 0 $(($num_bin-1))`; do
					if [ "$RandNum" -eq "$(( $MIN_value + $nBIN ))" ]; then
						bin_value[$nBIN]="$(( ${bin_value[$nBIN]} + 1 ))"
						continue 2
					fi
				done
				echo -e "\n*************************  ERROR!! Number ($RandNum) not set to any bin!! check the inputs!!."
			done
	
			echo -n "" > "Histogram_int${MIN_value}to${MAX_value}.dat"
			for binX in `seq 0 $(($num_bin-1))`; do
				mid_bin=$(( $MIN_value + $binX))
				echo "$mid_bin ${bin_value[$binX]}" >> "Histogram_int${MIN_value}to${MAX_value}.dat"
			done
			echo ""
			;;
			
		-d)	echo -e "\t double between 0 and 1 (precision 10^-6)"
			num_bin="10"
			MIN_value="0"
			MAX_value="1"
			bin_width="0.1"
			for num in `seq 0 $(($num_bin-1))`; do
				bin_value[$num]="0"
			done
			for RNum in `seq 1 $numRand`; do
				[ "$(( $RNum%($numRand/10) ))" -eq "0" ] && echo -n -e "\r\t"$(( $RNum/($numRand/10) ))"0%"
				BIN="0"
				RandNum="$(dd if=/dev/urandom count=1 2>/dev/null | od -t u  | head -1 | gawk '{ r=($2%1000000)/1000000; print r }' )"
				for nBIN in `seq 0 $(($num_bin-1))`; do
					flag="$( gawk -v Rnd="$RandNum" -v bin="$nBIN" -v bw="$bin_width" 'BEGIN { Bmin=bin*bw; Bmax=(bin+1)*bw; if (Rnd>=Bmin && Rnd<Bmax) print "1"; else print "0" }')"
					if [ "$flag" -eq "1" ]; then
						bin_value[$nBIN]="$(( ${bin_value[$nBIN]} + 1 ))"
						continue 2
					fi
				done
				echo -e "\n*************************  ERROR!! Number ($RandNum) not set to any bin!! check the inputs!!."
			done
	
			echo -n "" > "Histogram_doubl${MIN_value}to${MAX_value}.dat"
			for binX in `seq 0 $(($num_bin-1))`; do
				mid_bin=$( gawk -v bin="$binX" -v bw="$bin_width" 'BEGIN { r=(bin+0.5)*bw; printf "%4.3f", r}' )
				echo "$mid_bin ${bin_value[$binX]}" >> "Histogram_doubl${MIN_value}to${MAX_value}.dat"
			done
			echo ""
			;;
			
		*)	echo -e "The options are 'd' or 'i'!\n"; return;;
	esac
	
	echo "DONE!"
	
}

# search for a file with a specific extension and save it. If none are found, it takes the default name. No warnings if it founds more than one file.
# usage: Initialize <NameOfTheVariable> <ExtentionSearched> <DefaultValue>
Initialize_ext () {
	local _name=$1
	local _ext=$2
	local _default=$3
	local _myName=$_default
	
	if [ -n "`ls *$_ext 2>> /dev/null`" ]; then 
		_myName=$(basename `ls *$_ext` .$_ext)
		eval $_name="'$_myName'"
	else	
		eval $_name="'$_default'"
	fi
	echo -e "$_name= $_myName"
}

# Run a job using a Queue system
QScript () {
	local _IOfileName=
	local _Check=
	local _tempJobName=
	local _Program=
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-n) 	shift; _IOfileName=$1;;
		-p)	shift; _Program=$1;;
		*)	fatal 1 "QScript () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	# IMPUT CHECK
	if [ "$_IOfileName" == "" ]; then fatal 110 "QScript: mandatory parameter -n ($_IOfileName) not set!!!"; fi	
	
	_tempJobName="$JobName`date +%N | cut -b 6-9`"
	_Check=`bjobs 2> /dev/null | grep $_tempJobName | wc -l`
	while [ "$_Check" -gt "0" ]; do
		_tempJobName="$JobName`date +%N | cut -b 6-9`"
		_Check=`bjobs 2> /dev/null | grep $_tempJobName | wc -l`
	done
	
	case "$_Program" in
		NAMD)	msg -s "job-name $_tempJobName " | tee -a $LOGFILENAME
			echo -n -e > QueueScript.sh "#!/bin/bash\
                                \n#BSUB -q gpu1\
				\n#BSUB -o /dev/null\
				\n#BSUB -e ./err\
				\n#BSUB -n 40\
				\n#BSUB -J \"$_tempJobName$f\"\

				\nmodule load intel\
                                \nmodule load mkl\
                                \nmodule load impi\
                                \nmodule load cuda\

                                \nsource /share/apps/NAMD/namd.sh\

                                \nexport CUDA_VISIBLE_DEVICES=0,1,2,3\

				\nnamd2 +p40 +setcpuaffinity +devices 0,1,2,3 ${_IOfileName}.conf 2>&1 > ${_IOfileName}.log &
			"
			bsub < QueueScript.sh > /dev/null
			;;
		NAMD1n)	msg -s "job-name $_tempJobName " | tee -a $LOGFILENAME
			echo -n -e > QueueScript.sh "#!/bin/bash\
                                \n#BSUB -q gpu1\
				\n#BSUB -o /dev/null\
				\n#BSUB -e ./err\
				\n#BSUB -n 40\
				\n#BSUB -J \"$_tempJobName$f\"\

				\nmodule load intel\
                                \nmodule load mkl\
                                \nmodule load impi\
                                \nmodule load cuda\

                                \nsource /share/apps/NAMD/namd.sh\

                                \nexport CUDA_VISIBLE_DEVICES=0,1,2,3\

				\nnamd2 ${_IOfileName}.conf 2>&1 > ${_IOfileName}.log &
			"
			bsub < QueueScript.sh > /dev/null
			;;
		VMD)	echo -n -e > QueueScript.sh "#!/bin/bash\
				\n#BSUB -q gpu1\
				\n#BSUB -o /dev/null\
				\n#BSUB -e ./err\
				\n#BSUB -n 40\
				\n#BSUB -J \"$_tempJobName$f\"\

				\nmodule load intel\
                                \nmodule load mkl\
                                \nmodule load impi\
                                \nmodule load cuda\

				\nsource /share/apps/VMD/vmd.sh\

				\nexport CUDA_VISIBLE_DEVICES=0,1,2,3\

				\nvmd -dispdev none -e tempFILES/vmd${_IOfileName}.temp 2>&1 > vmd_${_IOfileName}.out &
			"
			bsub < QueueScript.sh > /dev/null
			;;
		*)	fatal 111 "QScript: mandatory parameter -p ($_Program) must be set to NAMD or VMD!!!";;
		esac
	
	_Check=`bjobs 2> /dev/null | grep "$_tempJobName" | wc -l`
	while [ "$_Check" -gt "0" ]
	do
		sleep 2s
		[ "$_Program" == "NAMD" ] && sleep 8s
		_Check=`bjobs 2> /dev/null | grep "$_tempJobName" | wc -l`
	done
	
	if [ "$_Program" == "NAMD" ] || [ "$_Program" == "NAMD1n" ]; then
		_Check=`tail ${_IOfileName}.log | grep 'End of program' | wc -l`
		if ! [ "$_Check" -eq "1" ]; then
			fatal 119 "QScript: The log file '${_IOfileName}.log' is not completed!!"
		fi
	fi
	
}

# Check if the programs part are in the current directory, if not it check the main program directory. Error if cannot find any
Check_ProgramParts () {
	local _ProgramName=
	local _MainPath=
	local _ProgramPath=
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-n) 	shift; _ProgramName=$1;;
		-p) 	shift; _MainPath=$1;;
		*)	fatal 1 "Read_INPUT () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	
	echo -e -n "Checking the Programs Part:\t"
	# FIRST check on the current folder. The current folder has the priority.
	_ProgramPath=$(ls "$PWD/${_ProgramName}".* 2>> /dev/null)
	if [ -r "$_ProgramPath" ]; then
		printf "%-28s  %-84s \n" "\"${_ProgramName}\":" "${_ProgramPath}"
		eval "$_ProgramName=$_ProgramPath"
		return 0
	fi
	# SECOND check on the program folder
	_ProgramPath=$(ls "${_MainPath}${_ProgramName}".* 2>> /dev/null)
	if [ -r "$_ProgramPath" ]; then
		printf "%-28s  %-84s \n" "\"${_ProgramName}\":" "${_ProgramPath}"
		eval "$_ProgramName=$_ProgramPath"
		return 0
	fi
	
	fatal 1 "ERROR: The ${_ProgramName} file can not be found or read"
}


Read_INPUT () {
# IMPROVEMENTS: CHECK IF in the INPUT file THERE IS MORE THEN 1 VALUE WITH THE SAME NAME. 
#		THE KAY MUST BE EXACTLY THAT!!
#########################################################################################################################
# usage: Read_INPUT -p <$parameter> -n <parameter> [OPTIONS] -d <$default>						#
#     -v <ParamValue>:		Insert the VALUE of the parameter (if it has one).					#
#     -n <ParamName>:		Insert the NAME of the parameter to initialize. The INPUT file is NOT case sensitive.	#
#     OPTIONS:														#
#     -d <DefaultValue>:	Insert the default value of the parameter. It will be used if the user did't set it.	#
#				IF -d is NOT used, the parameter MUST be set up by the user.				#
#     -i <InputFileName>:	Name of the Input File (Default INPUT.in)						#
#########################################################################################################################
	local _ParamValue=
	local _ParamName=
	local _DefaultValue=
	local _ValueInpFile=
	local _InputFileName="INPUT.in"
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-v)	shift; [[ "$1" == -* ]] && { continue; }; _ParamValue=$1;;		#the ParamValue may NOT have a value and se second entry will be -* or $#==0
		-n)	shift; _ParamName=$1;;
		-d)	shift; _DefaultValue=$1;;
		-i)	shift; _InputFileName=$1;;
		*)	fatal 1 "Read_INPUT () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	
	# FIRST search if the value is assigned to the parameter by bash command line
	if [ -n "$_ParamValue" ]; then
		printf "Parameter \"%-28s  %-84s \t(initialized by bash command line)\n" "${_ParamName}\":" "${_ParamValue}"
		# if the parameter has 'FileName' as part of the name that is a name of a file that must exist
		if [[ $_ParamName == *FileName* ]]; then
			[ -r "$_ParamValue" ] || fatal 1 "Read_INPUT () ERROR: The $_ParamValue file can not be found or read"
		fi
		return 0
	fi
	#echo -e "\n_InputFileName->$_InputFileName\tInputFile->$Inputfile"
	
	# SECOND search if the value is assigned to the parameter by INPUT file
	_ValueInpFile=$( echo `egrep -v "(^#)|(^@)" "$_InputFileName" | gawk -v Var="${_ParamName}=" '$1 ~ Var { for (i=2;i<=NF;i++) { if ($i=="#") break; print $i }}'` )
	#echo -e "\$?: $? -> _ValueInpFile: $_ValueInpFile" 
	if [ -n "$_ValueInpFile" ]; then
		#echo -e "Parameter \"$_ParamName\": $_ValueInpFile \t(initialized by Input file)" 
		printf "Parameter \"%-28s  %-84s \t(initialized by Input file)\n" "${_ParamName}\":" "$_ValueInpFile"
		if [ "$_ParamName" == "*FileName*" ]; then
			echo "*FileName* check"
			[ -r "$_ValueInpFile" ] || fatal 1 "Read_INPUT () ERROR: The $_ValueInpFile file can not be found or read"
		fi
		eval $_ParamName="'$_ValueInpFile'"
	else
	# THIRD search for a Deafault Value
		if [ -n "$_DefaultValue" ]; then
			#echo -e "Parameter \"$_ParamName\": $_DefaultValue \t(initialized to the Default value)" 
			printf "Parameter \"%-28s  %-84s \t(initialized to the Default value)\n" "${_ParamName}\":" "$_DefaultValue"
			if [[ $_ParamName == *FileName* ]]; then
				[ -r "$_DefaultValue" ] || fatal 1 "Read_INPUT () ERROR: The $_DefaultValue file can not be found or read"
			fi
			eval $_ParamName="'$_DefaultValue'"
		else
			fatal 1 "Read_INPUT () ERROR: The mandatory parameter $_ParamName has not be set!!"
		fi
	fi
	
}

VMD_function () {
#################################################################################################################################################################
# usage: VMD_function -psf <$psffile> -pdb <$pdbfile> -s <ServiceType> [OPTIONS]										#
#     -pv  <PathVMD>:		Insert the path for vmd program													#
#     -psf <PSFfile>:		[not necessary on BOX ServiceType] Insert the structure file .psf that will be used as starting configuration.			#
#     -pdb <PDBfile>:		Insert the coordinate file .pdf that will be used as starting configuration.							#
#     -t   <ServiceType>:	Insert the type of service that vmd will perform. Options are: 									#
# 	     BOX	->	print a file with the box dimensions.												#
# 	     LAST	->	print the last $n (.pdb) configurations from a trajectory.									#
# 	     SEL	->	print a new trajectory (dcd) and the first frame (pdb and psf) with only the selection.						#
# 	     RNAME	->	print the name of a (or a list of) selected residue in standard output following the key word 'NAME_RESIDUE_SEARCHED:'		#
# 	     MUT	->	start the tcl program "mutator"													#
# 	     SOL	->	solvate the system														#
#     OPTIONS:																			#
#     -n   <ConfigNum>:		used with "LAST" ServiceType. Number of configurations that will be extracted from the (end of) trajectory (Default: 1)		#
#     -dcd <dcdFile>:		REQUIRED with "LAST" and "SEL" ServiceType. It is the trajectory file.								#
#     -s   <Selections>:	REQUIRED with "SEL" ServiceType. It is the list of Selections that will be extracted.						#
#     -m   <SelectName>:	REQUIRED with "SEL" ServiceType. It is the list of Name of the Selections that will be extracted.				#
#     -ri  <ResID>:		REQUIRED with "RNAME" and "MUTATE" ServiceType. It is the ID number of the residue you are looking for.				#
#				  It may be a vector list ONLY with RNAME option.										#
#     -sn  <SegName>:		REQUIRED with "RNAME" and "MUTATE" ServiceType. It is the name of the segment where the residue is located.			#
#     -cn  <ChainName>:		REQUIRED with "RNAME" 														#
#     -rm  <ResMutation>:	REQUIRED with "MUTATE" ServiceType. It is the name of the new residue.								#
#     -o   <OutputName>:	used with "MUTATE" ServiceType. It is the name of the .pdb and .psf output. (optional for other options)			#
#################################################################################################################################################################
	local _FileNamePSF=
	local _pathPSF=
	local _FileNamePDB=
	local _pathPDB=
	local _FileNameDCD=
	local _ServiceType=
	#local _Selection=
	declare -a _Selection=		# When used in a function, declare makes each name local, as with the local command, unless the -g option is used.
	declare -a _SelectName=
	local _SelectNUM="0"
	local _ConfigNum="1"
	local _ResID=
	local _SegName=
	local _ChainName=
	local _VMD="$VMD"
	
	local _ResMutation=
	local _OutputName=
	
	# msg "VMD_function $@"
	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-pv)	shift; _VMD=$1;;
	    	-l)	shift; _libPATH=$1;;
		-psf)	shift; _FileNamePSF=$1;;
		-pdb)	shift; _FileNamePDB=$1;;
		-dcd)	shift; _FileNameDCD=$1;;
		-n)	shift; _ConfigNum=$1;;
		-t)	shift; _ServiceType=$1;;
		-s)	shift; _SelectNUM="0"		# there must be at least 1 element
			while [[ $1 != -* ]]; do 
				((_SelectNUM+=1)); _Selection[$_SelectNUM]=$1
				# msg "SelectNum= $_SelectNUM _Selection[$_SelectNUM]=${_Selection[$_SelectNUM]}" 
				shift; [ $# -gt 0 ] || break
			done
			[ $_SelectNUM -eq 0 ] && fatal 1 "VMD_function () ERROR: a list of value (at least 1) after \"-s\"\n"
			continue;;
		-m)	shift; _SelectNUM="0"		# there must be at least 1 element
			while [[ $1 != -* ]]; do 
				((_SelectNUM+=1)); _SelectName[$_SelectNUM]=$1
				# msg "SelectNum= $_SelectNUM _SelectName[$_SelectNUM]=${_SelectName[$_SelectNUM]}" 
				shift; [ $# -gt 0 ] || break
			done
			[ $_SelectNUM -eq 0 ] && fatal 1 "VMD_function () ERROR: expect a list of name (at least 1) after \"-m\"\n"
			continue;;
		-ri)	shift; _ResID="$1"; shift; [ $# -gt 0 ] || break
			while [[ $1 != -* ]]; do 
				_ResID="$_ResID $1";
				#echo "_ResID: $_ResID"
				shift; [ $# -gt 0 ] || break
			done
			continue;;
		-sn)	shift; _SegName=$1;;
		-cn)	shift; _ChainName=$1;;
		-rm)	shift; _ResMutation=$1;;
		-o)	shift; _OutputName=$1;;
		*)	fatal 1 "VMD_function () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	
	if ! [ -x "`which $_VMD`" ]; then
		_VMD=`which vmd`
		if [ "$_VMD" != "" ]; then
			msg "VMD_function() : vmd program found on -> $_VMD" >&2
		else
			fatal 11 "Cannot find any vmd program in the \$PATH!! Please install it or specify a custom path."
		fi
	fi
	
	# check the variables that must be set on the main program
	[ "$Env" == "" ] && [ "$_ServiceType" == "" ] && fatal 3 "ERROR VMD_function (MUT): the variable 'Env' ($Env) must be set in the main program!!"
	
	# if _OutputName is not set, put it equal to _FileNameDCD
	[ "$_OutputName" == "" ] && _OutputName=$_FileNameDCD
	
	# there must be a folder for temporary files
	mkdir -p tempFILES
	
	if ! [ -z "$_FileNamePSF" ]; then
		#[ $_ServiceType != "BOX" ] && fatal 1 "VMD_function () ERROR: The parameter -psf MUST be set!\n"
		_pathPSF=`dirname $_FileNamePSF`
		_FileNamePSF=`basename $_FileNamePSF`
		#echo -e "\t _FileNamePSF->$_FileNamePSF _FileNamePDB->$_FileNamePDB _FileNameDCD->$_FileNameDCD _ConfigNum->$_ConfigNum _ServiceType->$_ServiceType _SelectNUM->$_SelectNUM _ResID->$_ResID _SegName->$_SegName _ResMutation->$_ResMutation _OutputName->$_OutputName"
	fi
	_pathPDB=`dirname $_FileNamePDB`
	_FileNamePDB=`basename $_FileNamePDB`
		
	case "$_ServiceType" in
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	extract the box size	@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		BOX)	echo -n -e > tempFILES/vmd${_ServiceType}.temp "\
				\nmol load pdb ${_pathPDB}/${_FileNamePDB}.pdb\
				\nset outfile [open tempFILES/measure_box.temp w]\
				\nset everyone [atomselect top all]\
				\nset CENTER [measure center \$everyone]\
				\nputs \$outfile \"centerX: [lindex \$CENTER 0] \ncenterY: [lindex \$CENTER 1] \ncenterZ: [lindex \$CENTER 2]\"\
				\nset BOX [measure minmax \$everyone]\
				\nputs \$outfile \"min-maxX: [lindex [lindex \$BOX 0] 0] [lindex [lindex \$BOX 1] 0]\"\
				\nputs \$outfile \"min-maxY: [lindex [lindex \$BOX 0] 1] [lindex [lindex \$BOX 1] 1]\"\
				\nputs \$outfile \"min-maxZ: [lindex [lindex \$BOX 0] 2] [lindex [lindex \$BOX 1] 2]\"\
				\nclose \$outfile\
				\nexit\
			"
			;;
		
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	extract the last frame and save a new pdb	@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		LAST)	[ -z "${_FileNameDCD}" ] && fatal 3 "To run VMD_function -t LAST, the option -dcd is MANDATORY!"
			if [ $ForceField == "CHARMM" ]; then
				echo -n -e > tempFILES/vmd${_ServiceType}.temp "\
					\npackage require psfgen
					\nreadpsf ${_pathPSF}/${_FileNamePSF}.psf\
					\ncoordpdb ${_pathPDB}/${_FileNamePDB}.pdb
				"
			fi
			echo -n -e >> tempFILES/vmd${_ServiceType}.temp "\
				\npackage require pbctools\
				\n#mol new ${_pathPSF}/${_FileNamePSF}.psf waitfor all\
				\nmol new ${_pathPDB}/${_FileNamePDB}.pdb waitfor all\
				\nmol addfile ${_FileNameDCD}.dcd waitfor all\
				\npbc unwrap\
				\nsource $fitframes\
				\nfitframes top \"chain A B C\"
				\nputs -nonewline \"current frame: \"
				\nset FrameNow [expr [molinfo top get numframes]-1]\
				\nputs -nonewline \"Configurations desired: \" 
				\nset CountFrame $_ConfigNum\
				\nset Count_mol 1\
				
				\nsource $autopsf\
				\nset env(SOLVATEDIR) $Env\

				\nif { \${CountFrame}==0 } {\
				\n	set nLastFrame [atomselect 0 \"all\" frame \$FrameNow] \
				\n	\$nLastFrame writepdb ${_FileNameDCD}_last_F\${CountFrame}.pdb \
				\n	writepsf ${_FileNameDCD}_last_F\${CountFrame}.psf \
				\n	exit
				\n}
				
				\nwhile { \$FrameNow > 0 } { \
				\n	set nLastFrame [atomselect 0 \"not water and not ion\" frame \$FrameNow] \
				\n	\$nLastFrame writepdb ${_FileNameDCD}_last_F\${CountFrame}.pdb \
				\n	\$nLastFrame writepsf ${_FileNameDCD}_last_F\${CountFrame}.psf \

				\n	mol new ${_FileNameDCD}_last_F\${CountFrame}.psf waitfor all \
				\n	mol addfile ${_FileNameDCD}_last_F\${CountFrame}.pdb waitfor all \
				\n	set MolID [molinfo top] \
				\n\n	autopsf -top ${FileNameCHARMMtop[*]} -mol \$MolID -prefix \"${_FileNameDCD}_last_F\${CountFrame}_autopsf\" -solvate -ionize \
				\n	puts \"*** FINISH with frame $CountFrame ***\" \
				\n	if { \$CountFrame<=1 } { \
				\n		break \
				\n	} \
				\n	puts \"*** deletting molecule \$Count_mol ***\" \
				\n	mol delete \$Count_mol\
				\n	set Count_mol [expr \$Count_mol+10] \
				\n	set FrameNow [expr \$FrameNow-1] \
				\n	set {CountFrame} [expr \$CountFrame-1] \
				\n}\
				\nif { \${CountFrame}>1 } {\
				\n	puts \"ERROR: number of configurations required ($_ConfigNum) exceed the number of frame on the trajectory ([expr [molinfo top get numframes]-1]) \"\
				\n}\
				\nexit\
			"
			;;
		
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	extract the selection from a dcd and save the new dcd and starting pdb	@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		SEL)	[ -z "${_FileNameDCD}" ] && fatal 3 "To run VMD_function -t SEL, the option -dcd is MANDATORY!"
			[ -z "${_Selection[1]}" ] && fatal 3 "To run VMD_function -t SEL, the option -s is MANDATORY!"
			[ -z "${_SelectName[1]}" ] && fatal 3 "To run VMD_function -t SEL, the option -m is MANDATORY!"
			
			echo -n -e > tempFILES/vmd${_ServiceType}.temp "\
				\nset _ForceField $ForceField
				\npackage require pbctools\
				
				\nif { \${_ForceField}==\"CHARMM\" } {\
				\n	puts \"*** forcefield -> \$_ForceField\"
				\n	package require psfgen\
				\n	readpsf ${_pathPSF}/${_FileNamePSF}.psf\
				\n	coordpdb ${_pathPDB}/${_FileNamePDB}.pdb\
				\n	mol new ${_pathPSF}/${_FileNamePSF}.psf waitfor all\
				\n	mol addfile ${_pathPDB}/${_FileNamePDB}.pdb waitfor all\
				\n} else {\
				\n	puts \"forcefield -> \$_ForceField\"
				\n	mol new ${_pathPDB}/${_FileNamePDB}.pdb waitfor all\
				\n}
				
				\nmol addfile ${_FileNameDCD}.dcd waitfor all\
				\npbc unwrap\
				\nsource $fitframes\
				\nfitframes top \"protein\"
			"
			for i in `seq 1 $_SelectNUM`; do
				echo -n -e >> tempFILES/vmdSEL.temp "\
					\nputs \"*** atomselect top \\\"${_Selection[$i]} and (not water and not ions)\\\" frame first\"\
					\nset SelecStructure [atomselect top \"${_Selection[$i]} and (not water and not ions)\" frame first]\
					\n\$SelecStructure writepsf ${_OutputName}_${_SelectName[$i]}.psf\
					\n\$SelecStructure writepdb ${_OutputName}_first_${_SelectName[$i]}.pdb\
					\nanimate write dcd ${_OutputName}_${_SelectName[$i]}.dcd sel \$SelecStructure waitfor all\
				"
			done
			echo -e >> tempFILES/vmdSEL.temp "\nexit"
			;;
			
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	extract the name of the a selected residue				@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		RNAME)	[ -z "${_ResID}" ] && fatal 3 "To run VMD_function -t RNAME, the option -ri is MANDATORY!"
			if ! [ -z "${_SegName}" ]; then 
				echo -n -e > tempFILES/vmd${_ServiceType}.temp "\
					\nvariable _pathPDB \"$_pathPDB\" \nvariable _FileNamePDB \"$_FileNamePDB\" \nvariable _ResID \"$_ResID\" \nvariable _SegName \"$_SegName\"
				"
				cat ${PPATH}/ABiSS_lib/VMD_function_RNAME_SegName.tcl >> tempFILES/vmd${_ServiceType}.temp
			elif ! [ -z "${_ChainName}" ]; then
				echo -n -e > tempFILES/vmd${_ServiceType}.temp "\
					\nvariable _pathPDB \"$_pathPDB\" \nvariable _FileNamePDB \"$_FileNamePDB\" \nvariable _ResID \"$_ResID\" \nvariable _ChainName \"$_ChainName\"
				"
				cat ${PPATH}/ABiSS_lib/VMD_function_RNAME_chain.tcl >> tempFILES/vmd${_ServiceType}.temp
			else
				fatal 3 "To run VMD_function -t RNAME, the option -sn (or -cn) is MANDATORY!"
			fi
			;;
			
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	Mutate the selected residue 						@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		MUT)	[ -z "${_ResID}" ] && fatal 3 "To run VMD_function -t MUTATE, the option -ri is MANDATORY!"
			[ -z "${_SegName}" ] && fatal 3 "To run VMD_function -t MUTATE, the option -sn is MANDATORY!"
			[ -z "${_ResMutation}" ] && fatal 3 "To run VMD_function -t MUTATE, the option -rm is MANDATORY!"
			[ -z "${_OutputName}" ] && _OutputName="mutant_X${_ResID}${_ResMutation}"
			echo -n -e > tempFILES/vmd${_ServiceType}.temp "\
				\nset _ForceField $ForceField
				\nset _FileName ${_FileNamePSF}_TempMol
				\npackage require psfgen
				
				\nif { \${_ForceField}==\"CHARMM\" } {
				\n	puts \"*** forcefield -> \$_ForceField\"
				\n	
				\n	readpsf ${_pathPSF}/${_FileNamePSF}.psf\
				\n	coordpdb ${_pathPDB}/${_FileNamePDB}.pdb\
				\n	mol new ${_pathPSF}/${_FileNamePSF}.psf waitfor all\
				\n	mol addfile ${_pathPDB}/${_FileNamePDB}.pdb waitfor all\
				\n	set NoSolvent [atomselect top \"all and (not water and not ions)\"]\
				\n	\$NoSolvent writepsf tempFILES/\${_FileName}.psf\
				\n	\$NoSolvent writepdb tempFILES/\${_FileName}.pdb\
				\n	\$NoSolvent writexbgf tempFILES/\${_FileName}.xbgf\
				\n	\$NoSolvent delete
				\n} else {
				\n	puts \"*** forcefield -> \$_ForceField\"
				\n	mol new ${_pathPDB}/${_FileNamePDB}.pdb waitfor all\
				\n	
				
resetpsf

set pr [atomselect top \"protein\"]
\$pr writepdb tempFILES/protein.pdb
\$pr delete
set pr [atomselect top \"protein and not hydrogen\"]
\$pr writepdb tempFILES/protein_noH.pdb
\$pr delete
set pr [atomselect top \"segname AP1 and not hydrogen\"]
\$pr writepdb tempFILES/AP1_noH.pdb
\$pr delete
set pr [atomselect top \"segname BP1 and not hydrogen\"]
\$pr writepdb tempFILES/BP1_noH.pdb
\$pr delete
set pr [atomselect top \"segname CP1 and not hydrogen\"]
\$pr writepdb tempFILES/CP1_noH.pdb
\$pr delete

psfgen << ENDMOL

topology ${FileNameCHARMMtop[*]}
pdbalias residue CYX CYS
pdbalias residue HIE HSD
segment AP1 {
	pdb tempFILES/AP1_noH.pdb
}
segment BP1 {
	pdb tempFILES/BP1_noH.pdb
}
segment CP1 {
	pdb tempFILES/CP1_noH.pdb
}

pdbalias atom ILE CD1 CD
pdbalias atom PRO O OT1
pdbalias atom PRO OXT OT2
pdbalias atom GLU O OT1
pdbalias atom GLU OXT OT2
pdbalias atom ALA O OT1
pdbalias atom ALA OXT OT2

coordpdb tempFILES/protein_noH.pdb

guesscoord

writepdb tempFILES/\${_FileName}.pdb
writepsf tempFILES/\${_FileName}.psf

mol new tempFILES/\${_FileName}.psf waitfor all
mol addfile tempFILES/\${_FileName}.pdb waitfor all
set NoSolvent [atomselect top \"all and (not water and not ions)\"]
\$NoSolvent writepsf tempFILES/\${_FileName}.xbgf
\$NoSolvent delete

ENDMOL

				
				\n}
			
				
				\nsource $mutator
				\nsource $autopsf				
				\nset env(SOLVATEDIR) $Env
				
				
				\nputs \"\n*** \t MUTATOR:\"\
				\nif { [catch {mutator -psf tempFILES/\${_FileName} -pdb tempFILES/\${_FileName} -o tempFILES/${_OutputName} -ressegname ${_SegName} -resid ${_ResID} -mut ${_ResMutation}} err] } { \
				\n	puts \"***		ERROR! '$mutator' fail!\"\
				\n	exit 1\	
				\n}\
				
				\nmol new tempFILES/${_OutputName}.psf waitfor all\
				\nmol addfile tempFILES/${_OutputName}.pdb waitfor all\
				\nset MolID [molinfo top]\
				
				
				\nputs \"\n*** \t AUTOPSF to correct the structure (CYS and HIS):\"\
				\nif { \${_ForceField}==\"CHARMM\" } {
				\n	autopsf -top ${FileNameCHARMMtop[@]} -mol \$MolID -prefix \"${_OutputName}_autopsf\" -solvate -ionize 
				\n} else {
				\n	autopsf -top ${FileNameCHARMMtop[@]} -mol \$MolID -prefix \"${_OutputName}_autopsf\" -protein 
				\n}
				
				\nexit
			"
			;;	
			
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	Build a solvation box for the input system				@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		SOL)	[ -z "${_OutputName}" ] && _OutputName="Solvated_${_ResID}${!_FileNamePSF}"
			echo -n -e > tempFILES/vmd"${_ServiceType}".temp "\
				\nmol new ${_pathPSF}/${_FileNamePSF}.psf waitfor all\
				\nmol addfile ${_FileNamePDB}.pdb waitfor all\
				\nset NoSolvent [atomselect top \"all and (not water and not ions)\"]\
				\n\$NoSolvent writepsf tempFILES/${_FileNamePSF}_NoSolvent.psf\
				\n\$NoSolvent writepdb tempFILES/${_FileNamePSF}_NoSolvent.pdb\
				\n\$NoSolvent writexbgf tempFILES/${_FileNamePSF}_NoSolvent.xbgf\

				\nsource $solvate\
				\nsource $autoionize\
				
				\nset env(SOLVATEDIR) $Env\
				
				\nputs \"\n\t SOLVATE:\"\
				\nsolvate tempFILES/${_FileNamePSF}_NoSolvent.psf tempFILES/${_FileNamePSF}_NoSolvent.pdb -o ${_OutputName} -t 12\
				
				\nputs \"\n\t AUTOIONIZE:\"\
				\nautoionize -psf ${_OutputName}.psf -pdb ${_OutputName}.pdb -o ${_OutputName} -sc 0.15 -cation POT\
				\nexit
			"
			;;	
			
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	unidentified type	@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		*)	fatal 2 "VMD_function () ERROR: \"$_ServiceType\" is not a valid ServiceType!\n";;			# First file name
	esac
	$_VMD -dispdev none -e tempFILES/vmd${_ServiceType}.temp &> vmd_${_ServiceType}.out
	
	if [ "$_ServiceType" != "MUT" ]; then
		[ "`grep -v "^psfgen" vmd_${_ServiceType}.out | egrep "(ERROR)|(can't read)"`" ] && fatal 4 "There is an \"ERROR\" or \"can't read\" on \"vmd_${_ServiceType}.out\"!! Check it!!"
		[ "`egrep 'usage' vmd_${_ServiceType}.out`" ] && fatal 4 "There is an \"usage\" on \"vmd_${_ServiceType}.out\"!! Check it!!"
	fi
}


Make_new_mutant () {
	local _filePSF=${pathPSF}${FileNamePSF}
	local _filePDB=${pathPDB}${FileNamePDB}
	local _FileNamePSF=
	local _FileNamePDB=
	local _ResID=""
	local _NewRes=""
	local _flag=""
	local _TargetResID=
	local _ResidueNameStart=
	local _TargetSegName=$TargetSegName
	local _ForceField="CHARMM"
	declare -a _TargetResidueList=
	local _TargetResidueList_num=$TargetResidueList_num
	local _ResiduePool=$ResiduePool
	local _flag
	local _ResiduePool_vect
	local _ResidueNameEnd
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-pdb)	shift; _filePDB=$1;;
	    	-psf)	shift; _filePSF=$1;;
		-rID) 	shift; _ResID=$1;;
		-nr) 	shift; _NewRes=$1;;
		-ff)	shift; _ForceField=$1;;
		-ts)	shift; _TargetSegName=$1;;
		
		-tr)	shift;  _TargetResidueList_num="0";
			while [[ $1 != -* ]]; do 
				((_TargetResidueList_num+=1)); _TargetResidueList[$_TargetResidueList_num]=$1
				shift; [ $# -gt 0 ] || break
			done
			[ $_TargetResidueList_num -eq 0 ] && fatal 1 "There must be a list of value (at least 1) after \"-tr\"\n"
			continue;;
		-rp)	shift;  _flag="0";
			while [[ $1 != -* ]]; do 
				((_flag+=1)); _ResiduePool[$_flag]=$1
				shift; [ $# -gt 0 ] || break
			done
			[ $_flag -eq 0 ] && fatal 1 "There must be a list of value (at least 1) after \"-tr\"\n"
			continue;;
		*)	fatal 1 "Make_new_mutant () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	mkdir -p tempFILES
	_FileNamePSF=`basename $_filePSF`
	_FileNamePDB=`basename $_filePDB`
	
	#====================================================================================================================================================
	# Select the residue ID to mutate ( from the list of residues given by the user )
	#====================================================================================================================================================
	if [ "$_ResID" == "" ]; then
		RandNum="$(dd if=/dev/urandom count=1 2>/dev/null | od -t u | head -1 | gawk -v max="${_TargetResidueList_num}" '{ r=($2%max)+1; print r }' )"	# Random number between 1 and max
		_TargetResID="${_TargetResidueList[$RandNum]}"
	else
		_TargetResID="$_ResID"
	fi
	
	#====================================================================================================================================================
	# Find out the starting name of the selected residue
	#====================================================================================================================================================
	VMD_function -psf "${_filePSF}" -pdb "${_filePDB}" -t "RNAME" -ri "${_TargetResID}" -sn "${_TargetSegName}"
	_ResidueNameStart="$( gawk '$1 ~ /NAME_RESIDUE_SEARCHED:/ { print $2 }' vmd_RNAME.out )"
	
	#====================================================================================================================================================
	# If not specified by the use, Randomly select the new residue type
	#====================================================================================================================================================
	if [ "$_NewRes" == "" ]; then
		# Select the mutation (final name of the residue) from a list of mutations that DO NOT include the starting residue
		_flag="0"						# I want to strip out the ResidueNameStart from the list of possible _ResidueNameEnd
		for res in ${_ResiduePool}; do
			if [ "$res" == "$_ResidueNameStart" ]; then continue; fi
			_flag=$(($_flag+1))
			_ResiduePool_vect[$_flag]="$res"
		done
		_ResiduePool_vect[0]="$_flag"
		RandNum="$(dd if=/dev/urandom count=1 2>/dev/null | od -t u | head -1 | gawk -v max="${_ResiduePool_vect[0]}" '{ r=($2%max)+1; print r }' )"	# Random number between 1 and max
		_ResidueNameEnd="${_ResiduePool_vect[$RandNum]}"
	else
		_ResidueNameEnd="$_NewRes"
	fi
	
	#====================================================================================================================================================
	# Make the mutation
	#====================================================================================================================================================
	msg -s -n "\t${_ResidueNameStart}${_TargetResID}${_ResidueNameEnd}" | tee -a $LOGFILENAME
	VMD_function -psf "${_filePSF}" -pdb "${_filePDB}" -t "MUT" -ri "${_TargetResID}" -sn "${_TargetSegName}" -rm "${_ResidueNameEnd}" -o "${ProteinName}_M${CurrentMutant}"
	
	#====================================================================================================================================================
	# change name to *_autopsf.pdb/psf
	#====================================================================================================================================================
	mv ${ProteinName}_M${CurrentMutant}_autopsf.pdb ${ProteinName}_M${CurrentMutant}.pdb
	mv ${ProteinName}_M${CurrentMutant}_autopsf.psf ${ProteinName}_M${CurrentMutant}.psf
	
	#====================================================================================================================================================
	# make AMBER topology
	#====================================================================================================================================================
	if [ $_ForceField == "AMBER" ]; then
		msg -s " " | tee -a $LOGFILENAME
		msg -n "\tbuilding AMBER topology" | tee -a $LOGFILENAME
		# I need to change the name of the atmos in the pdb file, add water/ions and build the AMBERtop file
		cp ${ProteinName}_M${CurrentMutant}.pdb ${ProteinName}_M${CurrentMutant}_CHARMM.pdb
		sed -i -e "s/ OT1/ O  /g" ${ProteinName}_M${CurrentMutant}.pdb
		sed -i -e "s/ OT2/ OXT/g" ${ProteinName}_M${CurrentMutant}.pdb
		sed -i -e "s/CD  ILE/CD1 ILE/g" ${ProteinName}_M${CurrentMutant}.pdb
		sed -i -e "s/HSD /HIE /g" ${ProteinName}_M${CurrentMutant}.pdb
		sed -i -e "s/CYS /CYX /g" ${ProteinName}_M${CurrentMutant}.pdb
		$pdb4amber -i ${ProteinName}_M${CurrentMutant}.pdb -o tempFILES/${ProteinName}_M${CurrentMutant}_noH_amber.pdb -y &> pdb4amber.out
		msg -s -n ".." | tee -a $LOGFILENAME
		$reduce -build tempFILES/${ProteinName}_M${CurrentMutant}_noH_amber.pdb > tempFILES/${ProteinName}_M${CurrentMutant}_protein_amber.pdb 2> reduce.out
		msg -s -n ".." | tee -a $LOGFILENAME
		
		MakeAmberTOP -pdb tempFILES/${ProteinName}_M${CurrentMutant}_protein_amber.pdb -o ${ProteinName}_M${CurrentMutant} -sol
		FileNameTOP="${ProteinName}_M${CurrentMutant}"
		pathTOP="`readlink -f ${FileNameTOP}.top`"
		pathTOP="${pathTOP%/*}/"
	fi
	
	#====================================================================================================================================================
	# 	Building file to test that the mutation worked correctly
	#====================================================================================================================================================
	# VMD_function -t "MUT" will build the files tempFILES/${FileNamePSF}_NoSolvent.pdb and ${ProteinName}_M${CurrentMutant}_formatted_autopsf.pdb
	if [ $_ForceField == "CHARMM" ]; then
		gawk '{print $3, $4, $5, $6, $12}' tempFILES/${_FileNamePSF}_TempMol.pdb > tempFILES/${_FileNamePDB}_NoSolventTEST.pdb
		gawk '{print $3, $4, $5, $6, $12}' ${ProteinName}_M${CurrentMutant}_autopsf_PROTEIN.pdb > tempFILES/${ProteinName}_M${CurrentMutant}TEST.pdb
	else
		gawk '{print $3, $4, $5, $6, $12}' tempFILES/protein.pdb > tempFILES/${_FileNamePDB}_NoSolventTEST.pdb
		egrep -v "( WAT )|( K+ )|( Cl- )" ${ProteinName}_M${CurrentMutant}.pdb | gawk '{print $3, $4, $5, $6, $12}' > tempFILES/${ProteinName}_M${CurrentMutant}TEST.pdb
	fi
	
	# actually only the TargetResID is not specific.. I should add the check on TargetSegName
	_flag=`diff -y --suppress-common-lines tempFILES/${_FileNamePDB}_NoSolventTEST.pdb tempFILES/${ProteinName}_M${CurrentMutant}TEST.pdb | grep -v "$_TargetResID" | wc -l`
	if [ $_flag -le 1 ]; then
		rm tempFILES/${_FileNamePDB}_NoSolventTEST.pdb tempFILES/${ProteinName}_M${CurrentMutant}TEST.pdb
	else
		msg -s "\nWARNING!! there are differences (beyond the mutation) between the original file and the mutated one!! check the $PWD/tempFILES/*TEST.pdb files"
	fi
	
	#====================================================================================================================================================
	# archive the '*_autopsf_PROTEIN*' and '*_formatted.*' structures as temporary files
	#====================================================================================================================================================
	mv ${ProteinName}_M${CurrentMutant}_autopsf_* ${ProteinName}_M${CurrentMutant}_formatted.* tempFILES 2> /dev/null
	
	#====================================================================================================================================================
	# archive the last mutation on ResidueListName.out file (this will not happen for the wt configuration)
	#====================================================================================================================================================
	grep -v "**DECLINED**" ResidueListName.out | tail -n 1 | gawk -v ORS=" " -v MNum="M${CurrentMutant}_${_ResidueNameStart}${_TargetResID}${ResidueNameEnd}" -v TResID="$_TargetResID" -v RNEnd="$ResidueNameEnd" \
		'BEGIN { printf "\n%-18s", MNum":" } { for (i=2;i<=NF;i++) { if ($i=="#") break; if ($i ~ (TResID)) {print (TResID)(RNEnd); continue;} print $i }}' >> ResidueListName.out
		
	
	
	#====================================================================================================================================================
	# Change the name to the new configuration
	#====================================================================================================================================================
	FileNamePSF="${ProteinName}_M${CurrentMutant}"
	pathPSF="`readlink -f ${FileNamePSF}.psf`"
	pathPSF="${pathPSF%/*}/"
	FileNamePDB="${ProteinName}_M${CurrentMutant}"
	pathPDB="`readlink -f ${FileNamePDB}.pdb`"
	pathPDB="${pathPDB%/*}/"

}


MakeNewMutant_Chimera () {
	#Other functions/programs
	#ChimeraMutation.py
	#VMD_function
	
	#GLOBAL VARIABLE USED:
	local _chimera=$CHIMERA
	#LOGFILENAME
	
	#LOCAL VARIABLES:
	local _filePDB=${pathPDB}${FileNamePDB}
	local _FileNamePDB=
	local _ResID=""
	local _outputName="output"
	local _NewRes=""
	local _flag=""
	local _TargetResID=
	local _ResidueNameStart=
	local _TargetChainName=$TargetChainName
	declare -a _TargetResidueList
	local _TargetResidueList_num=$TargetResidueList_num
	local _ResiduePool_list=$ResiduePool_list
	local _flag
	declare -a _ResiduePool_vect		# I will neet to buil a vector with all the residue in _ResiduePool_list but the Residue-Name I want to change
	local _ResidueNameEnd
	local _ABiSS_LIB=$ABiSS_LIB
	local _RandNum=
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-pdb)	shift; _filePDB=$1;;			#MANDATORY (it may work with the default value)
		-rID) 	shift; _ResID=$1;;			
		-on)	shift; _outputName=$1;;				# NO EXTENSION
		-nr) 	shift; _NewRes=$1;;
		-ts)	shift; _TargetChainName=$1;;		#MANDATORY (it may work with the default value)
		-al)	shift; _ABiSS_LIB=$1;;
		-rp)	shift; _ResiduePool_list=$1;;		#MANDATORY (it may work with the default value)
		-tr)	shift;  _TargetResidueList_num="0";	#MANDATORY 
			while [[ $1 != -* ]]; do 
				((_TargetResidueList_num+=1)); _TargetResidueList[$_TargetResidueList_num]=$1
				shift; [ $# -gt 0 ] || break
			done
			[ $_TargetResidueList_num -eq 0 ] && fatal 1 "There must be a list of value (at least 1) after \"-tr\"\n"
			continue;;
			
		*)	fatal 1 "MakeNewMutant_Chimera () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	mkdir -p tempFILES
	_FileNamePDB=`basename $_filePDB`
	_FileNamePDB="${_FileNamePDB%.*}"
	#comlex_EXT="${comlex_FILE##*.}"						# ${string##substring}  ->  Deletes longest match of $substring from front of $string.
	#comlex_FILE="${comlex_FILE%.*}"
	
	#====================================================================================================================================================
	# Select the residue ID to mutate ( from the list of residues given by the user )
	#====================================================================================================================================================
	if [ "$_ResID" == "" ]; then
		_RandNum="$(dd if=/dev/urandom count=1 2>/dev/null | od -t u | head -1 | gawk -v max="${_TargetResidueList_num}" '{ r=($2%max)+1; print r }' )"	# Random number between 1 and max
		_TargetResID="${_TargetResidueList[$_RandNum]}"
	else
		_TargetResID="$_ResID"
	fi
	
	#====================================================================================================================================================
	# Find out the starting name of the selected residue
	#====================================================================================================================================================
	VMD_function -pdb "${_FileNamePDB}" -t "RNAME" -ri "${_TargetResID}" -cn "${_TargetChainName}"
	_ResidueNameStart="$( gawk '$1 ~ /NAME_RESIDUE_SEARCHED:/ { print $2 }' vmd_RNAME.out )"
	
	#====================================================================================================================================================
	# If not specified by the use, Randomly select the new residue type
	#====================================================================================================================================================
	if [ "$_NewRes" == "" ]; then
		# Select the mutation (final name of the residue) from a list of mutations that DO NOT include the starting residue
		_flag="0"						# I want to strip out the ResidueNameStart from the list of possible _ResidueNameEnd
		for res in ${_ResiduePool_list}; do
			if [ "$res" == "$_ResidueNameStart" ]; then continue; fi
			_flag=$(($_flag+1))
			_ResiduePool_vect[$_flag]="$res"
		done
		_ResiduePool_vect[0]="$_flag"
		_RandNum="$(dd if=/dev/urandom count=1 2>/dev/null | od -t u | head -1 | gawk -v max="${_ResiduePool_vect[0]}" '{ r=($2%max)+1; print r }' )"	# Random number between 1 and max
		_ResidueNameEnd="${_ResiduePool_vect[$_RandNum]}"
	else
		_ResidueNameEnd="$_NewRes"
	fi
	
	#====================================================================================================================================================
	# Make the mutation using CHIMERA
	#====================================================================================================================================================
	msg -s -n "\t${_ResidueNameStart}${_TargetResID}${_ResidueNameEnd}" | tee -a $LOGFILENAME
	[ -r "${_ABiSS_LIB}/ChimeraMutation.py" ] || fatal 2 "MakeNewMutant_Chimera () ERROR: unable to read file ${_ABiSS_LIB}/ChimeraMutation.py!\n";
	$_chimera --nogui --script "${_ABiSS_LIB}/ChimeraMutation.py ${_FileNamePDB}.pdb -o ${_outputName}.pdb -n ${_TargetResID} -c ${_TargetChainName} -r ${_ResidueNameEnd}" &> Chimera.out
		
	#====================================================================================================================================================
	# 	Building file to test that the mutation worked correctly
	#====================================================================================================================================================
	# VMD_function -t "MUT" will build the files tempFILES/${_FileNamePSF}_TempMol.pdb, tempFILES/${FileNamePSF}_NoSolvent.pdb and ${ProteinName}_M${CurrentMutant}_formatted_autopsf.pdb
	grep "^ATOM" ${_FileNamePDB}.pdb | gawk '{print $3, $4, $5, $6}' > tempFILES/${_FileNamePDB}_NoSolventTEST.pdb
	grep "^ATOM" ${_outputName}.pdb | gawk '{print $3, $4, $5, $6}'  > tempFILES/${_FileNamePDB}_MutTEST.pdb
			
	# actually only the TargetResID is not specific.. I should add the check on TargetChainName
	_flag=`diff -y --suppress-common-lines tempFILES/${_FileNamePDB}_NoSolventTEST.pdb tempFILES/${_FileNamePDB}_MutTEST.pdb | grep -v "$_TargetResID" | wc -l`
	if [ $_flag -le 1 ]; then
		rm tempFILES/${_FileNamePDB}_NoSolventTEST.pdb tempFILES/${_FileNamePDB}_MutTEST.pdb
	else
		msg -s "\nWARNING!! there are differences (beyond the mutation) between the original file and the mutated one!! check the $PWD/tempFILES/*TEST.pdb files"
	fi

}


AVG_and_STD () {
#########################################################################################################################################################
# usage: AVG_and_STD -i <$InputFileName> -c <ColumnNumber> -a <VarNameAVG> -s <VarNameSTD> [OPTIONS]							#
#     -i  <InputFileName>:	The name (with PATH and EXT) of the input file with the Energies.							#
#     -c  <ColumnNumber>:	The column of the input file that is going to be analyzed.								#
#     -a  <VarNameAVG>:		Name of the variable that will store the AVG value.									#
#     -s  <VarNameSTD>:		Name of the variable that will store the STD value.									#
#     OPTIONS:																		#
#     -w  			Suppress the 0 results warnings.			
#     -n  <nSigma>:		Exclude the data that differ for more than "nSigma" STD from the AVG.							#
#     -na <VarNameAVG_2>:	REQUIRED with -n. Name of the variable that will store the AVG value computed with the selected data (-n OPTION)	#
#     -ns <VarNameSTD_2>:	REQUIRED with -n. Name of the variable that will store the STD value computed with the selected data (-n OPTION)	#
#########################################################################################################################################################
	local _AVG="0"
	local _AVGname=
	local _STD="0"		#standard error of the mean
	local _STDname=
	local _FileName=
	local _ColumnNum=
	local _ElementsNum=
	local _nSigma="0"
	
	local _AVGname2=
	local _STDname2=
	local _min=
	local _max=
	local _numExcluded=
	local _warnings="true"
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-i)	shift; _FileName=$1;;
		-c)	shift; _ColumnNum=$1;;
		-a)	shift; _AVGname=$1;;
		-s)	shift; _STDname=$1;;
		-w)	_warnings="false";;
		-n)	shift; _nSigma=$1;;
		-na)	shift; _AVGname2=$1;;
		-ns)	shift; _STDname2=$1;;
		*)	fatal 1 "AVG_and_STD () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	_ElementsNum=`egrep -v "(^#)|(^@)" $_FileName | wc -l`
	[ "$_ElementsNum" -eq "0" ] && fatal 999 "ERROR!! Number of elements on \"AVG_and_STD ()\" equal to 0!"

	#for i in `egrep -v "(^#)|(^@)" $_FileName | gawk -v x="$_ColumnNum" '{print $x}'`; do
	for Val in `gawk -v x="$_ColumnNum" '($1 !~ /^#/ && $1 !~ /^@/) {print $x}' $_FileName`; do
		_AVG=$( gawk -v x="$_AVG" -v y="$Val" 'BEGIN {r=x+y; print r}' )									#$( echo "scale=4; x=$_AVG+$Val; print x;" | bc -l )
	done
	_AVG=$( gawk -v x="$_AVG" -v y="$_ElementsNum" 'BEGIN { r=x/y; printf "%9.4f", r }' )							#$( echo "scale=4; x=$_AVG/$_ElementsNum; print x;" | bc -l )
	#for i in `egrep -v "(^#)|(^@)" $_FileName | gawk -v x="$_ColumnNum" '{print $x}'`; do
	for Val in `gawk -v x="$_ColumnNum" '($1 !~ /^#/ && $1 !~ /^@/) {print $x}' $_FileName`; do
		_STD=$( gawk -v x="$Val" -v xm="$_AVG" -v s=$_STD 'BEGIN { r=(x-xm)^2+s; if(r<0.0001){r=0;} print r }' )						#$( echo "scale=4; x=$_AVG; y=($Val-x)^2+$_STD; print y" | bc -l )
	done
	_STD=$( gawk -v s="$_STD" -v x="$_ElementsNum" 'BEGIN { mod=0; if(x>9){mod=1;} r=sqrt(s/(x-mod)); printf "%9.4f", r }' )				#$( echo "scale=4; x=sqrt($_STD/($_ElementsNum-1)); print x;" | bc -l )
	eval $_AVGname="'$_AVG'"
	eval $_STDname="'$_STD'"
	
	# The next calculations are performed only if the OPTION -n is used
	_numExcluded="0"
	if [ "$_nSigma" -ne "0" ]; then
		_min=$( gawk -v m="$_AVG" -v s="$_STD" -v n="$_nSigma" 'BEGIN {r=(m-s*n); printf "%5.0f", r}' )					#$(echo "scale=0; x=($_AVG-$_nSigma*$_STD)/1; print x;" | bc -l )
		_max=$( gawk -v m="$_AVG" -v s="$_STD" -v n="$_nSigma" 'BEGIN {r=(m+s*n); printf "%5.0f", r}' )					#$(echo "scale=0; x=($_AVG+$_nSigma*$_STD)/1; print x;" | bc -l )
		_AVG="0"
		_STD="0"
		#for i in `egrep -v "(^#)|(^@)" $_FileName | gawk -v x="$_ColumnNum" '{print $x}'`; do
		for Val in `gawk -v x="$_ColumnNum" '($1 !~ /^#/ && $1 !~ /^@/) {print $x}' $_FileName`; do
			if [ "${Val%.*}" -lt "$_min" ] || [ "${Val%.*}" -gt "$_max" ]; then
				let _numExcluded+=1
				continue
			fi
			_AVG=$( gawk -v m="$_AVG" -v x="$Val" 'BEGIN {r=x+m; print r}' )								#$( echo "scale=4; x=$_AVG+$Val; print x;" | bc -l )		
		done
		if [ "${_AVG%.*}" -ne "0" ]; then
			# average valued computed with the data corrected for "nSigma" STD (-n OPTION)
			#$( echo "scale=4; x=$_AVG/($_ElementsNum-$_numExcluded); print x;" | bc -l )
			_AVG=$( gawk -v m="$_AVG" -v n="$_ElementsNum" -v x="$_numExcluded" 'BEGIN {r=m/(n-x); printf "%9.4f", r}' )	
		elif [ "$_warnings" == "true" ]; then
			msg "AVG_and_STD (): something may be WRONG with AVG_2sigma (=${_AVG%.*})! check $PWD/AVG_STD.err"
			echo -e "# Error report of AVG_and_STD () at $(date +%D-%H:%M:%S) \n_AVG=$_AVG\t_STD=$_STD\t\n_min=$_min\t_max=$_max\n_numExcluded$_numExcluded\
			\n_AVGname=$_AVGname\t_STDname$_STDname" >> $PWD/AVG_STD.err
		fi
		#echo "scale=4; x=$_AVG/($_ElementsNum-$_numExcluded); print x;"
		#for i in `egrep -v "(^#)|(^@)" $_FileName | gawk -v x="$_ColumnNum" '{print $x}'`; do
		for Val in `gawk -v x="$_ColumnNum" '($1 !~ /^#/ && $1 !~ /^@/) {print $x}' $_FileName`; do
			if [ "${Val%.*}" -lt "$_min" ] || [ "${Val%.*}" -gt "$_max" ]; then
				continue
			fi
			_STD=$( gawk -v m="$_AVG" -v s="$_STD" -v x=$Val 'BEGIN { r=(x-m)^2+s; if(r<0.0001){r=0;} print r }' )				#$( echo "scale=4; x=$_AVG; y=($Val-x)^2+$_STD; print y" | bc -l )
		done
		#echo "_STD: $_STD \${_STD%.*}: ${_STD%.*}"
		if [ "${_STD%.*}" -ne "0" ]; then
			_flag=$(( $_ElementsNum-$_numExcluded ))
			if [[ "$_flag" == "1" ]]; then
				_STD=$( gawk -v s="$_STD" 'BEGIN {r=sqrt(s); printf "%9.4f", r}' )				#$( echo "scale=4; x=sqrt($_STD/1); print x;" | bc -l )
			else
				#$( echo "scale=4; x=sqrt($_STD/($_ElementsNum-1-$_numExcluded)); print x;" | bc -l )
				_STD=$( gawk -v s="$_STD" -v n="$_ElementsNum" -v x="$_numExcluded" 'BEGIN {r=sqrt(s/(n-1-x)); printf "%9.4f", r}' )	
			fi
		fi
		
		#echo "scale=4; x=sqrt($_STD/($_ElementsNum-1-$_numExcluded)); print x;"
		eval $_AVGname2="'$_AVG'"
		eval $_STDname2="'$_STD'"
	fi
	
}

Weighted_AVG_STD () {
#########################################################################################################################################################
# usage: Weighted_AVG_STD -i <$InputFileName> -c <ColumnNumber> -a <VarNameAVG> -s <VarNameSTD> [OPTIONS]						#
#     -i  <InputFileName>:	The name (with PATH and EXT) of the input file with the Energies.							#
#     -c  <ColumnNumber>:	The column of the input file that is going to be analyzed.								#
#     -a  <VarNameAVG>:		Name of the variable that will store the weighted AVG value.								#
#     -s  <VarNameSTD>:		Name of the variable that will store the STD value.									#
#     OPTIONS:																		#
#     -  <>:		.							#
#########################################################################################################################################################
	local _wAVG="0"
	local _wAVGname=
	local _STD="0"
	local _STDname=
	local _FileName=
	local _ColumnNum=
	local _ElementsNum=
	local _STDcolumn=
	local _Value=
	local _flag="0"
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-i)	shift; _FileName=$1;;
		-c)	shift; _ColumnNum=$1;;
		-a)	shift; _wAVGname=$1;;
		-s)	shift; _STDname=$1;;
		*)	fatal 1 "Weighted_AVG_STD () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	_ElementsNum=`egrep -v "(^#)|(^@)" $_FileName | wc -l`

	for Val in `gawk -v x="$_ColumnNum" '($1 !~ /^#/ && $1 !~ /^@/) {print $x, $(x+2)}' $_FileName`; do		#faccio stampare due colonne di AVG e STD
		if [ "$_flag" -eq "0" ]; then
			_Value="$Val"
			_flag="1"
			#echo "ok"
			continue
		fi
		_STD=$( gawk -v si="$Val" -v sm=$_STD 'BEGIN { if(si==0){r=0;} else{r=(1/(si*si)+sm);} print r}' )
		_wAVG=$( gawk -v xm="$_wAVG" -v si="$Val" -v xi="$_Value" 'BEGIN { if(si==0){r=0;} else{r=xi/(si*si)+xm;} print r}' )
		_flag="0"
		#echo "_Value->$_Value Val->$Val _STD->$_STD _wAVG->$_wAVG"
	done
	_STD=$( gawk -v sm="$_STD" 'BEGIN { if(sm==0){r=0;} else{r=sqrt(1/sm);} printf "%4.2f", r}' )
	_wAVG=$( gawk -v x="$_wAVG" -v sm="$_STD" 'BEGIN {r=sm*sm*x; printf "%6.2f", r }' )
	#echo "_STD->$_STD _wAVG->$_wAVG"
	
	eval $_wAVGname="'$_wAVG'"
	eval $_STDname="'$_STD'"
	
}

Metropolis_check () {
	local _AcceptProb=""
	local _Metropolis_Prob=
	local _Average=${Average[9]}
	local _Metropolis_Temp=${Metropolis_Temp}
	local _RandNum=
	#========================= this is a little bit a problem
	local _Stored_BEnergy=${Stored_BEnergy}
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-ap) 	shift; _AcceptProb=$1;;
		*)	fatal 1 "Metropolis_check () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	
	if [ "$_AcceptProb" == "" ]; then
		# good pseudo Random number between 0 and 1
		_RandNum="$(dd if=/dev/urandom count=1 2>/dev/null | od -t u | head -1 | gawk '{ r=($2%1000000)/1000000; print r }' )"
	else
		_RandNum="$_AcceptProb"
	fi
	
	# Metropolis probability
	_Metropolis_Prob=$( gawk -v Ei="$Stored_BEnergy" -v Ef="${_Average}" -v Tm="${_Metropolis_Temp}" 'BEGIN { Mp=exp(-(Ef-Ei)/Tm); if (Mp<1) printf "%5.4f", Mp; else print "1"}')
	
	# check if I accept the new configuration (1=true) or not (0=false)
	flag="$( gawk -v Mp="${_Metropolis_Prob}" -v Rnum="${_RandNum}" 'BEGIN { if (Rnum<Mp) print "1"; else print "0"}')"
	
	if [ "$flag" -eq "1" ]; then
		msg -n "Random Number:${_RandNum} Metropolis prob:${_Metropolis_Prob} " | tee -a $LOGFILENAME
		msg -s -n "[ =exp(-(${_Average}-$Stored_BEnergy)/${_Metropolis_Temp}) ]" >> $LOGFILENAME
		msg -s "\tNew configuration **ACCEPTED** " | tee -a $LOGFILENAME
		#echo -e -n "\t RN:${_RandNum} MP:${_Metropolis_Prob} **ACCEPTED**  " >> ResidueListName.out
		printf " RN:%-10s MP:%-8s **ACCEPTED**  " "${_RandNum}" "${_Metropolis_Prob}" >> ResidueListName.out
		
		# if the new configuration is accepted I "change branch" in the Mutation Tree
		MTreeIndentation=$MTreeIndentation"  "
		# the old configuration is stored at Mutan_PSF_PDB folder (except for the WT that will not be moved)
		if [ "`grep "**ACCEPTED**" ResidueListName.out | wc -l`" != "1" ]; then
			mv "${pathPSF}${Stored_FileNamePSF}.psf" Mutan_PSF_PDB
			mv "${pathPDB}${Stored_FileNamePDB}.pdb" Mutan_PSF_PDB
		fi
		# I keep the name of the new accepted mutant as 'old configuration' for the next test 
		Stored_FileNamePSF="${FileNamePSF}"
		Stored_pathPSF="${pathPSF}"
		Stored_FileNamePDB="${FileNamePDB}"
		Stored_pathPDB="${pathPDB}"
		# I keep the energy of the configuration for the next test (note: the WT will not be tested)
		Stored_BEnergy="${_Average}"
	else
		msg "Random Number:${_RandNum} Metropolis prob:${_Metropolis_Prob} \tNew configuration **DECLINED** " | tee -a $LOGFILENAME
		#echo -e -n "  RN:${_RandNum} MP:${_Metropolis_Prob} **DECLINED**  " >> ResidueListName.out
		printf " RN:%-10s MP:%-8s **DECLINED**  " "${_RandNum}" "${_Metropolis_Prob}" >> ResidueListName.out
		
		# the refused configuration is stored at Mutan_PSF_PDB folder
		mv "${pathPSF}${FileNamePSF}.psf" Mutan_PSF_PDB
		mv "${pathPDB}${FileNamePDB}.pdb" Mutan_PSF_PDB
		# the previus configuration will be used for the mutation
		FileNamePSF="${Stored_FileNamePSF}"
		pathPSF="${Stored_pathPSF}"
		FileNamePDB="${Stored_FileNamePDB}"
		pathPDB="${Stored_pathPDB}"	
	fi
}

rename_OLDfiles () {
	local _fileName=""
	local _count="0"
	local _file=""
	local _fileExt=""
	local _filePath=""
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-f) 	shift; _file=$1;;
		*)	fatal 1 "rename_OLDfiles () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	
#	${string%substring}	#Deletes shortest match of $substring from back of $string.
#	${string##substring}	#Deletes longest match of $substring from front of $string.
	_fileName=${_file%.*}
	_fileName=${_fileName##*/}
	[ -f $_file ] && _fileExt=".${_file##*.}"
	_filePath=${_file%/*}
	[ "$_filePath" == "$_file" ] && _filePath="./"
	
	while [ 1 -gt 0 ]
	do
		let _count=$_count+1
		[ -e "${_filePath}/${_fileName}${_fileExt}_#OLD${_count}#" ] && continue
		
		mv "${_file}" "${_filePath}/${_fileName}${_fileExt}_#OLD${_count}#"
		break
	done
}

Restart_abiss () {
	# Should add some control on the inputs value of the variables
	local _Save="false"
	local _SaveFile=
	local _CurrentMutant=
	local _ProgramCheck=
	local _config=
	local _Selection=
	local _restartPrg="true"
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-r)	shift; _restartPrg=$1;;
		-s) 	shift; _Save="true"; _SLFile=$1;;
		-l)	shift; _SLFile=$1
			_CurrentMutant=`gawk '($1 ~ /^CurrentMutant/) {print $2}' $_SLFile`
			_ProgramCheck=`gawk '($1 ~ /^ProgramCheck/) {print $2}' $_SLFile`
			_config=`gawk '($1 ~ /^config/) {print $2}' $_SLFile`
			_Selection=`gawk '($1 ~ /^Selection/) {print $2}' $_SLFile`
			;;
		*)	fatal 1 "Restart_abiss () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	
	# Old version.. -s is not more used
	if [ "$_Save" == "true" ]; then
		sed -r -i -e "s/CurrentMutant= .*/CurrentMutant= $CurrentMutant/g" $_SLFile
		sed -r -i -e "s/ProgramCheck= .*/ProgramCheck= $ProgramCheck/g" $_SLFile
		sed -r -i -e "s/config= .*/config= $config/g" $_SLFile
		sed -r -i -e "s/Selection= .*/Selection= $Selection/g" $_SLFile
		RestartPrg="false"
		#echo "$skip"
		return 0
	fi
	
	if [ "$_restartPrg" == "false" ]; then
		sed -r -i -e "s/CurrentMutant= .*/CurrentMutant= $CurrentMutant/g" $_SLFile
		sed -r -i -e "s/ProgramCheck= .*/ProgramCheck= $ProgramCheck/g" $_SLFile
		sed -r -i -e "s/config= .*/config= $config/g" $_SLFile
		sed -r -i -e "s/Selection= .*/Selection= $Selection/g" $_SLFile		
		return 0
	fi
	
	echo -e "Restart_abiss-> CurrentMutant:$_CurrentMutant/$CurrentMutant\tProgramCheck:$_ProgramCheck/$ProgramCheck\tconfig:$_config/$config\tSelection:$_Selection/$Selection\tSkip:$Skip"
	
	Skip="false"
	if [ "$_CurrentMutant" != "$CurrentMutant" ]; then
		Skip="true"
	elif [ "$_ProgramCheck" != "$ProgramCheck" ]; then
		Skip="true"
	else
		if [ "$_ProgramCheck" == "8-1" ] || [ "$_ProgramCheck" == "8-2" ] || [ "$_ProgramCheck" == "8-3" ] || [ "$_ProgramCheck" == "8-4" ]; then
			[ "$_config" != "$config" ] && Skip="true"
		fi
		# It is not perfect but it doesn't waste much time
		if [ "$_ProgramCheck" == "8-2" ] || [ "$_ProgramCheck" == "8-3" ]; then
			[ "$_Selection" != "$Selection" ] && Skip="true"
		fi
	fi
	
	# If I don't have to skip.. set the RestartPrg to false and next time I will save
	if [ "$Skip" == "false" ]; then
		RestartPrg="false"		
	fi
	#echo "$skip"
}




Minim_and_sMD () {
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	#@ 	minimization and small MD						@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	
	ProgramCheck="5-1"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
	if [ "$Skip" == "false" ]; then
		msg "Starting namd_config.sh for minimization " >> $LOGFILENAME
		#msg "namd_config.sh -psf ${pathPSF}${FileNamePSF} -pdb ${pathPDB}${FileNamePDB} -t $MIN_TempK -o ${ProteinName}_minim -p ${FileNameCHARMMpar[@]} -c minim.conf \
		#	-s minim -m $minimize -n $MIN_run -f $MIN_restartfreq $MIN_dcdfreq $MIN_xstFreq $MIN_outputEnergies $MIN_outputPressure" &>> $LOGFILENAME
		$namd_config -s minim -ff $ForceField -pv "$VMD" -psf ${pathPSF}${FileNamePSF} -top ${pathTOP}${FileNameTOP} -pdb ${pathPDB}${FileNamePDB} -t $MIN_TempK -o ${ProteinName}_minim -p ${FileNameCHARMMpar[@]} -c minim.conf \
			-m $minimize -n $MIN_run -f $MIN_restartfreq $MIN_dcdfreq $MIN_xstFreq $MIN_outputEnergies $MIN_outputPressure &>> $LOGFILENAME
		# | tee -a $LOGFILENAME
		exitST="$?"
		[ $exitST == 0 ] || fatal 51 "fatal: namd_config ERROR $exitST."
	fi
	
	ProgramCheck="5-2"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
	if [ "$Skip" == "false" ]; then
		msg -n "$(date +%H:%M:%S) Starting NAMD for the minimization... " | tee -a $LOGFILENAME

		msg -s " " | tee -a $LOGFILENAME
		#echo "$NAMD $NAMD_options minim.conf > minim.log "
		$NAMD $NAMD_options minim.conf > minim.log 
		exitST="$?"
		if [ $exitST -gt 0 ]; then
			flag=`grep "Periodic cell has become too small for original patch grid" minim.log | wc -l`
			if [ $flag -eq 0 ]; then
				fatal 52 "fatal on brief MD: NAMD ERROR $exitST."
			fi
		fi
	fi
	
	
	#ProgramCheck="5-3"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
	#if [ "$Skip" == "false" ]; then
	#	#Restart_abiss -s "${CurrentPath}RestartPrg.out"
	#	msg "Starting VMD to extract the last frame .pdb" | tee -a $LOGFILENAME
	#	VMD_function -psf "${pathPSF}${FileNamePSF}" -pdb "${pathPDB}${FileNamePDB}" -t "LAST" -dcd "${ProteinName}_minim"
	#fi
	
}

# OLD AND NOT IN USE (22 APR 2021)
longMD () {
	# OLD AND NOT IN USE (22 APR 2021)
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	#@ 	long MD simulation							@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

	# building the input file for relaunch a simulation on NAMD.
	ProgramCheck="6-1"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
	if [ "$Skip" == "false" ]; then
		msg "Starting namd_config.sh for long MD simulation " >> $LOGFILENAME
		#msg "namd_config.sh -psf ${pathPSF}${FileNamePSF}.psf -pdb ${pathPDB}${FileNamePDB}_minim_last_F1.pdb -t $lMD_TempK -o ${FileNamePDB}_MD -p ${FileNameCHARMMpar[@]} -c MD.conf \
		#	-s MD -n $lMD_run -f $lMD_restartfreq $lMD_dcdfreq $lMD_xstFreq $lMD_outputEnergies $lMD_outputPressure" &>> $LOGFILENAME
		$namd_config -s restart -ff $ForceField -pv "$VMD" -psf ${pathPSF}${FileNamePSF} -top ${pathTOP}${FileNameTOP} -pdb ${pathPDB}${FileNamePDB} -t $lMD_TempK -o ${ProteinName}_MD -p ${FileNameCHARMMpar[@]} -c MD.conf -in ${ProteinName}_minim -n $lMD_run \
			-f $lMD_restartfreq $lMD_dcdfreq $lMD_xstFreq $lMD_outputEnergies $lMD_outputPressure &>> $LOGFILENAME
		exitST="$?"
		[ $exitST == 0 ] || fatal 61 "fatal: namd_config ERROR $exitST."
	fi
	
	# running a long MD simulation using NAMD
	ProgramCheck="6-2"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
	if [ "$Skip" == "false" ]; then
		msg -n "$(date +%H:%M:%S) Starting NAMD for the long MD simulation... " | tee -a $LOGFILENAME
		msg -s " " | tee -a $LOGFILENAME
		$NAMD $NAMD_options MD.conf > MD.log 
		exitST="$?"
		#[ $exitST == 0 ] || fatal 62 "fatal: NAMD ERROR $exitST."
		if [ $exitST -gt 0 ]; then
			flag=`grep "Periodic cell has become too small for original patch grid" MD.log | wc -l`
			if [ $flag -gt 0 ]; then
				$namd_config -s restart -ff $ForceField -pv "$VMD" -psf ${pathPSF}${FileNamePSF} -top ${pathTOP}${FileNameTOP} -pdb ${pathPDB}${FileNamePDB} -t $lMD_TempK -o ${ProteinName}_MDr -p ${FileNameCHARMMpar[@]} -c MD_restart.conf  -n $lMD_run \
					-in ${ProteinName}_MD -f $lMD_restartfreq $lMD_dcdfreq $lMD_xstFreq $lMD_outputEnergies $lMD_outputPressure &>> $LOGFILENAME
				exitST="$?"
				[ $exitST == 0 ] || fatal 751 "fatal: namd_config ERROR $exitST."
				$NAMD $NAMD_options MD_restart.conf > MD_restart.log 
				exitST="$?"
				[ $exitST == 0 ] || fatal 752 "fatal: NAMD ERROR $exitST."
			else
				fatal 75 "fatal on brief MD: NAMD ERROR $exitST."
			fi
		fi
	fi
	
	if [ "$ConfigNum" == 0 ]; then
		flag=$( echo " scale=5; r=($lMD_run-$GIBS_start)*0.000002; if(r>1) print r else print \"0\",r;" | bc)
		msg "$(date +%H:%M:%S) **ConfigNum** set to 0. The Energy will be computed on the last ${flag}ns" | tee -a $LOGFILENAME
		VMD_function -psf "${pathPSF}${FileNamePSF}" -pdb "${pathPDB}${FileNamePDB}" -t "LAST" -n "0" -dcd "${ProteinName}_MD"	
		[ $ForceField == "AMBER" ] && cp ${pathTOP}${FileNameTOP}.top ${ProteinName}_MD_last_F0.top
		[ $ForceField == "AMBER" ] && FixPDB_adHOC ${ProteinName}_MD_last_F0 
	else
	# if $ConfigNum!=0 -> run vmd in order to build a pdb for the last "$ConfigNum" of the long MD
		ProgramCheck="6-3"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
		if [ "$Skip" == "false" ]; then
			# I want to build n configuration of the molecule and run small MD on them. I need to build a new water box for every configuration in order to avoid problems with PBC
			msg "$(date +%H:%M:%S) Starting VMD to extract **$ConfigNum** .pdb configurations" | tee -a $LOGFILENAME
			VMD_function -psf "${pathPSF}${FileNamePSF}" -pdb "${pathPDB}${FileNamePDB}" -t "LAST" -n "$ConfigNum" -dcd "${ProteinName}_MD"			
		
			# build a folder for every configuration and copy/move the input file there. 
			msg "Making a folder for every configuration" >> $LOGFILENAME
			for config in `seq 1 $ConfigNum`; do		
				mv ${ProteinName}_MD_last_F${config}_autopsf.pdb ${ProteinName}_MD_last_F${config}.pdb
				mv ${ProteinName}_MD_last_F${config}_autopsf.psf ${ProteinName}_MD_last_F${config}.psf				
			
				msg "Folder ${ProteinName}_${MutantLabel}_conf${config} ->moving: `ls -x ${ProteinName}_MD_last_F${config}.pdb ${ProteinName}_MD_last_F${config}.psf`" &>> $LOGFILENAME
				mkdir -p ${ProteinName}_${MutantLabel}_conf${config}
				#cp ${FileNamePSF}.psf ./${FileNamePDB}_$config
				mv ${ProteinName}_MD_last_F${config}.pdb ${ProteinName}_MD_last_F${config}.psf ./${ProteinName}_${MutantLabel}_conf${config}
			done
			# I need it only 1 time
			msg " ->removing temporary files *_formatted* *_PROTEIN.* *_autopsf.log" &>> $LOGFILENAME
			rm *_formatted* *_PROTEIN.* *.log 2> /dev/null
		fi
	fi
	
}
# OLD AND NOT IN USE (22 APR 2021)
smallMD () {
	# OLD AND NOT IN USE (22 APR 2021)
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	#@ 				small MD simulation 				@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	
#	[ "$RestartPrg" == "true" ] || msg -n "Folder ${ProteinName}_${MutantLabel}_conf${config} : " | tee -a $LOGFILENAME
#	mkdir -p ${ProteinName}_${MutantLabel}_conf${config}		# there is 1 option where I would need to enter the folder even if there is nothing
#	cd ${ProteinName}_${MutantLabel}_conf${config}
#	mkdir -p Results
#	mkdir -p tempFILES
	
	# building the --minimization-- conf
	ProgramCheck="7-1"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
	if [ "$Skip" == "false" ]; then
		msg -s "" >> $LOGFILENAME
		msg -n "Starting namd_config.sh for minimization \t" >> $LOGFILENAME
		#msg "namd_config.sh -psf ${pathPSF}${FileNamePSF} -pdb ${pathPDB}${FileNamePDB} -t $MIN_TempK -o ${ProteinName}_minim -p ${FileNameCHARMMpar[@]} -c minim.conf \
		#	-s minim -m $minimize -n $MIN_run -f $MIN_restartfreq $MIN_dcdfreq $MIN_xstFreq $MIN_outputEnergies $MIN_outputPressure" &>> $LOGFILENAME
		$namd_config -s minim -ff $ForceField -pv "$VMD" -psf ${pathPSF}${FileNamePSF} -top ${pathTOP}${FileNameTOP} -pdb ${ProteinName}_MD_last_F${config} -t $MIN_TempK -o ${ProteinName}_MD_last_F${config}_minim -p ${FileNameCHARMMpar[@]} -c minim.conf \
			-m $minimize -n $MIN_run -f $MIN_restartfreq $MIN_dcdfreq $MIN_xstFreq $MIN_outputEnergies $MIN_outputPressure &>> $LOGFILENAME
		# | tee -a $LOGFILENAME
		exitST="$?"
		[ $exitST == 0 ] || fatal 71 "fatal: namd_config ERROR $exitST."
	fi
	
	# --minimization--
	ProgramCheck="7-2"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
	if [ "$Skip" == "false" ]; then
		msg -n "\t$(date +%H:%M:%S) Starting NAMD for the minimization... " | tee -a $LOGFILENAME
		#echo "$NAMD $NAMD_options minim.conf > minim.log "
		$NAMD $NAMD_options minim.conf > minim.log 
		exitST="$?"
		if [ $exitST -gt 0 ]; then
			flag=`grep "Periodic cell has become too small for original patch grid" minim.log | wc -l`
			if [ $flag -eq 0 ]; then
				fatal 72 "fatal on brief MD: NAMD ERROR $exitST."
			fi
		fi
	fi
	
	
	# building the input file for --small MD-- using NAMD
	ProgramCheck="7-3"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
	if [ "$Skip" == "false" ]; then
		msg -s "" >> $LOGFILENAME
		msg -n "Starting namd_config.sh for brief MD simulation \t" >> $LOGFILENAME
		$namd_config -s restart -ff $ForceField -pv "$VMD" -psf ${pathPSF}${FileNamePSF} -top ${pathTOP}${FileNameTOP} -pdb ${ProteinName}_MD_last_F${config} -t $fMD_TempK -o ${ProteinName}_MD -p ${FileNameCHARMMpar[@]} -c MD.conf -n $fMD_run \
				-in ${ProteinName}_MD_last_F${config}_minim -f $fMD_restartfreq $fMD_dcdfreq $fMD_xstFreq $fMD_outputEnergies $fMD_outputPressure &>> $LOGFILENAME
		#$namd_config -pv "$VMD" -psf ${ProteinName}_MD_last_F${config} -pdb ${ProteinName}_MD_last_F${config} -t $fMD_TempK -o ${ProteinName}_MD -p ${FileNameCHARMMpar[@]} -c MD.conf -s MD -n $fMD_run \
		#	-gs $GIBS_start -f $fMD_restartfreq $fMD_dcdfreq $fMD_xstFreq $fMD_outputEnergies $fMD_outputPressure &>> $LOGFILENAME
		# | tee -a $LOGFILENAME
		exitST="$?"
		[ $exitST == 0 ] || fatal 73 "fatal on brief MD: namd_config ERROR $exitST."
	fi
	
	# running a --small MD-- simulation using NAMD
	ProgramCheck="7-4"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
	if [ "$Skip" == "false" ]; then
		msg -s "\tStarting NAMD for small MD... " | tee -a $LOGFILENAME
		#msg -s " " | tee -a $LOGFILENAME
		$NAMD $NAMD_optionsB MD.conf > MD.log 
		exitST="$?"
		if [ $exitST -gt 0 ]; then
			flag=`grep "Periodic cell has become too small for original patch grid" MD.log | wc -l`
			if [ $flag -gt 0 ]; then
				$namd_config -s restart -ff $ForceField -pv "$VMD" -psf ${pathPSF}${FileNamePSF} -top ${pathTOP}${FileNameTOP} -pdb ${ProteinName}_MD_last_F${config} -t $fMD_TempK -o ${ProteinName}_MDr -p ${FileNameCHARMMpar[@]} -c MD_restart.conf -n $fMD_run \
					-in ${ProteinName}_MD -f $fMD_restartfreq $fMD_dcdfreq $fMD_xstFreq $fMD_outputEnergies $fMD_outputPressure &>> $LOGFILENAME
				exitST="$?"
				[ $exitST == 0 ] || fatal 741 "fatal: namd_config ERROR $exitST."
				$NAMD $NAMD_options MD_restart.conf > MD_restart.log 
				exitST="$?"
				[ $exitST == 0 ] || fatal 742 "fatal: NAMD ERROR $exitST."
			else
				fatal 74 "fatal on brief MD: NAMD ERROR $exitST."
			fi
		fi
	fi

}
# USED ON NAMD ABiSS
computeGIBS () {
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	#@ 	GBIS simulation of COMPLEX, RECELPTOR and LIGAND for each of the former configurations			@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	local _inputSERVICE="NoSelect"
	local _FilePSF=${ProteinName}_MD_last_F${config}
	local _FilePDB=${ProteinName}_MD_last_F${config}
	local _FileTOP=${ProteinName}_MD_last_F${config}
	local _FileDCD=${ProteinName}_MD
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-i) 	shift; _inputSERVICE=$1;;
		-psf)	shift; _FilePSF=$1;;
		-pdb)	shift; _FilePDB=$1;;
		-top)	shift; _FileTOP=$1;;
		-dcd)	shift; _FileDCD=$1;;
		*)	fatal 1 "computeGIBS () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	
	
	case $_inputSERVICE in
	#initialization
	INIT)	ProgramCheck="8-0"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
		if [ "$Skip" == "false" ]; then
			[ -f "B_energy_${MutantLabel}.out" ] && rename_OLDfiles -f "B_energy_${MutantLabel}.out"
			printf "%-15s\t%-15s\t\t%-15s\t\t%-15s\t\t%-15s\t\t%-15s\t\t%-15s\t\t%-15s\t\t%-15s\n" "#Conf." "BOND" "ANGLE" "DIHED" "IMPRP" "ELECT" "VDW" "BindingEnergy" "B_Energy_ele-vdw" \
				> ./B_energy_${MutantLabel}.out
			printf "%-15s\t%-15s\t\t%-15s\t\t%-15s\t\t%-15s\t\t%-15s\t\t%-15s\t\t%-15s\t\t%-15s\n" "#Conf." "BOND" "ANGLE" "DIHED" "IMPRP" "ELECT" "VDW" "BindingEnergy" "B_Energy_ele-vdw" \
				> ./tempFILES/B_energy_${MutantLabel}2s.temp
		fi		
		;;
	#get Trajectory for every configuration (complex, ligand and receptor)
	gTRJ)	ProgramCheck="8-1"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
		if [ "$Skip" == "false" ]; then
			msg "\t$(date +%H:%M:%S) Starting VMD to build the only-protein dcd of the COMPLEX, LIGAND and RECEPTOR configurations" | tee -a $LOGFILENAME
			VMD_function -psf "${_FilePSF}" -pdb "${_FilePDB}" -t "SEL" -dcd "${_FileDCD}" -s "$Complex" "$Receptor" "$Ligand" -m "complex" "receptor" "ligand" -o "${ProteinName}_MD"
			if [ $ForceField == "AMBER" ]; then 
				MakeAmberTOP -pdb ${ProteinName}_MD_first_complex -o ${ProteinName}_MD_first_complex
				MakeAmberTOP -pdb ${ProteinName}_MD_first_receptor -o ${ProteinName}_MD_first_receptor
				MakeAmberTOP -pdb ${ProteinName}_MD_first_ligand -o ${ProteinName}_MD_first_ligand
			fi
		fi
		;;
	#compute GBIS Energy (running the GBIS simulation and making the analysis)
	# I Want the SASA contribution separated from the coulomb contribution of the protein and solvent! I must run NAMD 3 time to get these contribution separated
	cENG)	ProgramCheck="8-2"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
		if [ "$Skip" == "false" ]; then
			msg "\tStarting namd_config.sh for GBIS simulation of **$Selection** selection" >> $LOGFILENAME					
			#RUNNING NAMD_CONFIG to get the conf file to run namd-gbis **SASA set off to have PNLY Ccoulomb contribution**
			#echo "$namd_config -s GBIS -sa off -ff $ForceField -pv $VMD -psf ${ProteinName}_MD_$Selection -top ${ProteinName}_MD_first_$Selection -pdb ${ProteinName}_MD_first_$Selection -t $GBIS_TempK -o ${ProteinName}_GBIS_${Selection} -p ${FileNameCHARMMpar[@]} -c GBIS_$Selection.conf -d ${ProteinName}_MD_$Selection.dcd -f $fMD_restartfreq $fMD_dcdfreq $fMD_xstFreq $fMD_outputEnergies $fMD_outputPressure -st $surfaceTension -ic $ionConcentration -gs $GIBS_start &>> $LOGFILENAME"
			$namd_config -s GBIS -sa "off" -ff $ForceField -pv "$VMD" -psf ${ProteinName}_MD_$Selection -top ${ProteinName}_MD_first_$Selection -pdb ${ProteinName}_MD_first_$Selection -t $GBIS_TempK -o ${ProteinName}_GBIS_${Selection} -p ${FileNameCHARMMpar[@]} -c GBIS_$Selection.conf -d ${ProteinName}_MD_$Selection.dcd -f $fMD_restartfreq $fMD_dcdfreq $fMD_xstFreq $fMD_outputEnergies $fMD_outputPressure -st $surfaceTension -ic $ionConcentration -gs $GIBS_start &>> $LOGFILENAME
			exitST="$?"
			[ $exitST == 0 ] || fatal 82 "fatal on GIBS simulation (sasa off): namd_config ERROR $exitST."
		fi
		
		ProgramCheck="8-3"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
		if [ "$Skip" == "false" ]; then
			msg -n "\tStarting NAMD for the GBIS analysis of **$Selection** selection..." | tee -a $LOGFILENAME
			# RUNNING NAMD TO GET THE GBIS ENERGIES
			$NAMD GBIS_$Selection.conf > GBIS_$Selection.log 
			exitST="$?"
			( [ $exitST != 0 ] || [ "`grep "Exiting prematurely" GBIS_$Selection.log`" != "" ] ) && fatal 83 "fatal on GBIS simulation (sasa off): NAMD ERROR $exitST."
		fi
				
		ProgramCheck="8-4"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
		if [ "$Skip" == "false" ]; then	
			#RUNNING NAMD_CONFIG to get the conf file to run namd-gbis **SASA set off to have PNLY Ccoulomb contribution**
			$namd_config -s GBIS -sa "on" -ff $ForceField -pv "$VMD" -psf ${ProteinName}_MD_$Selection -top ${ProteinName}_MD_first_$Selection -pdb ${ProteinName}_MD_first_$Selection -t $GBIS_TempK -o ${ProteinName}_GBIS_$Selection -p ${FileNameCHARMMpar[@]} -c GBIS_$Selection.conf -d ${ProteinName}_MD_$Selection.dcd -f $fMD_restartfreq $fMD_dcdfreq $fMD_xstFreq $fMD_outputEnergies $fMD_outputPressure -st $surfaceTension -ic $ionConcentration -gs $GIBS_start &>> $LOGFILENAME
			exitST="$?"
			[ $exitST == 0 ] || fatal 84 "fatal on GIBS simulation (sasa on): namd_config ERROR $exitST."
		fi
		
		ProgramCheck="8-5"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
		if [ "$Skip" == "false" ]; then
			msg -n -s "..." | tee -a $LOGFILENAME
			# RUNNING NAMD TO GET THE GBIS ENERGIES
			$NAMD GBIS_$Selection.conf > GBIS-SASA_$Selection.log 
			exitST="$?"
			( [ $exitST != 0 ] || [ "`grep "Exiting prematurely" GBIS_$Selection.log`" != "" ] ) && fatal 85 "fatal on GBIS simulation (sasa on): NAMD ERROR $exitST."
		fi
				
		ProgramCheck="8-6"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
		if [ "$Skip" == "false" ]; then	
			#RUNNING NAMD_CONFIG to get the conf file to run namd-gbis **SASA set off to have PNLY Ccoulomb contribution**
			$namd_config -s ENG -ff $ForceField -pv "$VMD" -psf ${ProteinName}_MD_$Selection -top ${ProteinName}_MD_first_$Selection -pdb ${ProteinName}_MD_first_$Selection -t $GBIS_TempK -o ${ProteinName}_GBIS_$Selection -p ${FileNameCHARMMpar[@]} -c GBIS_$Selection.conf -d ${ProteinName}_MD_$Selection.dcd -f $fMD_restartfreq $fMD_dcdfreq $fMD_xstFreq $fMD_outputEnergies $fMD_outputPressure -st $surfaceTension -ic $ionConcentration -gs $GIBS_start &>> $LOGFILENAME
			exitST="$?"
			[ $exitST == 0 ] || fatal 86 "fatal on ENG simulation: namd_config ERROR $exitST."
		fi
		
		ProgramCheck="8-7"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
		if [ "$Skip" == "false" ]; then
			msg -n -s "...    " | tee -a $LOGFILENAME
			# RUNNING NAMD TO GET THE GBIS ENERGIES
			$NAMD GBIS_$Selection.conf > ENG_$Selection.log 
			exitST="$?"
			( [ $exitST != 0 ] || [ "`grep "Exiting prematurely" GBIS_$Selection.log`" != "" ] ) && fatal 87 "fatal on ENG simulation: NAMD ERROR $exitST."
		fi

		ProgramCheck="8-8"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
		if [ "$Skip" == "false" ]; then
			# STARTING THE ANALYSIS OF THE ENERGIES
			msg -s "\tStarting the analysis" | tee -a $LOGFILENAME
			# Setup the output file
			echo -e "# Output file for the binding energies of configuration $config. \n# Selection: $Selection " > Results/GBIS_${Selection}_energies.out
			echo -e "# TS->TimeStep[ps]         energies[Kcal/mol] " >> Results/GBIS_${Selection}_energies.out
			echo -e "# AVGa=Average over all the values; STDa=standard deviation of AVGa" >> Results/GBIS_${Selection}_energies.out
			echo -e "# AVG2s=Average over all the values within $NumSigma standard deviations(using AVGa and STDa); STDa=standard deviation of AVG2s\n#" >> Results/GBIS_${Selection}_energies.out
			# If the simulation is too short, namd does not print ETITLE -> avoid grep ETITLE
			echo "# TS    BOND            ANGLE           DIHED           IMPRP           ELECT-PROT           VDW        POTENTIAL    B_Energy_ele-vdw        ELECT-SOL    SASA" >> Results/GBIS_${Selection}_energies.out
			# Coping the energies from the NAMDoutput to my output file "Results/GBIS_${Selection}_energies.out"
			gawk '$1 ~ /ENERGY:/ {printf "%05i\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\n", $2*0.002, $3, $4, $5, $6, $7, $8}' \
				GBIS_$Selection.log > Results/temp1.out
			gawk '$1 ~ /ENERGY:/ {printf "%-10.3f\t%-10.3f\n", $14, $7}' GBIS-SASA_$Selection.log > Results/temp2.out
			gawk '$1 ~ /ENERGY:/ {printf "%-10.3f\n", $7}' ENG_$Selection.log  > Results/temp3.out
			paste Results/temp1.out Results/temp2.out Results/temp3.out -d "\t" > Results/temp.out
			
			gawk '{B=$9+$7;S=$9-$6;E=$6-$10; printf "%05i\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\n", $1, $2, $3, $4, $5, $10, $7, $8, B, E, S}' \
				Results/temp.out >> Results/GBIS_${Selection}_energies.out
			rm Results/temp*.out 
			# Computing the averages and standard deviations
			for column in `seq 2 11`; do	
				AVG_and_STD -i "Results/GBIS_${Selection}_energies.out" -c "$column" -a "Average[$column]" -s "StDeviation[$column]" -n "$NumSigma" -na "Average_2sigma[$column]" -ns "StDeviation_2sigma[$column]"
			done
			printf "#\n@AVGa\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\n" ${Average[@]}  >> Results/GBIS_${Selection}_energies.out
			printf "@STDa\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\n" ${StDeviation[@]} >> Results/GBIS_${Selection}_energies.out
			printf "#\n@AVG2s\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\n" ${Average_2sigma[@]} >> Results/GBIS_${Selection}_energies.out
			printf "@STD2s\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\n" ${StDeviation_2sigma[@]} >> Results/GBIS_${Selection}_energies.out
		fi

		

		#echo "done2"
		;;
	#Compute averages and saving the results
	AVG)	ProgramCheck="8-9"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
		if [ "$Skip" == "false" ]; then
			
			# Build the file with the Binding energy contributions (i.e. complex - ligand - receptor) "Results/BindingEnergy.out" for configuration $config
			paste Results/GBIS_complex_energies.out Results/GBIS_receptor_energies.out Results/GBIS_ligand_energies.out | egrep -v "(^#)|(^@)" > Results/temp_energies.temp
			egrep "(^#)" Results/GBIS_complex_energies.out > Results/BindingEnergy.out
			gawk '{ printf "%05i\t", $1; for(i=2;i<=11;i++) {r=$i-$(i+11)-$(i+22); printf "%-10.3f\t", r} printf "\n" }' Results/temp_energies.temp >> Results/BindingEnergy.out
			# Compute the averages and standard deviations
			for column in `seq 2 11`; do	
				AVG_and_STD -w -i "Results/BindingEnergy.out" -c "$column" -a "DeltaG[$column]" -s "StdG[$column]" -n "$NumSigma" -na "DeltaG_2sigma[$column]" -ns "StdG_2sigma[$column]"
			done
			printf "#\n@AVGa\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\n" ${DeltaG[@]}  >> Results/BindingEnergy.out
			printf "@STDa\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\n" ${StdG[@]} >> Results/BindingEnergy.out
			printf "#\n@AVG2s\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\n" ${DeltaG_2sigma[@]} >> Results/BindingEnergy.out
			printf "@STD2s\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\t%-10.3f\t     %-10.3f\t%-10.3f\n" ${StdG_2sigma[@]} >> Results/BindingEnergy.out
			rm Results/temp_energies.temp
			
			msg "\tComputing the BINDING energy for **Conf.$config** " | tee -a $LOGFILENAME
		
			# Copy the average results for configuration $config on the output file for the whole mutant on two files (the second one is for the sigma correction and will be append on the bottom later)
			printf "a-%05i\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\n" $config \
				${DeltaG[2]} ${StdG[2]} ${DeltaG[3]} ${StdG[3]} ${DeltaG[4]} ${StdG[4]} ${DeltaG[5]} ${StdG[5]} ${DeltaG[6]} ${StdG[6]} ${DeltaG[7]} ${StdG[7]} \
				${DeltaG[8]} ${StdG[8]} ${DeltaG[9]} ${StdG[9]} ${DeltaG[10]} ${StdG[10]} ${DeltaG[11]} ${StdG[11]} >> ../B_energy_${MutantLabel}.out
			printf "2s-%05i\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\t%7.1f +/- %-4.1f\n" $config \
				${DeltaG_2sigma[2]} ${StdG_2sigma[2]} ${DeltaG_2sigma[3]} ${StdG_2sigma[3]} ${DeltaG_2sigma[4]} ${StdG_2sigma[4]} ${DeltaG_2sigma[5]} ${StdG_2sigma[5]} ${DeltaG_2sigma[6]} ${StdG_2sigma[6]} ${DeltaG_2sigma[7]} \
				${StdG_2sigma[7]} ${DeltaG_2sigma[8]} ${StdG_2sigma[8]}  ${DeltaG_2sigma[9]} ${StdG_2sigma[9]}  ${DeltaG_2sigma[10]} ${StdG_2sigma[10]} ${DeltaG_2sigma[11]} ${StdG_2sigma[11]} >> ../tempFILES/B_energy_${MutantLabel}2s.temp

			msg "\tDONE"
		fi
		
		;;
	*)
		fatal 5 "computeGIBS() ERROR: Type of service NOT recognized!! (options are INIT / gTRJ / cENG / AVG)"
		;;
	esac

}

mergingDATA () {
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	#@ 	MERGING DATA and computing of weighter mean binding energy			@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

	ProgramCheck="9-1"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
	if [ "$Skip" == "false" ]; then
	
		# Merge the two output file for the binding energy
		echo "" >> B_energy_${MutantLabel}.out
		cat tempFILES/B_energy_${MutantLabel}2s.temp >> B_energy_${MutantLabel}.out
		rm tempFILES/B_energy_${MutantLabel}2s.temp
	fi

	ProgramCheck="9-2"; Restart_abiss -l ${CurrentPath}RestartPrg.out -r $RestartPrg
	if [ "$Skip" == "false" ]; then
		grep "^a-" B_energy_${MutantLabel}.out > tempFILES/B_energy_a.temp
		grep "^2s-" B_energy_${MutantLabel}.out > tempFILES/B_energy_2s.temp
		msg -n "$(date +%H:%M:%S) MERGING DATA.." | tee -a $LOGFILENAME
		msg -s "Computing the WEIGHTED MEAN BINDING energy for **${MutantLabel}** " | tee -a $LOGFILENAME
		for column in `seq 2 9`; do	
			flag=$(( $column + 2*($column-2) ))		# that is because I need to skip the '*/-' and std values
			Weighted_AVG_STD -i tempFILES/B_energy_a.temp -c $flag -a Average[$column] -s StDeviation[$column]
			Weighted_AVG_STD -i tempFILES/B_energy_2s.temp -c $flag -a Average_2sigma[$column] -s StDeviation_2sigma[$column]
		done
		# Write the averages and stds on the output file
		printf "\n@AVGa\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\n" ${Average[@]}  >> B_energy_${MutantLabel}.out
		printf "@STDa\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\n" ${StDeviation[@]} >> B_energy_${MutantLabel}.out
		printf "\n@AVG2s\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\n" ${Average_2sigma[@]} >> B_energy_${MutantLabel}.out
		printf "@STD2s\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\t\t%-10.3f\n" ${StDeviation_2sigma[@]} >> B_energy_${MutantLabel}.out
		# Delete the temporary files
		rm tempFILES/B_energy_a.temp tempFILES/B_energy_2s.temp
	fi
}


MakeAmberTOP () {
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	#@ 	MAKING topology file for AMBER force field					@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	
	local _FilePDB=${ProteinName}_MD_last_F0
	local _FileOUT=${ProteinName}_MD_last_F0
	local _Solvate="no"
	local _molCharge=
	local _molWater=
	local _pIons=
	local _nIons=
	
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-pdb)	shift; _FilePDB=$1;;
		-o)	shift; _FileOUT=$1;;
		-sol)	shift; _Solvate="yes";;
		*)	fatal 1 "MakeAmberTOP () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	
	_FilePDB="${_FilePDB%.pdb}"
	_FileOUT="${_FileOUT%.*}"
	
	#MAKE a script for tLeap
	echo -e > tempFILES/tleap.temp " "
	for num in `seq 1 $NumberTopAMBER`; do echo -e >> tempFILES/tleap.temp "source ${FileNameAMBERtop[$num]}"; done
	echo -e >> tempFILES/tleap.temp "pdbFILE = loadPdb \"${_FilePDB}.pdb\""
	
	#echo "solvate: $_Solvate"
	if [ ${_Solvate} == "yes" ]; then
		#echo "entereddddd"
		echo -e -n >> tempFILES/tleap.temp "
			\nsolvatebox pdbFILE SPCBOX 14.0
			\nquit"
		tleap -f tempFILES/tleap.temp &> tleap.out
		
		_molWater=`grep "residues." tleap.out | gawk '{ print $2 }'`
		#wc -l`+`grep "CA  HI[SDEP]" $_FilePDB
		_molCharge=$( echo "`grep "CA  LYS" ${_FilePDB}.pdb | wc -l` `grep "CA  ARG" ${_FilePDB}.pdb | wc -l` `grep "CA  ASP" ${_FilePDB}.pdb | wc -l` `grep "CA  GLU" ${_FilePDB}.pdb | wc -l`" | gawk '{ r=$1+$2-$3-$4; printf "%5i", r}' )
		if [ $_molCharge -ge "0" ]; then
			_pIons=` echo "$_molWater 0.0027" | gawk '{ r=$1*$2; printf "%5i", r}' `
			_nIons=` echo "$_molWater 0.0027 $_molCharge" | gawk '{ r=$1*$2+$3; printf "%5i", r}' `
		else
			_nIons=` echo "$_molWater 0.0027" | gawk '{ r=$1*$2; printf "%5i", r}' `
			_pIons=` echo "$_molWater 0.0027 $_molCharge" | gawk '{ r=$1*$2-$3; printf "%5i", r}' `
		fi
		sed -i -e "s/quit/ /g" tempFILES/tleap.temp
		echo -e >> tempFILES/tleap.temp "	
			\naddIons pdbFILE Cl- $_nIons K+ $_pIons
		"
	fi
		
	echo -e >> tempFILES/tleap.temp "	
		\nsaveAmberParm pdbFILE $_FileOUT.top $_FileOUT.crd\
		\nsavePdb pdbFILE $_FileOUT.pdb\
		\nquit
	"
	
	#RUN tLeap
	#rm tleap.out 2> /dev/null
	echo -e >> tleap.out "\n ** _FilePDB -> $_FilePDB \t\t _FileOUT -> $_FileOUT ** \n"	
	tleap -f tempFILES/tleap.temp &>> tleap.out
	
	[ "`grep "Exiting LEaP: Errors = 0;" tleap.out`" ] || fatal 9 "MakeAmberTOP() ERROR: There are errors on tleap!! Check it out!"

	
	
}

FixPDB_adHOC () {
	local _FilePDB=$1
	local _FileOUT=$1

	echo -e >> tempFILES/VMDtleap.temp "
	mol new $_FilePDB.pdb waitfor all
	set Sel [atomselect top \"fragment 0\"]
	\$Sel set chain A
	\$Sel set segname AP1
	\$Sel delete
	set Sel [atomselect top \"fragment 1\"]
	\$Sel set chain B
	\$Sel set segname BP1
	\$Sel delete
	set Sel [atomselect top \"fragment 2\"]
	\$Sel set chain C
	\$Sel set segname CP1
	\$Sel delete
	set Sel [atomselect top \"all\"]
	\$Sel writepdb $_FileOUT.pdb
	\$Sel delete
	exit"
		$VMD -dispdev none -e tempFILES/VMDtleap.temp &> VMDtleap.out


}



MakeFiles_GMXPBSA () {
# usage: MakeFiles_GMXPBSA 

	#Other functions/programs:
	#gromacs
		
	#GLOBAL VARIABLE USED:
	#GROMPP
	#TRJCONV
	#MAKE_NDX
	#LOGFILENAME
	
	#LOCAL VARIABLES:
	local _groMDslow_NAME=
	local _trjNAME=
	local _tprFILE=
	local _topName=
	local _confNAME=
	local _rootName=
	local _runNumber=
	local _mdp_NAME="$SETUP_PROGRAM_FOLDER/EngComp_ff14*custom*.mdp"
	local _NUMframe="all"
	local _ForceFieldNUM="1"
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
	local _minimization="n"
	local _NO_topol_ff="n"
	local _use_tpbcon="n"
	local _gmx=${GROMPP%grompp}

	while [ $# -gt 0 ]
	do
	    case "$1" in
		-gro)		shift; _groMDslow_NAME=$1;;			# starting frame of the long simulation
		-xtc)		shift; _trjNAME=$1;;			 	# MD simulation trajectory
		-tpr)		shift; _tprFILE=$1;;				# MD simulation tpr file
		-top)		shift; _topName=$1;;				# topology used for the long simulation
		-s)    		 shift; _startingFrame=$1;;                      # starting frame [ps] for the Energy computation (Deafault=0 -> all the trajectory)
		-r)		shift; _runNumber=$1;;
		-cn)		shift; _confNAME=$1;;
		-rn)		shift; _rootName=$1;;
		-m)		shift; _mdp_NAME=$1;;
		-n)		shift; _NUMframe=$1;;
		-ff)		shift; _ForceFieldNUM=$1;;
		-mnp)		shift; _mnp=$1;;
		-pF)		shift; _precF=$1;;
		-pd)		shift; _pdie=$1;;
		-ac)		shift; _ABchains=$1;;
		-rf)		shift; _receptorFRAG=$1;;
		-mergeC)	shift; _mergeC=$1;;
		-mergeR)	shift; _mergeR=$1;;
		-mergeL)	shift; _mergeL=$1;;
		-min)		shift; _minimization=$1;;
		-noTF)		_NO_topol_ff="y";;
		-utc)		_use_tpbcon="y";;
		-l)		_linearized="y";;
		*)		fatal 1 "MakeFiles_GMXPBSA ERROR: $1 is not a valid OPTION!\n MakeFiles_GMXPBSA $@\n";;			
	    esac
	    shift
	done
	if [ "$_confNAME" == "" ] || [ "$_rootName" == "" ]; then
		[ $_runNumber == "" ] && _rootName="1"
		_confNAME="conf${_runNumber}"
		_rootName="config${_runNumber}_prot"
	elif ! [ "$_runNumber" == "" ]; then
		_confNAME="conf${_runNumber}"
		_rootName="config${_runNumber}_prot"
	fi
	
	if ! [ -r ${_groMDslow_NAME}.gro ] || ! [ -r ${_trjNAME}.xtc ] || ! [ -r ${_tprFILE}.tpr ] || ! [ -r ${_topName}.top ]; then
		fatal 2 "MakeFiles_GMXPBSA ERROR: one of the input file is missing! \nGROfile:${_groMDslow_NAME}.gro TRJfile:${_trjNAME}.xtc TPRfile:${_tprFILE}.tpr TOPfile:${_topName}.top" 
	fi
	
	if [ ${_receptorFRAG} -gt 1 ]; then
	# This is needed to chenge the pdb file and add TER at the end of every fragment. Not necessary if the fragment change with the chain.
		_multichain="y"
	fi

	#====================================================================================================================================================
	#msg "                            --MAKE THE FILES-- 			"
	#====================================================================================================================================================

	mkdir -p ${_rootName}
	rm ${_rootName}/* 2> /dev/null
	#rm *out 2> /dev/null

	#make index adhoc									ONLY 1 PROTEIN AND 1 MOLECULE ALLOWED FOR NOW
	Run_GMXtools "keep 1\n\nq\n" "$MAKE_NDX" "-f ${_groMDslow_NAME}.gro -o index.ndx" -o "make_ndx.temp"

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
	Run_GMXtools "0\n" "$TRJCONV" "-n index.ndx -f ${_trjNAME}.xtc -o ${_confNAME}_starting.pdb -s ${_tprFILE}.tpr -sep -e 0" -o "trjconv.temp"
	mv ${_confNAME}_starting0.pdb ${_confNAME}_starting_protein.pdb
	echo "DONE"; [ "$debug" == "true" ] && read GoAhead
	# TRJCONV to remove the pbc from the trajectory 
	msg -n "\t\t --running TRJCONV to remove the pbc from the trajectory.. "
	Run_GMXtools "0\n" "$TRJCONV" "-n index.ndx -f ${_trjNAME}.xtc -o ./nptMD_nojump.xtc -s ${_tprFILE}.tpr -pbc nojump -b ${_startingFrame}" -o "trjconv.temp"
	Run_GMXtools "1\n0" "$TRJCONV" "-n index.ndx -f ./nptMD_nojump.xtc -o ./${_rootName}/${_confNAME}_noPBC.xtc -s ${_tprFILE}.tpr -pbc mol -center" -o "trjconv.temp"
	echo "DONE"; [ "$debug" == "true" ] && read GoAhead
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
		for i in `seq 2 $_receptorFRAG`; do
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
		for i in `seq 2 $_ABchains`; do
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
	Run_GMXtools "${_makeNDX_string}" "$MAKE_NDX" "-f ${_confNAME}_starting_protein.pdb -o ${_rootName}/index.ndx" -o "make_ndx.temp"
	
	#if [ "$_ABchains" == "2" ]; then
	#	echo -e "keep 1\nsplitch 0\ndel 0\n0|1\ndel 0\ndel 0\n0|1\nname 0 receptor\nname 1 ligand\nname 2 complex\n\nq\n" | make_ndx -f ${_confNAME}_starting_protein.pdb -o ${_rootName}/index.ndx &> make_ndx.temp || { echo " something wrong on MAKE_NDX!! exiting..."; exit; }
	#elif [ "$_ABchains" == "1" ]; then
	#	echo -e "keep 1\nsplitch 0\ndel 0\n0|1\n\nname 0 receptor\nname 1 ligand\nname 2 complex\n\nq\n" | make_ndx -f ${_confNAME}_starting_protein.pdb -o ${_rootName}/index.ndx &> make_ndx.temp || { echo " something wrong on MAKE_NDX!! exiting..."; exit; }
	#else
	#	fatal 2 "MakeFiles_GMXPBSA ERROR: Something wrong with _ABchains ($_ABchains)!!"
	#fi
	
	echo "DONE"; [ "$debug" == "true" ] && read GoAhead
	# HEAD to make a temporary new only-protein top
	msg -n "\t\t --using HEAD to make a only-protein top.. "
	head -n -3 ${_topName}.top > ${_topName}_protein.top
	echo "DONE"; [ "$debug" == "true" ] && read GoAhead
	# GROMPP to make a protein tpr 
	msg -n "\t\t --GROMPP to make a protein tpr.. "
	$GROMPP -v -f ${_mdp_NAME} -c ${confNAME}_starting_protein.pdb -p ${_topName}_protein.top -o ${_rootName}/${_confNAME}.tpr -maxwarn "1"					&>> grompp_OP.temp || { echo " something wrong on GROMPP!! exiting..."; exit; }
	echo "DONE"; [ "$debug" == "true" ] && read GoAhead

	_his_string=""
	_num_his=$(egrep -c "(HIS     CA)|(HID     CA)|(HIE     CA)|(HIP     CA)|(HSD     CA)|(HSE     CA)|(HSP     CA)|(CA  HIS)|(CA  HID)|(CA  HIE)|(CA  HIP)|(CA  HSD)|(CA  HSE)|(CA  HSP)" ${confNAME}_starting_protein.pdb)
	for i in `seq 1 $_num_his`; do
		_his_string="${_his_string}1\n"
	done
	rm *# *~ &> /dev/null

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
Gpath			$GPATH

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
ffield			${_ForceFieldNUM}
use_nonstd_ff           n                               #options: y,n

#GROMACS VARIABLE
complex	                complex
receptor                receptor
ligand                  ligand

skip                    1                               #options: integer
double_p                n                               #options: y,n
read_vdw_radii		n                               #options: y,n
coulomb			${_gmx}              	        #options: coul,gmx

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


run_minim () {
# usage run_minim -mdp minim_NAME -gro gro_NAME -top top_NAME -out output_NAME -n "3" (outpus is ${_output_NAME}_minim.gro )

	#Other functions/programs:
	#gromacs
		
	#GLOBAL VARIABLE USED:
	#GROMPP
	#MDRUN
	#LOGFILENAME
	
	#LOCAL VARIABLES:
	local _minim_NAME=
	local _gro_NAME=
	local _top_NAME=
	local _output_NAME=
	local _numberOfRun=1
	local _start=
	local _maxWarn=
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-mdp)	shift; _minim_NAME=$1;;			
		-gro)	shift; _gro_NAME=$1;;			
		-top)	shift; _top_NAME=$1;;			
		-out)	shift; _output_NAME=$1;;		
		-n)	shift; _numberOfRun=$1;;
		-mw)	shift; _maxWarn="-maxwarn $1";;
		*)	fatal 1 "run_minim ERROR: $1 is not a valid OPTION!\n";;			
	    esac
	    shift
	done
	_minim_NAME="${_minim_NAME%.mdp}"
	_gro_NAME="${_gro_NAME%.gro}"
	_top_NAME="${_top_NAME%.top}"
	_output_NAME="${_output_NAME%.*}"
	[ ${_numberOfRun} -lt 1 ] && { _numberOfRun=1;}
	
	$GROMPP -f ${_minim_NAME} -c ${_gro_NAME}.gro -p ${_top_NAME}.top -o ${_gro_NAME}_EM1.tpr ${_maxWarn}					&> grompp.out || { echo " something wrong on 1st GROMPP!! exiting..."; exit; }
	$MDRUN -s ${_gro_NAME}_EM1.tpr -c ${_gro_NAME}_EM1.gro -v										&> output.temp || { echo " something wrong on 1st MDRUN!! exiting..."; exit; }
			
	if [ ${_numberOfRun} -gt 1 ]; then
		_start=1
		for run in `seq 2 ${_numberOfRun}`; do
			$GROMPP -f ${_minim_NAME} -c ${_gro_NAME}_EM${_start}.gro -p ${_top_NAME}.top -o ${_gro_NAME}_EM${run}.tpr ${_maxWarn} 	&> output.temp || { echo " something wrong on ${run}st GROMPP!! exiting..."; exit; }
			$MDRUN -s ${_gro_NAME}_EM${run}.tpr -c ${_gro_NAME}_EM${run}.gro -v							&> output.temp || { echo " something wrong on ${run}st MDRUN!! exiting..."; exit; }
			let _start=$_start+1
		done
	fi
	mv ${_gro_NAME}_EM${_numberOfRun}.gro ${_output_NAME}_minim.gro
	# Check if the minimization goes well
	minim_test=$( echo `grep "Norm of force" output.temp | cut -d= -f2` )
	if [ "$minim_test" == "inf" ]; then
		msg -t -n "\t something wrong with the energy minimization. We need your help.."
		exit
	fi
}

MakeNewMinimConfig () {
#
# e.g. MakeNewMinimConfig -gro starting_file.ext -SA SAMD.mdp -NVT NVT.mdp -NPT NPT.mdp -top topol.top -out outputNAME

	#Other functions/programs:
	#gromacs
	
	#GLOBAL VARIABLE USED:
	#GROMPP
	#MDRUN
	#LOGFILENAME
	
	#LOCAL VARIABLES:
	local _INPUT_structure_fileNAME=
	local _SAMDmdp_NAME=
	local _NVTmdp_NAME=
	local _NPTmdp_NAME=
	local _top_NAME="topol.top"
	local _OUTPUTgro=

	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-gro)	shift; _INPUT_structure_fileNAME=$1;;
		-SA)	shift; _SAMDmdp_NAME=$1;;
		-NVT)	shift; _NVTmdp_NAME=$1;;
		-NPT)	shift; _NPTmdp_NAME=$1;;
		-top)	shift; _top_NAME=$1;;
		-out)	shift; _OUTPUTgro=$1;;
		*)	fatal 1 "MutantRearangement() ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done	
	_top_NAME="${_top_NAME%.top}"
	_OUTPUTgro="${_OUTPUTgro%.*}"
	
	# Simulated Annealing-MD to find a energy minimum from which start (every run will start at a different minima)
	msg -n "$(date +%H:%M:%S) --running Simulated Annealing MD (SA-MD) to find a new minima.. " | tee -a $LOGFILENAME
	$GROMPP -f ${_SAMDmdp_NAME} -c ${_INPUT_structure_fileNAME} -r ${_INPUT_structure_fileNAME} -p ${_top_NAME}.top -o system_SAMD.tpr 		&> output.temp || { echo " something wrong on SA-MD GROMPP!! exiting..."; exit; }
	$MDRUN -s system_SAMD.tpr -c system_SAMD.gro -cpo state_SAMD.cpt -x traj_SAMD.xtc 								&> output_SAMD.temp || { echo " something wrong on SA-MD RUN!! exiting..."; exit; }
	echo "DONE" | tee -a $LOGFILENAME; [ $DEBUG == "true" ] && read GoAhead
	
	# NVT ensemble ("isothermal-isochoric" or "canonical")
	msg -n "$(date +%H:%M:%S) --running NVT MD for for Temperature equilibration.. " | tee -a $LOGFILENAME
	$GROMPP -f ${_NVTmdp_NAME} -c system_SAMD.gro -r system_SAMD.gro -p ${_top_NAME}.top -o system_NVT_MD.tpr -t state_SAMD.cpt		 	&> output.temp || { echo " something wrong on NVT GROMPP!! exiting..."; exit; }
	$MDRUN -s system_NVT_MD.tpr -c system_NVT_MD.gro -cpo state_NVT_MD.cpt  									&> mdrun_NVT_MD.out || { echo " something wrong on NVT MD RUN!! exiting..."; exit; }
	echo "DONE" | tee -a $LOGFILENAME; [ $DEBUG == "true" ] && read GoAhead
	
	# NPT ensemble ("isothermal-isobaric")
	msg -n "$(date +%H:%M:%S) --running NPT MD for Pressure equilibration.. " | tee -a $LOGFILENAME
	$GROMPP -f ${_NPTmdp_NAME} -c system_NVT_MD.gro -r system_NVT_MD.gro -p ${_top_NAME}.top -o system_NPT_MD.tpr -t state_NVT_MD.cpt	 	&> output.temp || { echo " something wrong on NPT GROMPP!! exiting..."; exit; }
	$MDRUN -s system_NPT_MD.tpr -c ${_OUTPUTgro}.gro -x traj_NPT_MD.xtc 										&> mdrun_NPT_MD.out || { echo " something wrong on NPT MD RUN!! exiting..."; exit; }
	echo "DONE" | tee -a $LOGFILENAME; [ $DEBUG == "true" ] && read GoAhead
	
}



function addTERpdb {
	
	local _pdbFileName=$1
	local _flag=0
	local _increment=0
	
	_pdbFileName=${_pdbFileName%.pdb}
	for lineOC2 in `sed -n '/OC2/=' ${_pdbFileName}.pdb`; do
		let lineOC2=$lineOC2+$_increment
		let lineTER=$lineOC2+$_increment+1
		_flag=$(head -n $lineTER ${_pdbFileName}.pdb | tail -n 1 | cut -b 1-3)
		cp ${_pdbFileName}.pdb a${_pdbFileName}.pdb
		if [ "$_flag" != "TER" ]; then
			let _increment=$_increment+1
			sed -i $lineOC2'a\TER' a${_pdbFileName}.pdb
		fi
		#sed -i_temp '/OC2/a\TER' Mutant${SEQUENCE}.pdb
		mv a${_pdbFileName}.pdb ${_pdbFileName}.pdb
	done
	
}

function buildBoxWaterIons {
# buildBoxWaterIons _startingSystem _topology (output: system_ions.gro)
	
	#Other functions/programs:
	#gromacs
	
	#GLOBAL VARIABLE USED:
	#GENBOX
	#GROMPP
	#GENION
	#MAKE_NDX
	#minim_NAME
	
	#LOCAL VARIABLES:
	local _startingSystem=$1
	local _topology=$2
	local ChargeValue=
	local WaterMolecules=
	local KNumber=; local ClNumber=
	local NEWnetCHARGE=
	
	_topology=${_topology%.top}
	$GENBOX -cp ${_startingSystem} -cs spc216.gro -o system_water.gro -p ${_topology}.top				&> genbox.out || { echo " something wrong on GENBOX!! exiting..."; exit; }

	# COMPUTE THE NUMBER OF IONS NEEDED IN THE BOX AND ADD THEM TO THE SYSTEM
	$GROMPP -f ${minim_NAME} -c system_water.gro -p ${_topology}.top -o system_ions.tpr -maxwarn 1			&> grompp.out || { echo " something wrong on GROMPP!! exiting..."; exit; }
	ChargeValue=$( gawk '/System has non-zero total charge/ {  x=$NF; if(x>0){x=x+0.5}else{x=x-0.5}; printf "%2i", x  }' grompp.out )
	[ "$ChargeValue" == "" ] && fatal 99 "ChargeValue=\"$ChargeValue\"!!!!"
	WaterMolecules=$( gawk '$1 ~ /SOL/ { print $NF }' ${_topology}.top )
	[ "$WaterMolecules" == "" ] && fatal 99 "WaterMolecules=\"$WaterMolecules\"!!!!"
	IonsNumber=$( echo "scale=0; x=(0.599+$WaterMolecules*0.00271)/1; print x;" | bc -l );		# 150nM of solt
	KNumber=$( echo "scale=0; x=($IonsNumber-1*$ChargeValue/2)/1; print x;" | bc -l );
	ClNumber=$( echo "scale=0; x=($IonsNumber+1*$ChargeValue/2)/1; print x;" | bc -l );
	netCHARGE=$( echo "scale=0; x=($KNumber-$ClNumber+1*$ChargeValue); print x;" | bc -l );
	NEWnetCHARGE="not computed"
	#echo -e "ChargeValue=$ChargeValue WaterMolecules=$WaterMolecules IonsNumber=$IonsNumber \nnetCHARGE=$netCHARGE KNumber=$KNumber ClNumber=$ClNumber NEWnetCHARGE=$NEWnetCHARGE"
	if [ "$netCHARGE" -ne "0" ]; then 
		msg -s -n -t "   >>> WORNING!! check the charge of the system!! (SystemCharge.out) <<<   "
		ClNumber=$( echo "scale=0; x=($ClNumber+1*$netCHARGE)/1; print x;" | bc -l )
		NEWnetCHARGE=$( echo "scale=0; x=($KNumber-$ClNumber+1*$ChargeValue)/1; print x;" | bc -l )
	fi
	echo -e "ChargeValue=$ChargeValue WaterMolecules=$WaterMolecules IonsNumber=$IonsNumber \
		\nnetCHARGE=$netCHARGE KNumber=$KNumber ClNumber=$ClNumber NEWnetCHARGE=$NEWnetCHARGE" &> SystemCharge.out
	
	#echo "ChargeValue->$ChargeValue   WaterMolecules->$WaterMolecules   IonsNumber->$IonsNumber   KNumber->$KNumber   ClNumber->$ClNumber"
	Run_GMXtools "keep 0\nr SOL\nkeep 1\n\nq\n" "$MAKE_NDX" "-f system_water.gro -o index_SOL.ndx" -o "make_ndx.out"
	Run_GMXtools "0\n" "$GENION" "-s system_ions.tpr -n index_SOL.ndx -o system_ions.gro -p ${_topology}.top -nn ${ClNumber} -nname CL -np ${KNumber} -pname K" -o "genion.temp"
	rm index_SOL.ndx
	
}

function BuildFoldersAndPrintHeadingFiles {
# BuildFoldersAndPrintHeadingFiles _currentPath
	local _currentPath=$1
	
	mkdir -p REPOSITORY RESULTS tempFILES REMOVED_FILES
	printf "%-10s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \n" "#RUNnumber" "DeltaG(kJ/mol)" "Coul(kJ/mol)" "vdW(kJ/mol)" \
		"PolSol(kJ/mol)" "NpoSol(kJ/mol)" "ScoreFunct" "ScoreFunct2" "Canonica_AVG" "MedianDG" "DeltaG_2s" "dG_PotEn" > ${_currentPath}/RESULTS/MoleculesResults.dat
	
	
	
}

function PosResSelection {
# PosResSelection SistemName(Cx, CXCR2, Covid)
	
	case "$1" in
	
		Cx)
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chA" -tf "topol_Protein_chain_A" -fn  "0 1"  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chB" -tf "topol_Protein_chain_B" -fn  "2 3"  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chC" -tf "topol_Protein_chain_C" -fn  "4 5"  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chD" -tf "topol_Protein_chain_D" -fn  "6 7"  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chE" -tf "topol_Protein_chain_E" -fn  "8 9"  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chF" -tf "topol_Protein_chain_F" -fn "10 11" -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chH" -tf "topol_Protein_chain_H" -fn   "12"  -pr "Backbone" -fc "800 800 800"
			if [ "${POSRES}" != "" ]; then
				msg -n "$(date +%H:%M:%S) --building adhoc POSITION RESTRAINT.. " | tee -a $LOGFILENAME
				MakePOSRES_protein -pf "system.gro" -of "posres_abiss_A" -tf "topol_Protein_chain_A" -fn  "0 1"  -pr "${posresRESIDUES}" -fc "300 300 400"
				MakePOSRES_protein -pf "system.gro" -of "posres_abiss_B" -tf "topol_Protein_chain_B" -fn  "2 3"  -pr "${posresRESIDUES}" -fc "300 300 400"
				MakePOSRES_protein -pf "system.gro" -of "posres_abiss_C" -tf "topol_Protein_chain_C" -fn  "4 5"  -pr "${posresRESIDUES}" -fc "300 300 400"
				MakePOSRES_protein -pf "system.gro" -of "posres_abiss_D" -tf "topol_Protein_chain_D" -fn  "6 7"  -pr "${posresRESIDUES}" -fc "300 300 400"
				MakePOSRES_protein -pf "system.gro" -of "posres_abiss_E" -tf "topol_Protein_chain_E" -fn  "8 9"  -pr "${posresRESIDUES}" -fc "300 300 400"
				MakePOSRES_protein -pf "system.gro" -of "posres_abiss_F" -tf "topol_Protein_chain_F" -fn "10 11" -pr "${posresRESIDUES}" -fc "300 300 400"
				echo "DONE" | tee -a $LOGFILENAME; [ $DEBUG == "true" ] && read GoAhead
			fi
			;;
		CXCR2)
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chH" -tf "topol_Protein_chain_H" -fn  "0"  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chL" -tf "topol_Protein_chain_L" -fn  "1"  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chB" -tf "topol_Protein_chain_B" -fn  "2"  -pr "Backbone" -fc "800 800 800"
			if [ "${POSRES}" != "" ]; then
				msg -n "$(date +%H:%M:%S) --building adhoc POSITION RESTRAINT.. " | tee -a $LOGFILENAME
				# NOT USED WITH CXCR2
				echo "DONE" | tee -a $LOGFILENAME; [ $DEBUG == "true" ] && read GoAhead
			fi
			;;
		Covid-A)
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chS" -tf "topol_Protein_chain_S" -fn  "0"  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chA" -tf "topol_Protein_chain_A" -fn  "1"  -pr "Backbone" -fc "800 800 800"
			if [ "${POSRES}" != "" ]; then
				msg -n "$(date +%H:%M:%S) --building adhoc POSITION RESTRAINT.. " | tee -a $LOGFILENAME
				# NOT USED 
				echo "DONE" | tee -a $LOGFILENAME; [ $DEBUG == "true" ] && read GoAhead
			fi
			;;
		Covid-H)
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chS" -tf "topol_Protein_chain_S" -fn  "0"  -pr "Backbone" -fc "800 800 800"
			MakePOSRES_protein -pf "system.gro" -of "posres_BB_chH" -tf "topol_Protein_chain_H" -fn  "1"  -pr "Backbone" -fc "800 800 800"
			if [ "${POSRES}" != "" ]; then
				msg -n "$(date +%H:%M:%S) --building adhoc POSITION RESTRAINT.. " | tee -a $LOGFILENAME
				# NOT USED 
				echo "DONE" | tee -a $LOGFILENAME; [ $DEBUG == "true" ] && read GoAhead
			fi
			;;
		*)	fatal 1 "PosResSelection ERROR: $1 is not a valid OPTION!\n";;
	esac


}


























