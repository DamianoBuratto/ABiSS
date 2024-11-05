#!/bin/bash

echo -e "\t > GRO_to_PDB.sh"


function GRO_to_PDB {
# GLOBAL VARIABLES NEEDED:
  # ABiSS_LIB
  # VMD
  # fatal

# LOCAL VARIABLES:
	local _pathGRO="."
	local _FileNameGRO=""         # NO EXTENSION
	local _pathPDB="."
	local _FileNamePDB=""         # NO EXTENSION
	local _FileNamePDB_OUT=""     # NO EXTENSION

	while [ $# -gt 0 ]
	do
		case "$1" in
			-gp)	shift; _pathGRO=$1;;
			-gn)	shift; _FileNameGRO=$1;;
			-pp)	shift; _pathPDB=$1;;
			-pn)	shift; _FileNamePDB=$1;;
			-o)	  shift; _FileNamePDB_OUT=$1;;
			*)	  break;;
		esac
		shift
	done
  if [[ $_FileNamePDB_OUT == "" ]]; then
    _FileNamePDB_OUT=$_FileNameGRO
  fi

  echo -e "
  \nvariable _pathGRO \"$_pathGRO\" \
  \nvariable _FileNameGRO \"$_FileNameGRO\" \
  \nvariable _pathPDB \"$_pathPDB\" \
  \nvariable _FileNamePDB \"$_FileNamePDB\" \
  \nvariable _FileNamePDB_OUT \"$_FileNamePDB_OUT\"" > ${TEMP_FILES_FOLDER}/vmd_GRO_to_PDB.tcl

  cat "${ABiSS_LIB}/VMD_function_GRO_to_PDB.tcl" >> ${TEMP_FILES_FOLDER}/vmd_GRO_to_PDB.tcl
  $VMD -dispdev none -e ${TEMP_FILES_FOLDER}/vmd_GRO_to_PDB.tcl &> ${TEMP_FILES_FOLDER}/vmd_GRO_to_PDB.out \
      || fatal 33 "GRO_to_PDB -> $VMD failed.. check ${TEMP_FILES_FOLDER}/vmd_GRO_to_PDB.out"


}


