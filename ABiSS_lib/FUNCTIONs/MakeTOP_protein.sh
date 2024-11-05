#!/bin/bash

echo -e "\t > MakeTOP_protein.sh"


MakeTOP_protein () {
# THIS FUNCTION MAKES THE TOPOLOGY FILES ( .top .itp ) FROM THE INPUT FILE
# TODO change the adhoc option on the -merge
#	local _protein_InfileNAME=
	local _protein_OutFileNAME="proteinFile_pdb2gmx"
	local _ForceField=
	local _num_his=
	local _pdb2gmx_string=
#	local _lineDummy=
	local _topFileNAME="topol"
#	local _ABchains="2"
#	local _receptorFRAG="1"
	local _merge=""
	local _mergeSTRING="y\nn\n"
  local _out_file="MakeTOP_protein.out"
	echo "############################ MakeTOP_protein () ###############################" &>> ${_out_file}

	while [ $# -gt 0 ]
	do
	    case "$1" in
      -of)	shift; _protein_OutFileNAME=$1;;
      -ff)	shift; _ForceField=$1;;
      -pf)	shift; _protein_InFileNAME=$1;;
      -tf)	shift; _topFileNAME=$1;;
  #		-ac)	shift; _ABchains=$1;;			# NOT USED
  #		-rf)	shift; _receptorFRAG=$1;;		# NOT USED
      -merge)	shift; _merge="-merge interactive"; _mergeSTRING=$1;;
      *)    if [ "$1" == "" ]; then
              # echo "\$1=$1";
              # I need the shift because with continue it will restart immediately without the shift at the end of the while
              shift; continue
            fi
            fatal 1 "MakeTOP_protein () ERROR: '$1' is not a valid OPTION!\n";;
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

	cat ./"${_protein_InFileNAME}".pdb > mutant_out.temp
	_num_his=$(grep -E -c "(HIS     CA)|(HID     CA)|(HIE     CA)|(HIP     CA)|(HSD     CA)|(HSE     CA)|(HSP     CA)|(CA  HIS)|(CA  HID)|(CA  HIE)|(CA  HIP)|(CA  HSD)|(CA  HSE)|(CA  HSP)" ./"${_protein_InFileNAME}.pdb")
	echo -e "(egrep \"(HIS     CA)|(HID     CA)|(HIE     CA)|(HIP     CA)|(HSD     CA)|(HSE     CA)|(HSP     CA)|(CA  HIS)|(CA  HID)|(CA  HIE)|(CA  HIP)|(CA  HSD)|(CA  HSE)|(CA  HSP)\" ${_protein_InFileNAME}.pdb )" &>> ${_out_file}
	_pdb2gmx_string="\n1\n"
	if [ "${_merge}" == "-merge interactive" ]; then
		_pdb2gmx_string="${_pdb2gmx_string}${_mergeSTRING}"
		# y\nn\ny\nn\ny\nn\ny\nn\ny\nn\ny\nn\n
	fi
	for i in $(seq 1 "$_num_his"); do
		_pdb2gmx_string="${_pdb2gmx_string}1\n"
	done
  { echo -e "_protein_OutFileNAME: ${_protein_OutFileNAME} \n_ForceField: ${_ForceField} \
  \n_protein_InFileNAME: ${_protein_InFileNAME} \n_topFileNAME : ${_topFileNAME} \n_merge: ${_merge} \n_mergeSTRING: ";
  echo "${_mergeSTRING}";
	echo -e "num hist: ${_num_his} \npdb2gmx_string:"; echo "${_pdb2gmx_string}"; echo -e "\n\n"; } &>> ${_out_file}
	#sed -i_OLD '/OC2/a\TER' ${_protein_InFileNAME}.pdb
	echo -e "${_pdb2gmx_string}" | $PDB2GMX -f "${_protein_InFileNAME}.pdb" -o system.pdb -p "$_topFileNAME.top" \
    -ignh -ff "${_ForceField}" -his ${_merge} &>> ${_out_file} || { echo "something wrong with pdb2gmx!!"; exit; }

	#_lineDummy=$( echo "x=`sed -n '/N    GLY Z   1      53.800/=' ${_protein_InFileNAME}_temp.pdb`-1; print x;" | bc -l )
	#head -n ${_lineDummy} ${_protein_InFileNAME}_temp.pdb > ${_protein_OutFileNAME}.pdb
  _input_file="system.pdb"
  _output_file="${_protein_OutFileNAME}.gro"
  for option in "${editconf_opt}" "${editconf_opt2}" "${editconf_opt3}"; do
    [[ "${option}" == "" ]] && continue;
    if [[ $VERBOSE == True ]]; then
      msg "running editconf vith option: $option"
    fi
    # CREATE THE BOX ( deafult -> -bt triclinic -d 1.5 )
    echo -e "1\n" | $EDITCONF -f "${_input_file}" $option -o "temp${_output_file}" 	&>> "${_out_file}" \
      || { echo " something wrong on EDITCONF!! exiting..."; exit; }

    _input_file="${_protein_OutFileNAME}.gro"
    cp "temp${_output_file}" "${_output_file}"
  done

	mv ./*_temp.pdb ./*_Z.itp "${removed_files_FOLDER}" &> /dev/null

}

