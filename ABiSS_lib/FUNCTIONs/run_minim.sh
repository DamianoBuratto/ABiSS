#!/bin/bash

echo -e "\t > run_minim.sh"



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
	local _maxWarn=0
	while [ $# -gt 0 ]
	do
	    case "$1" in
		-mdp)	shift; _minim_NAME=$1;;
		-gro)	shift; _gro_NAME=$1;;
		-top)	shift; _top_NAME=$1;;
		-out)	shift; _output_NAME=$1;;
		-n)	shift; _numberOfRun=$1;;
		-mw)	shift; _maxWarn="$1";;
		*)	fatal 1 "run_minim ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	_minim_NAME="${_minim_NAME%.mdp}"
	_gro_NAME="${_gro_NAME%.gro}"
	_top_NAME="${_top_NAME%.top}"
	_output_NAME="${_output_NAME%.*}"
	[ "${_numberOfRun}" -lt 1 ] && { _numberOfRun=1;}

	$GROMPP -f "${_minim_NAME}" -c "${_gro_NAME}.gro" -p "${_top_NAME}.top" -o "${_gro_NAME}_EM1.tpr" -maxwarn "${_maxWarn}"	\
    &> grompp.out || { echo " something wrong on 1st GROMPP!! exiting..."; exit; }
	$MDRUN -s "${_gro_NAME}_EM1.tpr" -c "${_gro_NAME}_EM1.gro" -v	\
    &> output.temp || { echo " something wrong on 1st MDRUN!! exiting..."; exit; }

	if [ ${_numberOfRun} -gt 1 ]; then
		_start=1
		for run in $(seq 2 ${_numberOfRun}); do
			$GROMPP -f "${_minim_NAME}" -c "${_gro_NAME}_EM${_start}.gro" -p "${_top_NAME}.top" -o "${_gro_NAME}_EM${run}.tpr" \
			-maxwarn "${_maxWarn}" &> output.temp || { echo " something wrong on ${run}st GROMPP!! exiting..."; exit; }
			$MDRUN -s "${_gro_NAME}_EM${run}.tpr" -c "${_gro_NAME}_EM${run}.gro" -v		\
        &> output.temp || { echo " something wrong on ${run}st MDRUN!! exiting..."; exit; }
			((_start=_start+1))
		done
	fi
	mv "${_gro_NAME}_EM${_numberOfRun}.gro" "${_output_NAME}_minim.gro"
	# Check if the minimization goes well
	minim_test="$(grep "Norm of force" output.temp | cut -d= -f2)"
	if [ "$minim_test" == "inf" ]; then
		msg -t -n "\t something wrong with the energy minimization. We need your help.."
		exit
	fi
}

