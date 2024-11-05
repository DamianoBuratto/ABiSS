#!/bin/bash

echo -e "\t > findPATH.sh"

#e.g. -> findPATH "$CHIMERA" chimera CHIMERA
function findPATH {

# GLOBAL VARIABLES
# Is using msg_fatal.sh

# LOCAL VARIABLES
	local _programPATH=$1
	local _programNAME=$2
	local _resultVAR=$3
	
	if [ "$_programPATH" == "findPATH" ]; then
		_flag=$(command -v "${_programNAME}")
		_programPATH=${_flag%/*}
		if [ "$_programPATH" != "" ]; then
			msg "--${_programNAME}-- program found at -> $_programPATH"
		else
			fatal 11 "findPATH ERROR: Cannot find any ${_programNAME} program in the \$PATH!! Please install it or specify a custom path."
		fi
	else
	  if [ -x "${_programPATH}/${_programNAME}" ]; then
		  msg "--${_programNAME}-- program at -> ${_programPATH}"
		else
		  msg "WARNING!! Cannot find executable --${_programNAME}-- at ${_programPATH}!! Trying to search for it.."
		  _flag=$(command -v "${_programNAME}")
      _programPATH=${_flag%/*}
      if [ "$_programPATH" != "" ]; then
        msg "--$_programNAME-- program found at -> $_programPATH"
      else
        fatal 12 "findPATH ERROR: Cannot find any ${_programNAME} program in the \$PATH!! Please install it or specify a custom path."
      fi
		fi
	fi
	
	if [[ "$_resultVAR" ]]; then
		eval "$_resultVAR=$_programPATH"
	else
		echo "$_programPATH"
	fi
}
