#!/bin/bash

echo -e "\t > addTERpdb.sh"

# e.g. -> addTERpdb namefile.pdb
# The function will add a TER at the end of each molecule where there is a OC2 group.
# If there is already a TER, it will skip
function addTERpdb {

	local _pdbFileName=$1
	local _flag=0
	local _increment=0
  local _OC2_lines=
  local _temp_file_name="addTERpdb_temp"

#	_pdbFileName=${_pdbFileName%.pdb}

	cp "${_pdbFileName}" ./${_temp_file_name}.pdb
	_OC2_lines="$(sed -n '/OC2/=' "${_temp_file_name}".pdb)"
	for lineOC2 in $_OC2_lines; do
		((lineOC2=lineOC2+_increment))
		((lineTER=lineOC2+_increment+1))
		_flag=$(head -n "$lineTER" "${_temp_file_name}.pdb" | tail -n 1 | cut -b 1-3)
		cp "${_temp_file_name}.pdb" "a${_temp_file_name}.pdb"
#		cp "${_temp_file_name}.pdb" "temp_${_temp_file_name}_before_TER.pdb"
		if [ "$_flag" != "TER" ]; then
			((_increment=_increment+1))
			sed "$lineOC2"'a\TER' a"${_temp_file_name}".pdb > "${_temp_file_name}.pdb"
		fi
		#sed -i_temp '/OC2/a\TER' Mutant${SEQUENCE}.pdb
#		mv "a${_temp_file_name}.pdb" "${_temp_file_name}.pdb"
	done
	mv ${_temp_file_name}.pdb "${_pdbFileName}"
  # rm ./*temp*.pdb

}