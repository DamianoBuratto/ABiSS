#!/bin/bash

echo -e "\t > msg_fatal.sh"

msg () {
	local _StartingNewLine="0"
	local _StartingName="1"		#0=false
	local _NewLineEOF="1"
	local _verbose_mode="False"
	local _program_name=$PN
	while [ $# -gt 0 ]
	do
		case "$1" in
			-t)	_StartingNewLine="1";;		      # use this option to start with a newline
			-s)	_StartingName="0";;		          # use this option to NOT start the line with the header
			-n)	_NewLineEOF="0";;		            # use this option to NOT end the line with a newline
			-pn) shift; _program_name="$1";;   # use a custom program name (useful inside functions)
			-v) _verbose_mode="True";;
			*)	break;;
	  esac
	  shift
	done
	if [[ $_verbose_mode == "True" ]]; then
	  echo -e "VERBOSE:\t$*"
	  return 0
	fi
	[[ $_StartingNewLine == 1 ]] && echo -e -n "\n"
	[[ $_StartingName == 1 ]] && echo -e -n "$_program_name:\t\t"
	echo -e -n "$@";
	[[ $_NewLineEOF == 1 ]] && echo -e ""
}

fatal () { err=$1; shift; msg "\n($err) $* \n" >&2; exit "$err"; }

warning () { warning=$1; shift; msg "\n($warning) $* \n" >&2; }
