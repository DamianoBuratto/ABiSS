#!/bin/bash

echo -e "\t > all_to_HIS.sh"

function all_to_HIS {

	local _pdbFileName=
	local _output_pdbFile_name=
	local _ext="pdb"

	while [ $# -gt 0 ]
	do
	    case "$1" in
		-f)	shift; _pdbFileName=$1;;
		-o)	shift; _output_pdbFile_name=$1;;
		*)	fatal 1 "all_to_HIS() ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
  _ext="${_pdbFileName#*.}"
  [[ $_ext == "$_pdbFileName" ]] && _ext="pdb"
	_pdbFileName="${_pdbFileName%.*}"
	_output_pdbFile_name="${_output_pdbFile_name%.*}"

  [[ -r "${_pdbFileName}.${_ext}" ]] || return 1
  sed 's/HISD/HIS /g' "${_pdbFileName}.${_ext}" > "temp.${_ext}"
	sed 's/HISE/HIS /g' "temp.${_ext}" > "temp2.${_ext}"
	sed 's/HISP/HIS /g' "temp2.${_ext}" > "${_output_pdbFile_name}.${_ext}"


}