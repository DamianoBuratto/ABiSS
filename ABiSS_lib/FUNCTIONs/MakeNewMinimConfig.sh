#!/bin/bash

echo -e "\t > MakeNewMinimConfig.sh"



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
	local _mypipe=out.out

	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-gro)	shift; _INPUT_structure_fileNAME=$1;;
		-SA)	shift; _SAMDmdp_NAME=$1;;
		-NVT)	shift; _NVTmdp_NAME=$1;;
		-NPT)	shift; _NPTmdp_NAME=$1;;
		-top)	shift; _top_NAME=$1;;
		-out)	shift; _OUTPUTgro=$1;;
    -pipe)shift; _mypipe=$1;;
		*)	fatal 1 "MutantRearangement() ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	_top_NAME="${_top_NAME%.top}"
	_OUTPUTgro="${_OUTPUTgro%.*}"

	# Simulated Annealing-MD to find a energy minimum from which start (every run will start at a different minima)
	msg "$(date +%H:%M:%S) --running Simulated Annealing MD (SA-MD) to find a new minima.. " | tee -a "$LOGFILENAME"
	$GROMPP -f "${_SAMDmdp_NAME}" -c "${_INPUT_structure_fileNAME}" -r "${_INPUT_structure_fileNAME}" -p "${_top_NAME}.top" \
    -o system_SAMD.tpr -maxwarn 1 &> output.temp \
    || { echo " something wrong on SA-MD GROMPP!! exiting..."; echo "exit" > "${_mypipe}" ; exit; }
	$MDRUN_md -s system_SAMD.tpr -c system_SAMD.gro -cpo state_SAMD.cpt -x traj_SAMD.xtc \
    &> output_SAMD.temp \
    || { echo " something wrong on SA-MD RUN!! exiting..."; echo "exit" > "${_mypipe}"; exit; }

	# NVT ensemble ("isothermal-isochoric" or "canonical")
	msg "$(date +%H:%M:%S) --running NVT MD for for Temperature equilibration.. " | tee -a "$LOGFILENAME"
	$GROMPP -f "${_NVTmdp_NAME}" -c system_SAMD.gro -r system_SAMD.gro -p "${_top_NAME}.top" -o system_NVT_MD.tpr -t state_SAMD.cpt \
    &> output.temp \
    || { echo " something wrong on NVT GROMPP!! exiting..."; echo "exit" > "${_mypipe}"; exit; }
	$MDRUN_md -s system_NVT_MD.tpr -c system_NVT_MD.gro -cpo state_NVT_MD.cpt \
    &> mdrun_NVT_MD.out \
    || { echo " something wrong on NVT MD RUN!! exiting..."; echo "exit" > "${_mypipe}"; exit; }

	# NPT ensemble ("isothermal-isobaric")
	msg "$(date +%H:%M:%S) --running NPT MD for Pressure equilibration.. " | tee -a "$LOGFILENAME"
	$GROMPP -f "${_NPTmdp_NAME}" -c system_NVT_MD.gro -r system_NVT_MD.gro -p "${_top_NAME}.top" -o system_NPT_MD.tpr -t state_NVT_MD.cpt \
    &> output.temp \
    || { echo " something wrong on NPT GROMPP!! exiting..."; echo "exit" > "${_mypipe}"; exit; }
	$MDRUN_md -s system_NPT_MD.tpr -c "${_OUTPUTgro}.gro" -x traj_NPT_MD.xtc \
    &> mdrun_NPT_MD.out \
    || { echo " something wrong on NPT MD RUN!! exiting..."; echo "exit" > "${_mypipe}"; exit; }

}

MakeNewMinim_NVT_NPT () {
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
	local _mypipe=out.out

	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-gro)	shift; _INPUT_structure_fileNAME=$1;;
		-SA)	shift; _SAMDmdp_NAME=$1;;
		-NVT)	shift; _NVTmdp_NAME=$1;;
		-NPT)	shift; _NPTmdp_NAME=$1;;
		-top)	shift; _top_NAME=$1;;
		-out)	shift; _OUTPUTgro=$1;;
    -pipe)shift; _mypipe=$1;;
		*)	fatal 1 "MutantRearangement() ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	_top_NAME="${_top_NAME%.top}"
	_OUTPUTgro="${_OUTPUTgro%.*}"

	# Simulated Annealing-MD to find a energy minimum from which start (every run will start at a different minima)
	#msg "$(date +%H:%M:%S) --running Simulated Annealing MD (SA-MD) to find a new minima.. " | tee -a "$LOGFILENAME"
	#$GROMPP -f "${_SAMDmdp_NAME}" -c "${_INPUT_structure_fileNAME}" -r "${_INPUT_structure_fileNAME}" -p "${_top_NAME}.top" \
  #  -o system_SAMD.tpr -maxwarn 1 &> output.temp \
  #  || { echo " something wrong on SA-MD GROMPP!! exiting..."; echo "exit" > "${_mypipe}" ; exit; }
	#$MDRUN_md -s system_SAMD.tpr -c system_SAMD.gro -cpo state_SAMD.cpt -x traj_SAMD.xtc \
  #  &> output_SAMD.temp \
  #  || { echo " something wrong on SA-MD RUN!! exiting..."; echo "exit" > "${_mypipe}"; exit; }

	# NVT ensemble ("isothermal-isochoric" or "canonical")
	msg "$(date +%H:%M:%S) --running NVT MD for for Temperature equilibration.. " | tee -a "$LOGFILENAME"
	$GROMPP -f "${_NVTmdp_NAME}" -c "${_INPUT_structure_fileNAME}" -r "${_INPUT_structure_fileNAME}" \
	  -p "${_top_NAME}.top" -o system_NVT_MD.tpr &> gromppNVT_seq"${SEQUENCE}".out \
    || { echo " something wrong on NVT GROMPP!! exiting..."; echo "exit" > "${_mypipe}"; exit; }
	$MDRUN_md -s system_NVT_MD.tpr -c system_NVT_MD.gro -cpo state_NVT_MD.cpt -e NVT.edr -v \
    &> mdrun_NVT_MD.out \
    || { echo " something wrong on NVT MD RUN!! exiting..."; echo "exit" > "${_mypipe}"; exit; }
	cp ./mdout.mdp "${DOUBLE_CHECK_FOLDER}"/mdoutNVT_seq"${SEQUENCE}".mdp

	# NPT ensemble ("isothermal-isobaric")
	msg "$(date +%H:%M:%S) --running NPT MD for Pressure equilibration.. " | tee -a "$LOGFILENAME"
	$GROMPP -f "${_NPTmdp_NAME}" -c system_NVT_MD.gro -r system_NVT_MD.gro -p "${_top_NAME}.top" \
	  -o system_NPT_MD.tpr -t state_NVT_MD.cpt -maxwarn 1 &> gromppNPT_seq"${SEQUENCE}".out \
    || { echo " something wrong on NPT GROMPP!! exiting..."; echo "exit" > "${_mypipe}"; exit; }
	$MDRUN_md -s system_NPT_MD.tpr -c "${_OUTPUTgro}.gro" -cpo state_NPT_MD.cpt -x traj_NPT_MD.xtc -e NPT.edr -v \
    &> mdrun_NPT_MD.out \
    || { echo " something wrong on NPT MD RUN!! exiting..."; echo "exit" > "${_mypipe}"; exit; }
	cp mdout.mdp "${DOUBLE_CHECK_FOLDER}"/mdoutNPT_seq"${SEQUENCE}".mdp

  printf "Temperature\n0\n"         | ${ENERGY} -f NVT.edr -o temp_NVT.xvg\
	            &> energy.temp || { msg "Somthing wrong on the energy check.."; }
  printf "Pressure\nDensity\n0\n"   | ${ENERGY}  -f NPT.edr -o press_NPT.xvg\
	            &> energy.temp || { msg "Somthing wrong on the energy check.."; }
  cp ./grompp*_seq*out ./*edr ./*xvg "${DOUBLE_CHECK_FOLDER}"
}

MakeNewMinimConfig_SAMD () {
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
	local _mypipe=out.out

	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-gro)	shift; _INPUT_structure_fileNAME=$1;;
		-SA)	shift; _SAMDmdp_NAME=$1;;
		-NVT)	shift; _NVTmdp_NAME=$1;;
		-NPT)	shift; _NPTmdp_NAME=$1;;
		-top)	shift; _top_NAME=$1;;
		-out)	shift; _OUTPUTgro=$1;;
    -pipe)shift; _mypipe=$1;;
		*)	fatal 1 "MutantRearangement() ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
	_top_NAME="${_top_NAME%.top}"
	_OUTPUTgro="${_OUTPUTgro%.*}"

	# Simulated Annealing-MD to find a energy minimum from which start (every run will start at a different minima)
	msg "$(date +%H:%M:%S) --running Simulated Annealing MD (SA-MD) to find a new minima.. " | tee -a "$LOGFILENAME"
	$GROMPP -f "${_SAMDmdp_NAME}" -c "${_INPUT_structure_fileNAME}" -r "${_INPUT_structure_fileNAME}" \
	  -p "${_top_NAME}.top" -t "state_NPT_MD.cpt" -o "system_SAMD.tpr" -maxwarn 1 &> gromppSAMD_seq"${SEQUENCE}".out \
    || { echo " something wrong on SA-MD GROMPP!! exiting..."; echo "exit" > "${_mypipe}" ; exit; }
	$MDRUN_md -s "system_SAMD.tpr" -c "${_OUTPUTgro}.gro" -cpo "state_SAMD.cpt" -x "traj_SAMD.xtc" -e SAMD.edr -v \
    &> output_SAMD.temp \
    || { echo " something wrong on SA-MD RUN!! exiting..."; echo "exit" > "${_mypipe}"; exit; }
	cp ./mdout.mdp "${DOUBLE_CHECK_FOLDER}"/mdoutSAMD_seq"${SEQUENCE}".mdp

	printf "Temperature\nDensity\nPressure\n0\n" | ${ENERGY} -f SAMD.edr -o temp_SAMD.xvg\
	            &> energy.temp || { msg "Somthing wrong on the energy check.."; }
  printf "1\n1\n" | ${RMS} -s "system_SAMD.tpr" -f "traj_SAMD.xtc" -o "rmsd_SAMD${SEQUENCE}.xvg" \
	            -tu ps &> rms.temp || { msg "Somthing wrong on the rms check.. continue"; cat rms.temp; }
  cp ./grompp*_seq*out ./*edr ./*xvg "${DOUBLE_CHECK_FOLDER}"


	# NVT ensemble ("isothermal-isochoric" or "canonical")
	#msg "$(date +%H:%M:%S) --running NVT MD for for Temperature equilibration.. " | tee -a "$LOGFILENAME"
	#$GROMPP -f "${_NVTmdp_NAME}" -c system_SAMD.gro -r system_SAMD.gro -p "${_top_NAME}.top" -o system_NVT_MD.tpr -t state_SAMD.cpt \
  #  &> output.temp \
  #  || { echo " something wrong on NVT GROMPP!! exiting..."; echo "exit" > "${_mypipe}"; exit; }
	#$MDRUN_md -s system_NVT_MD.tpr -c system_NVT_MD.gro -cpo state_NVT_MD.cpt \
  #  &> mdrun_NVT_MD.out \
  #  || { echo " something wrong on NVT MD RUN!! exiting..."; echo "exit" > "${_mypipe}"; exit; }

	# NPT ensemble ("isothermal-isobaric")
	#msg "$(date +%H:%M:%S) --running NPT MD for Pressure equilibration.. " | tee -a "$LOGFILENAME"
	#$GROMPP -f "${_NPTmdp_NAME}" -c system_NVT_MD.gro -r system_NVT_MD.gro -p "${_top_NAME}.top" -o system_NPT_MD.tpr -t state_NVT_MD.cpt \
  #  &> output.temp \
  #  || { echo " something wrong on NPT GROMPP!! exiting..."; echo "exit" > "${_mypipe}"; exit; }
	#$MDRUN_md -s system_NPT_MD.tpr -c "${_OUTPUTgro}.gro" -x traj_NPT_MD.xtc \
  #  &> mdrun_NPT_MD.out \
  #  || { echo " something wrong on NPT MD RUN!! exiting..."; echo "exit" > "${_mypipe}"; exit; }

}
