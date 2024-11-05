#!/bin/bash

##########################################################################
# Title      :	ABiSS - Antibody in Silico Selection
# Author     :	Damiano Buratto - damianoburatto@gmail.com
# Date       :	2018 Jan 29
# Requires   :	Gromcas, vmd, chimera, Python 3.8 or higher, Antechamber, OpenBabel (optional, but strongly recommended)
# Category   :	derived from ABiSS
# Version    :	0.6 (2023 August )
#
##########################################################################

# Description
#    NOTES: - In the structure file, the Receptor MUST be before the LIGAND (Antibody)
#	          - At the end of the energy computation for the WT, you should check all the files inside the DOUBLE_CHECK folder
#             to be sure that all the computations went as planned. (The files will be update at the end of every mutation)
#           - The input files used by the program are created by function or are taken from the the ABiSS_lib
#           - The functions PosResSelection and MakePOSRES_protein must be DOUBLE CHECKED and changed adhoc
#    o
#
# Examples:
#   ABiSS_custom.sh -I INPUT_*.in -np "$NP" -cluster "IQB" -v
#   ABiSS_custom.sh -I INPUT_*.in -np "$NP" -cluster "IQB" -v -R "RUN1/SETUP_PROGRAM_FILES/abiss_settings.sh"
##########################################################################

exec 5> debug_output.txt
# exec 5> >(logger -t $0)
BASH_XTRACEFD="5"
PS4='$LINENO: '
set -x

set -o errtrace # Enable the err trap, code will get called when an error is detected
trap "echo ERROR: There was an error in ${FUNCNAME[0]-main context}, details to follow ->" ERR

# Variables that are used across functions are generally named with CAPITALS.
PN=$(basename "$0")			# Program name / basename $BASH_SOURCE
ProgramPATH=$(readlink -f "$0")		# Program path	OLD->dirname / realpath ${BASH_SOURCE[0]}
ProgramPATH="${ProgramPATH%/*}"
ProgramINPUTs="$*"
STARTING_FOLDER=$PWD
ABiSS_LIB="${ProgramPATH}/ABiSS_lib"
FUNCTIONs_FOLDER="${ProgramPATH}/ABiSS_lib/FUNCTIONs"
MDPs_FOLDER="${ProgramPATH}/ABiSS_lib/MDPs"
FORCE_FIELDs_FOLDER="${ProgramPATH}/ABiSS_lib/FORCE_FIELDs"
VER='0.6'
export ProgramPATH
export STARTING_FOLDER
export ABiSS_LIB
export FUNCTIONs_FOLDER
export MDPs_FOLDER
# export GMXLIB=${GMXDATA}/top:${FORCE_FIELDs_FOLDER}
export GMXLIB=${FORCE_FIELDs_FOLDER}

function update_variables_file() {
  _input_file=$1; shift
  _verbose=$1; shift
  _variables=("$@")
  msg -t "Updating the variable file.."
  update_array=()
  for variable in ${_variables[*]}; do
    update_array+=("$variable"'="'"${!variable}"'"')
    #eval 'update_array+=('"$variable"'="${'"$variable"'[@]}")'
  done
  if [[ $_verbose == "True" ]]; then
    python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${_input_file}" -u "${update_array[@]}" -v || { exit; }
  else
    python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${_input_file}" -u "${update_array[@]}" || { exit; }
  fi
}

function run_md_for_every_cycle() {
  _relaxed_system=$1
  _topName=$2
  _tprFILE=$3
  _trjNAME=$4
  _Cycle_Number=1

  while [ "${_Cycle_Number}" -le "${RunningNum_PerSystem}" ]; do
    # All the cycle${_Cycle_Number}_MD folders have been built by BuildFoldersAndPrintHeadingFiles.sh
	  _cycle_number_MD_FOLDER="$current_conf_PATH/cycle${_Cycle_Number}_MD"
    msg "[run_md_for_every_cycle] -> **$(date "+%d-%m-%y %H:%M:%S") starting SAMD on cycle ${_Cycle_Number} **"
    _start_time=$(stopwatch -s)
    #RECOVERING PDB and TOPOLOGY FILEs (particularly useful when it start the 2nd cycle)
    cd "$_cycle_number_MD_FOLDER" || fatal 1 "Cannot enter '$_cycle_number_MD_FOLDER' folder"
    mkfifo "$_cycle_number_MD_FOLDER"/mypipe || fatal 2 "Cannot make \"mypipe\" file"
    cp "${repository_FOLDER}/${_relaxed_system}" ./
    cp "${repository_FOLDER}/"topol.top ./
    cp "${repository_FOLDER}/"*rotein_chain_*.itp ./
    cp "${repository_FOLDER}/"posres_*.itp ./
    cp "${repository_FOLDER}/"*NPT*.cpt ./

    # e.g. MakeNewMinimConfig -gro starting_file.ext -SA SAMD.mdp -NVT NVT.mdp -NPT NPT.mdp -top topol.top -out outputNAME
    MakeNewMinimConfig_SAMD -gro "system_equil.gro" -SA "${SAMD_NAME}" \
                       -top "${_topName}.top" -out "system_Compl_MDstart" -pipe "$_cycle_number_MD_FOLDER"/mypipe \
                       &> "${_cycle_number_MD_FOLDER}/SAMD.out"

    msg "[run_md_for_every_cycle] -> $(date "+%d-%m-%y %H:%M:%S") --running \"Produciton\" MD of the model.. "
    if [[ $VERBOSE == True ]]; then
      echo "";
      msg -v "$GROMPP -f "${MD_EngComp_ff14sb_NAME}" -c system_Compl_MDstart.gro -r system_Compl_MDstart.gro "\
          "-p ${_topName}.top -o ${_tprFILE}.tpr \t";
      msg -v "${MPI_RUN} $MDRUN_md -s ${_tprFILE}.tpr -c system_Compl_MD.gro -x ${_trjNAME}.xtc \t";
      echo ""
    fi
    $GROMPP -f "${MD_EngComp_ff14sb_NAME}" -c "system_Compl_MDstart.gro" -r "system_Compl_MDstart.gro" \
      -p "${_topName}.top" -o "${_tprFILE}.tpr" -t "state_SAMD.cpt" 	&> gromppPROD_seq"${SEQUENCE}".out \
      || { msg " something wrong on GROMPP!! exiting..."; echo "exit" > "$_cycle_number_MD_FOLDER"/mypipe; exit; }
    $MDRUN_md -s "${_tprFILE}.tpr" -c "system_Compl_MD.gro" -x "${_trjNAME}.xtc" -e PROD.edr -v &> Prod_MD.out \
      || { msg " something wrong on production MDRUN!! exiting..."; echo "exit" > "$_cycle_number_MD_FOLDER"/mypipe; exit; }
	  if [[ "${_Cycle_Number}" -eq 1 ]]; then
	    printf "Temperature\nPressure\nDensity\n0\n" | ${ENERGY} -f PROD.edr -o "PROD${SEQUENCE}.xvg" \
	            &> energy.temp || { msg "Somthing wrong on the energy check.. continue"; }
	    printf "1\n1\n" | ${RMS} -s "${_tprFILE}.tpr" -f "${_trjNAME}.xtc" -o "rmsd_PROD${SEQUENCE}.xvg" -a "avgPROD${SEQUENCE}.xvg" \
	            -tu ps &> rms.temp || { msg "Somthing wrong on the rms check.. continue"; cat rms.temp; }
	    cp mdout.mdp "${DOUBLE_CHECK_FOLDER}"/mdoutPROD_seq"${SEQUENCE}".mdp;
	    cp gromppPROD_seq"${SEQUENCE}".out ./*edr ./*xvg "${DOUBLE_CHECK_FOLDER}";
	  fi
    cp "system_Compl_MD.gro" "LastFrame_cycle${_Cycle_Number}.gro"

    msg "[run_md_for_every_cycle] -> DONE MD on cycle_${_Cycle_Number} $(stopwatch -f "$_start_time")" > "$_cycle_number_MD_FOLDER"/mypipe
		((_Cycle_Number+=1))
    #mv ${_trjNAME}.part0002.xtc ${_trjNAME}.xtc
  done
  msg "[run_md_for_every_cycle] -> DONE with all MD"
}

#====================================================================================================================================================
# 	STARTING OPTIONs
#====================================================================================================================================================
# LOADING ALL THE FUNCTIONS NEEDED
source "${FUNCTIONs_FOLDER}"/functions_list.sh
echo ""

ALL_VARIABLES=(SystemName tprFILE trjNAME topName receptorFRAG ABchains EnergyFunction EnergyCalculation
GMXPBSApath JerkwinPROGRAM CPATH APATH GPATH linearizedPB precF pdie
trjconvOPT GsourcePATH startingFrameGMXPBSA NUMframe mergeFragments mergeC mergeR mergeL
CONDA_activate_path CONDA_gmxmmpbsa_name CONDA_modeller_name mmpbsa_inFILE use_decomp_as_weights resid_be_decomp_files
RunningNum_PerSystem reuse_MD reuse_MD_PATH reuse_MD_abiss_settings Starting_Configuration
Stored_AVG Stored_STD ForceField ResiduePool_list TargetResidueList editconf_opt editconf_opt2 editconf_opt3
Consecutive_DISCARD_Count Eff_Metropolis_Temp Metropolis_Temp_cap average_all_frames Make_new_mutation
complex_FILE complex_EXT Stored_system_FILE MD_EngComp_ff14sb_NAME AcceptProb
Protein_MD_EngComp_ff14sb_NAME source_GMX
KEY_annealing KEY_SA_npoints KEY_SA_temp KEY_SA_time KEY_nsteps_minim KEY_nsteps_SAMD KEY_nsteps_NVT
KEY_nsteps_NPT KEY_nsteps_MD  KEY_nstouts_SAMD KEY_nstouts_NVT KEY_nstouts_NPT KEY_nstouts_MD
KEY_compressed KEY_define_SAMD KEY_define_MD KEY_pcoupl
minim_NAME SAMD_NAME NVT_NAME NPT_NAME PYTHON AWK VMD CHIMERA POSRES POSRES_RESIDUES
SEQUENCE current_conf_PATH RUN_FOLDER SETUP_PROGRAM_FOLDER LOGFILENAME TEMP_FILES_FOLDER CONFOUT_FILENAME
DOUBLE_CHECK_FOLDER GROMPP MDRUN MDRUN_md PDB2GMX EDITCONF GENBOX GENION MAKE_NDX TRJCONV GENRESTR CHECK ENERGY RMS GROMACSver
PN ProgramPATH STARTING_FOLDER ABiSS_LIB FUNCTIONs_FOLDER MDPs_FOLDER VER Complex_file_name MaxMutant
metropolis_correction Metropolis_Temp keep_hydration Restart_calculations cluster CUDA_visible_devices GMXPBSAminim
GMXPBSA_NO_topol_ff GMXPBSA_use_tpbcon NP_value SELFAVOIDING_FILENAME FAST VERBOSE)

# STARTING_VARIABLES contain all the variables that can be set outside of the INPUT file.
# That means all the variable set by the user from command line and the PROGRAM PATHs/Name set at the beginning.
# The variable set by the user are going to overwrite the INPUT file
STARTING_VARIABLES=(PN ProgramPATH STARTING_FOLDER ABiSS_LIB FUNCTIONs_FOLDER MDPs_FOLDER VER Complex_file_name MaxMutant
metropolis_correction Metropolis_Temp keep_hydration Restart_calculations cluster CUDA_visible_devices GMXPBSAminim
GMXPBSA_NO_topol_ff GMXPBSA_use_tpbcon NP_value SELFAVOIDING_FILENAME FAST VERBOSE)

# SIMULATION OPTIONS
# Starting_User_Inputs -> cannot be use like this
VERBOSE=False
while [ $# -gt 0 ]
do
    case "$1" in
  -I)       shift; input_file="$1";;
  -cf)      shift; Complex_file_name="$1";;
  -mm)      shift; MaxMutant="$1";;
  -m_cor)   metropolis_correction="True";;
  -mtemp)   shift; Metropolis_Temp="$1";;
  -kh)      keep_hydration="-kh";;
  -R)		    Restart_calculations="True"; abiss_settings_RESTART="$1";;				        # with this option, the program has to be started inside the folder with the trajectories
  -cluster)	shift; cluster="$1";;                       # OPTIONS are: SIAIS, IQB
  -gpu)     shift; CUDA_visible_devices="$1";;
  -min)		  GMXPBSAminim="y";;
  -noTF)		GMXPBSA_NO_topol_ff="-noTF";;
  -utc)		  GMXPBSA_use_tpbcon="-utc";;
  -np)		  shift; NP_value=$1;;					              # Number of parallel Process (only for cluster option)
  -sa)      shift; SELFAVOIDING_FILENAME=$1;;
  -s)       shift; source_GMX="$1";;
  -t)		    FAST="True";;
  -v)       VERBOSE="True";;
  *)		    if [ "$1" == "" ]; then
              shift
              continue
            fi
		        fatal 1 "UserInput ERROR: $1 is not a valid OPTION!\n$*";;
    esac
    shift
done

[[ -r $input_file ]] || { echo "You must give me a readable input file with the -I option! ($input_file)"; exit; }
msg -t "Loading the INPUT file.. "
# Read the input_file and print a abiss_settings.sh file with input_file values + Default values
if [[ $VERBOSE == "True" ]]; then
  python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${input_file}" -o "./abiss_settings.sh" -v || { exit; }
else
  python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${input_file}" -o "./abiss_settings.sh" || { exit; }
fi

if [[ $Restart_calculations != "True" ]]; then
  # Update the abiss_settings.sh file with the STARTING_VARIABLES
  # STARTING_VARIABLES contain all the variables that are set outside of the INPUT file.
  # That means all the variable set by the user from command line and the PROGRAM PATHs/Name set at the beginning.
  # The variable set by the user are going to overwrite the INPUT file
  update_variables_file "./abiss_settings.sh" "$VERBOSE" "${STARTING_VARIABLES[@]}"
  # shellcheck source=/home/damiano/data/ZJU_work/PROGRAMMING/InSilicoMaturation/ABiSS_custom_v6/abiss_settings.sh
  # Finally source the abiss_settings.sh file with all the variables values
  source abiss_settings.sh

  #====================================================================================================================================================
  # 	VARIABLES, INPUT files and PATHS
  #====================================================================================================================================================
  # RUN# folder
  flag="0"
  while [ 1 -gt 0 ]
  do
    ((flag+=1))
    [ -d "RUN${flag}" ] && continue

    fd="RUN${flag}"
    break
  done
  mkdir ${fd}

  export GROMPP= ;export MDRUN= ;export MDRUN_md= ;export PDB2GMX=
  export EDITCONF= ;export GENBOX= ;export GENION=
  export MAKE_NDX= ;export TRJCONV= ;export GENRESTR= ;export CHECK=
  GROMACSver=
  # Other Programs
  export PYTHON=
  export AWK="${AWK:-gawk}"
  export VMD="findPATH"
  export CHIMERA="findPATH"

  export current_conf_PATH=
  LOGFILENAME="${STARTING_FOLDER}/${fd}/${fd}.out"; echo -n "" > "${LOGFILENAME}"       ;export LOGFILENAME
  RUN_FOLDER="${STARTING_FOLDER}/${fd}"                                                 ;export RUN_FOLDER
  SETUP_PROGRAM_FOLDER="${RUN_FOLDER}/SETUP_PROGRAM_FILES"                              ;export SETUP_PROGRAM_FOLDER
  DOUBLE_CHECK_FOLDER="${RUN_FOLDER}/DOUBLE_CHECK"                                      ;export DOUBLE_CHECK_FOLDER
  TEMP_FILES_FOLDER="${RUN_FOLDER}/tempFILES"
  CONFOUT_FILENAME="${RUN_FOLDER}/conf_${fd}.out"                                       ;export CONFOUT_FILENAME
  if [[ $SELFAVOIDING_FILENAME == "" ]]; then
    SELFAVOIDING_FILENAME="${SETUP_PROGRAM_FOLDER}/self_avoiding_file.out"              ;export SELFAVOIDING_FILENAME
  else
    msg "coping global SELFAVOIDING_FILENAME=$SELFAVOIDING_FILENAME"
    cp "$SELFAVOIDING_FILENAME" "${SETUP_PROGRAM_FOLDER}/self_avoiding_file.out" || fatal 1 "failed to copy $SELFAVOIDING_FILENAME"
    SELFAVOIDING_FILENAME="${SETUP_PROGRAM_FOLDER}/self_avoiding_file.out"              ;export SELFAVOIDING_FILENAME
  fi
  mkdir "${TEMP_FILES_FOLDER}"
  mkdir "${SETUP_PROGRAM_FOLDER}"
  mkdir "${DOUBLE_CHECK_FOLDER}"

  #====================================================================================================================================================
  # 	Setting variables
  #====================================================================================================================================================
  # GROMACS_CheckSet
  [ "$cluster" != "no" ] && msg "Using configurations for $cluster.." | tee -a "$LOGFILENAME"
  msg "Checking Gromacs version.." | tee -a "$LOGFILENAME"
  GROMACS_CheckSet "$cluster"
  Set_cluster_variables "$cluster"

  #====================================================================================================================================================
  # 	BASIC CHECKS
  #====================================================================================================================================================
  [ -r "$Complex_file_name" ] || fatal 2 "ERROR: (PWD=$PWD file:'$Complex_file_name') STRUCTURE INPUT file can not be found or read"
  complex_EXT="${Complex_file_name##*.}"						# ${string##substring}  ->  Deletes longest match of $substring from front of $string.
  complex_FILE="${Complex_file_name%.*}"
  [ "$complex_EXT" != "pdb" ] && fatal 1 "The Input configuration must be a pdb file (with chains and TER specified)"


  # General checkings
  [[ -r "${CONDA_activate_path}/activate" ]] || fatal 2 "ERROR: cannot find conda activate '$CONDA_activate_path'"
  ver=$(python --version);msg "python -> $(which python) $ver"
  ver=$($PYTHON --version);msg "PYTHON variable -> $(which $PYTHON) $ver"
  [[ "$(which python)" != "$(which $PYTHON)" ]] && msg "WARNING: python and $PYTHON are pointing to different locations"
  msg "GMX -> ${GMX}";msg "GROMPP -> ${GROMPP}"; msg "MPI_RUN MDRUN -> ${MPI_RUN} ${MDRUN}"

  GMXPBSApath="${ProgramPATH}/gmxpbsa-master"
  JerkwinPROGRAM="${ABiSS_LIB}/Jerkwin_mmpbsa.bsh"
  JerkwinPATH="${ABiSS_LIB}"

  findPATH "$VMD" vmd VMD; VMD="${VMD}/vmd"
#  findPATH "$CHIMERA" chimera CHIMERA; CHIMERA="${CHIMERA}/chimera"
  findPATH "$APATH" apbs APATH
  # GPATH is used by gmxpbsa and I want it to be gromacs 4.6.7 (->NO gmx)
  findPATH "$GPATH" mdrun GPATH

  [ -x "${GMXPBSApath}"/gmxpbsa0.sh ] || fatal 13 "Cannot find executable gmxpbsa0.sh at '${GMXPBSApath}'!! Please check the path."
  [ -x "${GMXPBSApath}"/gmxpbsa1.sh ] || fatal 13 "Cannot find executable gmxpbsa1.sh at '${GMXPBSApath}'!! Please check the path."
  [ -x "${GMXPBSApath}"/gmxpbsa2.sh ] || fatal 13 "Cannot find executable gmxpbsa2.sh at '${GMXPBSApath}'!! Please check the path."

  if [[ $VERBOSE == "True" ]]; then
    msg -v " CONDA_activate_path=${CONDA_activate_path} \n\t\t CONDA_gmxmmpbsa_name=${CONDA_gmxmmpbsa_name} \
    \n\t\t CONDA_modeller_name=${CONDA_modeller_name} \n\t\t GMXPBSApath=${GMXPBSApath} \n\t\t CPATH=${CPATH} \n\t\t APATH=${APATH} \
    \n\t\t GPATH=${GPATH} \n\t\t VMD=${VMD} \n\t\t CHIMERA=${CHIMERA} \n\t\t FORCE_FIELD=${FORCE_FIELD} \n\t\t GMX=${GMX} \n\t\t GROMPP=${GROMPP} \
  	\n\t\t MDRUN=${MDRUN} \n\t\t EDITCONF=${EDITCONF} \n\t\t PDB2GMX=${PDB2GMX} \n\t\t GENBOX=${GENBOX} \n\t\t GENION=${GENION} \
  	\n\t\t MAKE_NDX=${MAKE_NDX} \n\t\t TRJCONV=${TRJCONV} \n\t\t GENRESTR=${GENRESTR} \n\t\t CHECK=${CHECK} \n\t\t MPI_RUN=${MPI_RUN} \
  	\n\t\t MDRUN=${MDRUN} \n\t\t MDRUN_md=${MDRUN_md} \n\t\t KEY_compressed=${KEY_compressed}" | tee -a "$LOGFILENAME"
  fi
  #====================================================================================================================================================
  #	 VARIABLEs INITIALIZATION
  #====================================================================================================================================================
  cd "${RUN_FOLDER}" || fatal 1 "Cannot enter '${RUN_FOLDER}' folder"
  # FILE WITH THE INITIALIZATION OF ALL THE VARIABLE
  msg -t "Initializing the MDP and other input files.." | tee -a "$LOGFILENAME"
  MDPs_setup
  # [ "$Starting_Configuration" -eq 1 ] && Stored_system_FILE="${complex_FILE}"
  cp "${STARTING_FOLDER}/${input_file}" "${SETUP_PROGRAM_FOLDER}"
  #===============================================================================================================================================================
  #	 UPDATING VARIABLE FILE
  #====================================================================================================================================================
  #msg "Writing the Checkpoint.."
  #printCHECKPOINT "$LOGFILENAME"
  mv "${STARTING_FOLDER}"/abiss_settings.sh "${SETUP_PROGRAM_FOLDER}"
  update_variables_file "${SETUP_PROGRAM_FOLDER}"/abiss_settings.sh "$VERBOSE" "${ALL_VARIABLES[@]}"

  msg "Checking all the variables.." | tee -a "$LOGFILENAME"
  # Run a check of the variables
  $PYTHON "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${SETUP_PROGRAM_FOLDER}"/abiss_settings.sh -c || { exit; }
  #====================================================================================================================================================
  #	start the FOR cycle for the mutations
  #====================================================================================================================================================
  echo -e -n "ResNum\t" > "$CONFOUT_FILENAME"
  for residue in ${TargetResidueList}; do
    printf "%5s\t" "$residue" >> "$CONFOUT_FILENAME"
  done
  echo "" >> "$CONFOUT_FILENAME"
  Eff_Metropolis_Temp=${Metropolis_Temp}
else
  # shellcheck source=/home/damiano/data/ZJU_work/PROGRAMMING/InSilicoMaturation/ABiSS_custom_v6/abiss_settings.sh
  source "${abiss_settings_RESTART}" || { echo "Couldn't source settings (${abiss_settings_RESTART})"; exit; }
  msg "RESTARTING the program.. (RUN_FOLDER=$RUN_FOLDER)" | tee -a "$LOGFILENAME"
  # cp abiss_settings.sh "${SETUP_PROGRAM_FOLDER}"
  cd "${RUN_FOLDER}" || { exit; }
  Starting_Configuration=$SEQUENCE
  semilast_mutant_count="$( tail -n2 "${CONFOUT_FILENAME}" | head -n1 | wc -w )"
  last_mutant_count="$( tail -n1 "${CONFOUT_FILENAME}" | wc -w )"
  if [[ $last_mutant_count -lt $semilast_mutant_count ]]; then
    # delete the last line of the file (that is the uncompleted mutant) and add a blank line
    sed -i '$d' "${CONFOUT_FILENAME}"
    echo -e "\n" >> "${CONFOUT_FILENAME}"
  else
    # just add a blank line
    echo -e "\n" >> "${CONFOUT_FILENAME}"
  fi
fi




echo -e "\n****************        AntiBody in Silico Selection Program  -custom-		 ******************" | tee -a "${LOGFILENAME}"
echo -e   "****************        $ProgramPATH/$PN	" | tee -a "${LOGFILENAME}"
echo -e   "****************        v $VER					    \n" | tee -a "${LOGFILENAME}"
#Print DATE and the whole command line used to run the program
echo -e ">>DATE: $(date)" | tee -a "${LOGFILENAME}"
echo ">>${PN} ${ProgramINPUTs}" | tee -a "${LOGFILENAME}"; echo -e "\n" | tee -a "${LOGFILENAME}"


# Coping the important files inside the RUN folder
cp "${STARTING_FOLDER}/${complex_FILE}.${complex_EXT}" "${RUN_FOLDER}"
# STARTING THE MUTANTs CYCLE
for SEQUENCE in $(seq "$Starting_Configuration" "$MaxMutant"); do
  cd "${RUN_FOLDER}" || fatal 1 "Cannot enter '${RUN_FOLDER}' folder"
  update_variables_file "${SETUP_PROGRAM_FOLDER}"/abiss_settings.sh "$VERBOSE" "${ALL_VARIABLES[@]}"
	if [[ "$SEQUENCE" -eq 0 ]]; then
		[[ -d "${RUN_FOLDER}/Config${SEQUENCE}" ]] && { msg "Removing folder Config${SEQUENCE}.."; rm -fr "Config${SEQUENCE}"; }
		mkdir "${RUN_FOLDER}/Config${SEQUENCE}"
		cd "${RUN_FOLDER}/Config${SEQUENCE}" || fatal 1 "Cannot enter 'Config${SEQUENCE}' folder"
		current_conf_PATH="$PWD"
		echo -e "\n# **********************************************************************************************" | tee -a "$LOGFILENAME"
		msg       "         ****** STARTING WITH Config$SEQUENCE (it will run ${RunningNum_PerSystem} times) ******" | tee -a "$LOGFILENAME"
		msg "PATH:$current_conf_PATH" | tee -a "$LOGFILENAME"
		echo -n -e "WT  \t" >> "$CONFOUT_FILENAME"
	else
		[[ -d "${RUN_FOLDER}/Mutant${SEQUENCE}" ]] && { msg "Removing folder Mutant${SEQUENCE}.."; rm -fr "Mutant${SEQUENCE}"; }
		mkdir "${RUN_FOLDER}/Mutant${SEQUENCE}"
		cd "${RUN_FOLDER}/Mutant${SEQUENCE}" || fatal 1 "Cannot enter 'Mutant${SEQUENCE}' folder"
		current_conf_PATH="$PWD"
		echo -e "\n# **********************************************************************************************" | tee -a "$LOGFILENAME"
		msg       "         ****** STARTING WITH Mutant$SEQUENCE (it will run ${RunningNum_PerSystem} times) ******" | tee -a "$LOGFILENAME"
		msg "PATH:$current_conf_PATH" | tee -a "$LOGFILENAME"
		printf "%-4s\t" "M$SEQUENCE" >> "$CONFOUT_FILENAME"
	fi
	cp "$RUN_FOLDER"/"${complex_FILE}".pdb "$current_conf_PATH"
	
	#====================================================================================================================================================
	# 	Make the NEW mutant 
	#====================================================================================================================================================
	# Metropolis_flag start equal to $Starting_Configuration and will be set =1 every time that Metropolis algorithm is ran
	if [[ "$Make_new_mutation" == "True" ]]; then
		# shellcheck disable=SC2068
#		MakeNewMutant_Chimera -pdb "${complex_FILE}.pdb" -on "./Mutant${SEQUENCE}" -tr ${TargetResidueList} \
#		-rp "$ResiduePool_list" -ts "$TargetChainName"
    new_mutant=True
    attempts=1
    source "${CONDA_activate_path}/activate" "${CONDA_modeller_name}" || fatal 66 "Could not activate Modeller"
    while [ "$new_mutant" == "True" ]; do
      if [[ ${use_decomp_as_weights} == "True" ]]; then
        if [[ $attempts -lt 4 ]]; then
          msg "$(date "+%d-%m-%y %H:%M:%S") Making a new mutation (Keep Hydration=${keep_hydration})..." | tee -a "$LOGFILENAME"
          python "${FUNCTIONs_FOLDER}"/MakeNewMutant_Modeller.py "${complex_FILE}.pdb" -s "${SystemName}" -o "./Mutant${SEQUENCE}" \
                  -rl ${TargetResidueList} -rw ${resid_be_decomp_files[*]} ${keep_hydration} -v || fatal 22 "MakeNewMutant_Modeller.py failed!"
        else
          # If after 20 mutation I still cannot find a different sequence, force a random mutation without "keep_hydration"
          msg "$(date "+%d-%m-%y %H:%M:%S") Making a new mutation (All Random)..." | tee -a "$LOGFILENAME"
          python "${FUNCTIONs_FOLDER}"/MakeNewMutant_Modeller.py "${complex_FILE}.pdb" -s "${SystemName}" -o "./Mutant${SEQUENCE}" \
                  -rl ${TargetResidueList} -rw ${resid_be_decomp_files[*]} -v || fatal 22 "MakeNewMutant_Modeller.py failed!"
        fi
      else
        if [[ $attempts -lt 6 ]]; then
          msg "$(date "+%d-%m-%y %H:%M:%S") Making a new mutation (Keep Hydration=${keep_hydration})..." | tee -a "$LOGFILENAME"
          python "${FUNCTIONs_FOLDER}"/MakeNewMutant_Modeller.py "${complex_FILE}.pdb" -s "${SystemName}" -o "./Mutant${SEQUENCE}" \
                  -rl ${TargetResidueList} ${keep_hydration} -v || fatal 22 "MakeNewMutant_Modeller.py failed!"
        else
          # If after 20 mutation I still cannot find a different sequence, force a random mutation without "keep_hydration"
          msg "$(date "+%d-%m-%y %H:%M:%S") Making a new mutation (All Random)..." | tee -a "$LOGFILENAME"
          python "${FUNCTIONs_FOLDER}"/MakeNewMutant_Modeller.py "${complex_FILE}.pdb" -s "${SystemName}" -o "./Mutant${SEQUENCE}" \
                  -rl ${TargetResidueList} -v || fatal 22 "MakeNewMutant_Modeller.py failed!"
        fi
      fi
      new_mutant=False
      # Check that the sequence hasn't be tested already (self avoiding walk)
      VMD_function -pdb "./Mutant${SEQUENCE}" -t "RNAME" -ri "${TargetResidueList}"
      flag=$(grep "NAME_RESIDUE_SEARCHED:" vmd_RNAME.out | cut -d ":" -f 2);
      flag2=$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'<<<"${flag}");
      while read -r line; do
        if [[ $line == "$flag2" ]]; then
          msg "$flag2 sequence already tested \n\t\t\t\t\t($line)\n\t\t\t\t\t..." | tee -a "$LOGFILENAME"
          rm -f "./Mutant${SEQUENCE}".pdb
          ((attempts+=1)); new_mutant=True; break
        fi
      done < "$SELFAVOIDING_FILENAME"
      rm -f vmd_RNAME.out
	  done
    source "${CONDA_activate_path}/activate"
		msg "" | tee -a "$LOGFILENAME"
		rm -f "${complex_FILE}.pdb"
		complex_FILE="Mutant${SEQUENCE}"

		Metropolis_flag="0"
		# INSERT THE RIGHT "TER" IF THEY ARE MISSING
#		addTERpdb "${complex_FILE}".pdb
    # coping the current configuration on the main folder (important after MakeNewMutant_Chimera)
    cp "$current_conf_PATH/${complex_FILE}.pdb" "$RUN_FOLDER/${complex_FILE}_noH.pdb"
	fi

	#====================================================================================================================================================
	#====================================================================================================================================================

#	VMD_function -pdb "${complex_FILE}" -t "RNAME" -ri "${TargetResidueList}" -cn "${TargetChainName}"
  VMD_function -pdb "${complex_FILE}" -t "RNAME" -ri "${TargetResidueList}"
	flag="$(grep "NAME_RESIDUE_SEARCHED:" vmd_RNAME.out | cut -d ":" -f 2)"
#	echo -n -e "$flag\t" >> "$CONFOUT_FILENAME";
  for residue in $flag; do
    printf "%4s \t" "$residue" >> "$CONFOUT_FILENAME"
  done
	echo "$flag" >> "$SELFAVOIDING_FILENAME"

  # "cycle${Cycle_Number}_MD"
  # repository_FOLDER results_FOLDER removed_files_FOLDER TEMP_FILES_FOLDER(only if not already defined)
	BuildFoldersAndPrintHeadingFiles "$RunningNum_PerSystem"
	#

  if [[ "${reuse_MD}" == "True" ]] && [[ "$SEQUENCE" -eq 0 ]]; then
    # TODO what do I need for this option? add some checks
    msg "SEQUENCE=$SEQUENCE -> Using previously computed trajectories"
    [[ ${reuse_MD_PATH} == "" ]] && { fatal 11 "With reuse_MD=True you must assign the reuse_MD_PATH variable"; }
    [[ ${reuse_MD_abiss_settings} == "" ]] && { fatal 12 "With reuse_MD=True you must assign the reuse_MD_abiss_settings variable"; }
    reuse_nsteps=$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${reuse_MD_abiss_settings}/abiss_settings.sh" -k "KEY_nsteps_MD")
    reuse_nstouts=$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${reuse_MD_abiss_settings}/abiss_settings.sh" -k "KEY_nstouts_MD")
    reuse_ForceField=$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${reuse_MD_abiss_settings}/abiss_settings.sh" -k "ForceField")
    reuse_file_name=$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${reuse_MD_abiss_settings}/abiss_settings.sh" -k "Complex_file_name")
    if [[ $KEY_nsteps_MD != "$reuse_nsteps" ]]; then
      fatal 13 "You can reuse previous MD only if they have the same KEY_nsteps_MD"
    fi
    if [[ $KEY_nstouts_MD != "$reuse_nstouts" ]]; then
      fatal 14 "You can reuse previous MD only if they have the same KEY_nstouts_MD"
    fi
    if [[ $ForceField != "$reuse_ForceField" ]]; then
      fatal 15 "You can reuse previous MD only if they have the same ForceField"
    fi
    if [[ $Complex_file_name != "$reuse_file_name" ]]; then
      warning 21 "You are using a different structure file_name ($Complex_file_name) from the reuse simulation ($reuse_file_name)"
    fi
    if [[ $VERBOSE == True ]]; then
      msg -v "KEY_nsteps_MD=$KEY_nsteps_MD reuse_nsteps=$reuse_nsteps"
      msg -v "KEY_nstouts_MD=$KEY_nstouts_MD reuse_nstouts=$reuse_nstouts"
      msg -v "ForceField=$ForceField reuse_ForceField=$reuse_ForceField"
      msg -v "Complex_file_name=$Complex_file_name reuse_file_name=$reuse_file_name"
      ## TODO ADD POSRES
    fi
    Cycle_Number="1"
    while [ "${Cycle_Number}" -le "${RunningNum_PerSystem}" ]; do
      cp -r "${reuse_MD_PATH}/cycle${Cycle_Number}_MD" "${current_conf_PATH}" || fatal 1 "Cannot cp '${cycle_number_MD_FOLDER}' folder"
      msg "DONE MD on cycle_${Cycle_Number}" > "${current_conf_PATH}/cycle${Cycle_Number}_MD/mypipe" &

      ((Cycle_Number+=1))
    done
    cp "${reuse_MD_PATH}/"*gro "${reuse_MD_PATH}/"*pdb "${reuse_MD_PATH}/"*top "${reuse_MD_PATH}/"*itp "${repository_FOLDER}/"

  else
    #====================================================================================================================================================
    #	 BUILD TOPOLOGY FOR THE PROTEIN
    #====================================================================================================================================================
    msg "$(date +%H:%M:%S) --building PARAMETERS for the PROTEIN.. " | tee -a "$LOGFILENAME"
    if [[ $VERBOSE == True ]]; then
      echo ""; msg -v "MakeTOP_protein -pf ${complex_FILE} -ff $ForceField -tf topol -of system.gro ${mergeFragments} ";
      echo "    ${mergeC}"; echo""
    fi
    # MakeTOP_protein -> MAKE THE TOPOLOGY FILES
    MakeTOP_protein -pf "${complex_FILE}" -ff "$ForceField" -tf "topol" -of "system.gro" ${mergeFragments} ${mergeC}

  # coping the current configuration on the main folder (important after MakeNewMutant_Chimera)
  # after fixing TER and HIS (and change name back to $complex_FILE
    cp "$current_conf_PATH"/system.pdb "$current_conf_PATH"/"${complex_FILE}".pdb
  # INSERT THE RIGHT "TER" IF THEY ARE MISSING
    addTERpdb "${complex_FILE}".pdb || fatal 33 "addTERpdb failed"
    # CHANGE THE NAME OF ALL HISTIDINE TO HIS
    all_to_HIS -f "${complex_FILE}".pdb -o "$RUN_FOLDER"/"${complex_FILE}" || fatal 33 "all_to_HIS failed"
  #	cp "$current_conf_PATH"/"${complex_FILE}".pdb "$RUN_FOLDER"/"${complex_FILE}".pdb

    # BUILD THE BOX OF WATER
    msg "$(date +%H:%M:%S) --GENERATING the box and FILLING it with water and ions and minimize the energy.. "
    if [[ $VERBOSE == True ]]; then
      echo ""; msg -v "buildBoxWaterIons -s system.gro -t topol.top -m $minim_NAME ";
      msg -v "run_minim -mdp ${minim_NAME} -gro system_ions.gro -top topol -out system_Compl -n 1 "; echo ""
    fi
    # buildBoxWaterIons _startingSystem _topology (output: system_ions.gro)
    buildBoxWaterIons -s "system.gro" -t "topol.top" -m "$minim_NAME" || exit
    # run_minim -mdp minim_NAME -gro gro_NAME -top top_NAME -out output_NAME -n "3" (outpus is ${_output_NAME}_minim.gro )
    # RUN a set of energy minimization
    run_minim -mdp "${minim_NAME}" -gro "system_ions.gro" -top "topol" -out "system_Compl" -n 1
    relaxed_system="system_Compl_minim.gro"
    rm -f ./*# ./*~ &>> "$removed_files_FOLDER/rm.out"

    # PosResSelection SystemName(Cx, CXCR2, Covid, Covid-H, HLA_biAB)
    msg "$(date +%H:%M:%S) --GENERATING position restraints.. "
    if [[ $VERBOSE == True ]]; then
      echo ""; msg -v "PosResSelection -s ${SystemName} -pf ${relaxed_system} \t"; echo ""
    fi
    PosResSelection -s "${SystemName}" -pf "${relaxed_system}"

    msg "$(date +%H:%M:%S) --GENERATING equilibrated structure.. "
    # TODO what is this topName
    MakeNewMinim_NVT_NPT -gro "${relaxed_system}" -NVT "${NVT_NAME}" -NPT "${NPT_NAME}" \
                         -top "${topName}.top" -out "system_equil"

    mv "$current_conf_PATH/"*.cpt "${repository_FOLDER}"
    mv "$current_conf_PATH"/*top "$current_conf_PATH"/*itp "${repository_FOLDER}"
    mv "$current_conf_PATH/${complex_FILE}".pdb "$current_conf_PATH/${relaxed_system}" "$current_conf_PATH/system_equil.gro" "${repository_FOLDER}"
    mv ./*temp*.* ./*.temp ./*out "$removed_files_FOLDER"
    rm -f ./*#
    run_md_for_every_cycle "system_equil.gro" "${topName}" "${tprFILE}" "${trjNAME}" &
    #   &> "${current_conf_PATH}/MD.out"
    # INPUT_FILES:  ${REPOSITORY}/ ->   "${relaxed_system}" | topol.top | *rotein_chain_*.itp | posres_*.itp
    # OUTPUT_FILES: $current_conf_PATH/cycle${_Cycle_Number}_MD/ -> ${tprFILE}.tpr | ${trjNAME}.xtc |
    #                          "system_Compl_MD.gro"->"LastFrame_cycle${_Cycle_Number}.gro" | "system_Compl_MDstart.gro"
  fi

  Cycle_Number="1"
  confNAME="cycle${Cycle_Number}"
  rootName="cycle${Cycle_Number}_BE"
  cycle_number_MD_FOLDER="$current_conf_PATH/cycle${Cycle_Number}_MD"
  resid_be_decomp_files=()
	while [ "${Cycle_Number}" -le "${RunningNum_PerSystem}" ]; do
	  cd "$cycle_number_MD_FOLDER" || fatal 1 "Cannot enter '$cycle_number_MD_FOLDER' folder"
    sleep 5s
    WaitingTime=0
    # -e checks if the file exists
    while ! [[ -e "$cycle_number_MD_FOLDER"/mypipe ]]; do
      echo "$(date) waiting to find $cycle_number_MD_FOLDER/mypipe"
      sleep 1m
      ((WaitingTime++))
      [[ $WaitingTime == 10 ]] && fatal 1 "Unable to find $cycle_number_MD_FOLDER/mypipe (WaitingTime=${WaitingTime}m)"
    done
    msg "waiting for MD (${current_conf_PATH}/MD.out).."
    pipe_output=$(cat "$cycle_number_MD_FOLDER"/mypipe)
    [[ $pipe_output == "exit" ]] && fatal 11 "something wrong during MD.."
    rm -f "$cycle_number_MD_FOLDER"/mypipe
		#TODO compute the energy on a sub-selection of the system
		#====================================================================================================================================================
		#msg "                            --COMPUTE THE ENERGY-- 			"
		#====================================================================================================================================================
		# NEEDED files from simulations:
		# system_Compl_MD.gro		-->	starting frame of the long simulation
		# ${trjNAME}.xtc		-->	long simulation trajectory
		# ${tprFILE}.tpr		-->	long simulation tpr file
		# ${topName}.top		-->	topology used for the long simulation
		#====================================================================================================================================================
		
		#	 BUILD the INPUT FILE 
		msg "$(date +%H:%M:%S) --computing energy with $EnergyCalculation: Building INPUT file.. " | tee -a "$LOGFILENAME"; echo ""
		# TODO the AntibodyChains and ReceptorFragment are adhoc
		# makes a ${rootName} folder has index.ndx(receptor, ligand, complex), ${confNAME}.tpr and ${confNAME}_noPBC.xtc
		MakeFiles_GMXPBSA -gro "system_Compl_MD" -s_pdb "${repository_FOLDER}"/"${complex_FILE}".pdb -xtc "${trjNAME}" -tpr "${tprFILE}" \
		  -top "${topName}" -cn "${confNAME}" -rn "${rootName}" -ff "$ForceField" -np "$NP_value" -pF "$precF" -pd "$pdie" \
		  -ac "$ABchains" -rf "$receptorFRAG" -s "${startingFrameGMXPBSA}" -min "${GMXPBSAminim}" -m "${Protein_MD_EngComp_ff14sb_NAME}" \
		  -mergeC "$mergeC" -mergeR "$mergeR" "${GMXPBSA_use_tpbcon}" "${linearizedPB}" "${GMXPBSA_NO_topol_ff}" || exit
		number_of_frames="$(awk '($1 ~ /^Step/) { print $2 }' trj_check.out)"
    if [[ $VERBOSE == True ]]; then
      echo "";
      msg -v "MakeFiles_GMXPBSA -gro system_Compl_MD -s_pdb ${repository_FOLDER}/${complex_FILE}.pdb \
      -xtc ${trjNAME} -tpr ${tprFILE} -top ${topName} -cn ${confNAME} -rn ${rootName} \
      -ff $ForceField -np $NP_value -pF $precF -pd $pdie -ac $ABchains -rf $receptorFRAG \
      -s ${startingFrameGMXPBSA} -min ${GMXPBSAminim} -m ${Protein_MD_EngComp_ff14sb_NAME}"
		  echo "      -mergeC $mergeC -mergeR $mergeR ${GMXPBSA_use_tpbcon} ${linearizedPB} ${GMXPBSA_NO_topol_ff} || exit"
		  echo -e "      number_of_frames=$number_of_frames"
		  echo "";
    fi

		case "$EnergyCalculation" in
			GMXPBSA)
			  # ALL UNITS IN KJ/MOL
			  # OLD METHOD, NOT MAINTAINED
				#====================================================================================================================================================
				#	 RUNNING GMXPBSA
				msg "$(date +%H:%M:%S) --running gmxpbsa0.sh.. " | tee -a "$LOGFILENAME"
				bash "${GMXPBSApath}"/gmxpbsa0.sh &> gmxpbsa0.out
				if [ "$(grep "ERROR" gmxpbsa0.out)" != "" ]; then fatal 30 " something wrong on gmxpbsa0!! exiting..."; fi
				if ! [ -r "RUN1_${rootName}/REPORTFILE0" ]; then fatal 30 " something wrong on REPORTFILE0 (RUN1_${rootName}/REPORTFILE0)!! CHECK IT..."; fi
				
				msg "$(date +%H:%M:%S) --running gmxpbsa1.sh.. " | tee -a "$LOGFILENAME"
				bash "${GMXPBSApath}"/gmxpbsa1.sh &> gmxpbsa1.out
				if [ "$(grep "ERROR" gmxpbsa1.out)" != "" ]; then fatal 31 " something wrong on gmxpbsa1!! exiting..."; fi
				if ! [ -r "RUN1_${rootName}/REPORTFILE1" ]; then fatal 31 " something wrong on REPORTFILE1 (RUN1_${rootName}/REPORTFILE1)!! CHECK IT..."; fi
			
				msg "$(date +%H:%M:%S) --running gmxpbsa2.sh.. " | tee -a "$LOGFILENAME"
				bash "${GMXPBSApath}"/gmxpbsa2.sh &> gmxpbsa2.out
				if [ "$(grep "ERROR" gmxpbsa2.out)" != "" ] || [ "$(grep "fatal" gmxpbsa2.out)" != "" ]; then fatal 33 " something wrong on gmxpbsa2!! exiting..."; fi
				if ! [ -r "RUN1_${rootName}/REPORTFILE2" ]; then fatal 33 " something wrong on REPORTFILE2 (RUN1_${rootName}/REPORTFILE2)!! CHECK IT..."; fi
				#cp -r ../RUN1_*1_prot ./RUN1_${rootName}

        mv ./*.temp "${removed_files_FOLDER}" &> /dev/null
				rm -f ./*# ./*~ &>> "$removed_files_FOLDER/rm.out"
				sleep 1
				if [ "$NUMframe" == "all" ]; then
					tail -n +2 RUN1_${rootName}/${rootName}/SUMMARY_FILES/mmpbsa_plot > energy_plot.temp
				else
					tail -n +2 RUN1_${rootName}/${rootName}/SUMMARY_FILES/mmpbsa_plot | tail -n "${NUMframe}" > energy_plot.temp
				fi
				;;
			Jmmpbsa)
			  # NOT WORKING
			  msg "$(date +%H:%M:%S) --running Jmmpbsa.. " | tee -a "$LOGFILENAME"
				cd "$rootName" || fatal 1 "Cannot enter '$rootName' folder"
				${JerkwinPROGRAM} -gsp "GsourcePATH" -ap "$APATH" -trj "${confNAME}_noPBC.xtc" -tpr "${confNAME}" -ndx "index.ndx" -to "$trjconvOPT" -com "complex" -pro "receptor" -lig "ligand" -prefix "OUT"
				cd ..
				;;
			gmxMMPBSA)
			  # ALL UNITS IN KCAL/MOL
			  msg "$(date +%H:%M:%S) --running gmxMMPBSA_cycle${Cycle_Number}.. " | tee -a "$LOGFILENAME"
			  source "${CONDA_activate_path}"/activate "${CONDA_gmxmmpbsa_name}" || fatal 66 "could not activate gmxMMPBSA-1.6.1"
			  cd "$cycle_number_MD_FOLDER"/"$rootName" || fatal 1 "Cannot enter '$rootName' folder"
			  msg -v "searching for ForceField($ForceField) in GMXLIB($GMXLIB)"
			  xIFS="$IFS";IFS=':';read -ra newarr <<< "$GMXLIB";
			  for path in "${newarr[@]}"; do
			    if [[ -d "${path}/${ForceField}.ff" ]]; then
			      cp -r "${path}/${ForceField}.ff" ./
			      [[ $VERBOSE == "True" ]] && msg -v "found ${path}/${ForceField}.ff"
			      break
			    fi
			  done; IFS="$xIFS";
#			  ((NP_4=NP_value/4))
        ((NP_half=NP_value/2))
			  NP_used=$( awk -v np="$NP_half" -v nf="$number_of_frames" 'BEGIN {print (np<nf)?np:nf}')
			  echo -e "NP_value=$NP_value \t number_of_frames=$number_of_frames \t NP_used=$NP_used" > gmx_MMPBSA.out
			  cp "${ABiSS_LIB}/gmx_mmpbsa_in/${mmpbsa_inFILE}" "$cycle_number_MD_FOLDER"/topol*itp \
			      "$cycle_number_MD_FOLDER"/*_protein.top "$cycle_number_MD_FOLDER"/*_starting_protein.pdb ./
			  start_time=$(stopwatch -s)
			  if [[ $VERBOSE == "True" ]]; then
          msg -v "mpirun -np ${NP_used} gmx_MMPBSA MPI -O -i ${mmpbsa_inFILE} -cs ${confNAME}_newGRO.tpr -ci index.ndx"
			    msg -v "-cg 0 1 -ct ${confNAME}_noPBC.xtc -cr ./*_starting_protein.pdb -cp topol_protein.top -eo gmx_MMPBSA_plot.csv"
			    msg -v "-deo FINAL_DECOMP_MMPBSA.csv -nogui &>> gmx_MMPBSA.out || fatal 2 gmx_MMPBSA failed!"
        fi
			  mpirun -np "${NP_used}" gmx_MMPBSA MPI -O -i "${mmpbsa_inFILE}" -cs ${confNAME}_newGRO.tpr -ci index.ndx \
			    -cg 0 1 -ct ${confNAME}_noPBC.xtc -cr ./*_starting_protein.pdb -cp topol_protein.top -eo "gmx_MMPBSA_plot.csv" \
			    -deo "FINAL_DECOMP_MMPBSA.csv" -nogui &>> gmx_MMPBSA.out || {
			      # shellcheck disable=SC2006
			      if [[ "$(grep "Segmentation fault" gmx_MMPBSA.out)" != "" ]]; then
			        msg "some error occurred with gmx_MMPBSA.. waiting 2min and try again"
			        sleep 2m
			        mpirun -np "${NP_used}" gmx_MMPBSA MPI -O -i "${mmpbsa_inFILE}" -cs ${confNAME}_newGRO.tpr -ci index.ndx \
			    -cg 0 1 -ct ${confNAME}_noPBC.xtc -cr ./*_starting_protein.pdb -cp topol_protein.top -eo "gmx_MMPBSA_plot.csv" \
			    -deo "FINAL_DECOMP_MMPBSA.csv" -nogui &>> gmx_MMPBSA.out || fatal 2 "gmx_MMPBSA failed!";
			      else
			        fatal 2 "gmx_MMPBSA failed!";
			      fi
			      }
			  msg "DONE gmxMMPBSA on cycle_${Cycle_Number} $(stopwatch -f "$start_time")"
			  source "${CONDA_activate_path}"/activate
        if [[ "${source_GMX}" != "" ]]; then source "${source_GMX}"; fi
        if [[ $VERBOSE == "True" ]]; then
          $MDRUN_md -h &> mdrun_md.temp
          msg -v ""; head -n 1 mdrun_md.temp; echo ""
        fi

			  msg "\t$(date +%H:%M:%S) Computing results.. " | tee -a "$LOGFILENAME"
			  # This is needed to remove the windows ^M carriage return (CR)
			  tr -d '\r' < gmx_MMPBSA_plot.csv > gmx_MMPBSA_plot.dat
			  Delta_Energy_line=$( grep -n "Delta Energy Terms" gmx_MMPBSA_plot.dat | cut -d: -f1 )
			  # tail -n+"${Delta_Energy_line}" gmx_MMPBSA_plot.dat > gmx_MMPBSA_plot_delta_header.temp
			  # line=$(grep "Frame" gmx_MMPBSA_plot_delta_header.temp)
			  line=$(grep "Frame" gmx_MMPBSA_plot.dat | head -n1 )
			  IFS=',';read -ra newarr <<< "$line";
			  [[ $VERBOSE == "True" ]] && { msg -v "line=${line}"; msg -v "newarr=${newarr[*]}"; }
			  (( i=0 ))
			  for name in ${newarr[*]}; do
			    #PB->Frame #,BOND,ANGLE,DIHED,VDWAALS,EEL,1-4 VDW,1-4 EEL,EPB,ENPOLAR,EDISPER,GGAS,GSOLV,TOTAL
			    #GB->Frame #,BOND,ANGLE,DIHED,VDWAALS,EEL,1-4 VDW,1-4 EEL,EGB,ESURF,GGAS,GSOLV,TOTAL
			    (( i=i+1 ))
			    [[ $VERBOSE == "True" ]] && msg -v "element=${element} i=${i} name=${name}"
          if [[ ${name} == TOTAL ]]; then TOTAL_field="$i"; continue; fi
          if [[ ${name} == VDWAALS ]]; then VDW_field="$i"; continue; fi
          if [[ ${name} == EEL ]]; then EEL_field="$i"; continue; fi
          if [[ ${name} == "1-4 VDW" ]]; then VDW14_field="$i"; continue; fi
          if [[ ${name} == "1-4 EEL" ]]; then EEL14_field="$i"; continue; fi
          if [[ ${name} == EPB ]]; then EPB_field="$i"; continue; fi
          if [[ ${name} == EGB ]]; then EGB_field="$i"; continue; fi
          if [[ ${name} == ENPOLAR ]]; then ENPOLAR_field="$i"; continue; fi
          if [[ ${name} == EDISPER ]]; then EDISPER_field="$i"; continue; fi
          if [[ ${name} == ESURF ]]; then ESURF_field="$i"; continue; fi
			  done; IFS="$xIFS";
			  echo -e "\n\nTOTAL_field=${TOTAL_field}\tVDW_field=${VDW_field}\tEEL_field=${EEL_field}\tVDW14_field=${VDW14_field}\t\
			        \nEEL14_field=${EEL14_field}\tEPB_field=${EPB_field}\nEGB_field=${EGB_field}\tENPOLAR_field=${ENPOLAR_field}\t\
			        EDISPER_field=${EDISPER_field}\tESURF_field=${ESURF_field}" >> gmx_MMPBSA.out
			  tail -n+$((Delta_Energy_line+=2)) gmx_MMPBSA_plot.dat > gmx_MMPBSA_plot_delta.temp
        printf "%-8s \t %-15s \t %-15s \t %-15s \t %-15s \t %-15s \n" '# frame' 'DeltaG(kJ/mol)' 'Coul(kJ/mol)' 'vdW(kJ/mol)' 'PolSol(kJ/mol)' 'NpoSol(kJ/mol)' > energy_plot.temp
        while read -r line; do
#          echo "$line"
          [[ "$line" == "" ]] && continue
       ### Frame #        ###
          printf "%-8s \t" "$(echo "$line" | cut -d"," -f1)" >>  energy_plot.temp

       ### DeltaG(kJ/mol) ###
          printf "%-15s \t" "$(echo "$line" | cut -d"," -f"${TOTAL_field}" )" >>  energy_plot.temp

       ### Coul(kJ/mol) ###
          EEL="$(echo "$line" | cut -d"," -f"${EEL_field}")"; EEL14="$(echo "$line" | cut -d"," -f"${EEL14_field}" )"
          total="$(echo "scale=0; x=$EEL; y=$EEL14; print x+y" | bc -l )"
#          echo "EEL=$EEL   EEL14=$EEL14   total=$total"
          printf "%-15s \t" "${total}" >>  energy_plot.temp

       ### vdW(kJ/mol) ###
          VDW="$(echo "$line" | cut -d"," -f"${VDW_field}")"; VDW14="$(echo "$line" | cut -d"," -f"${VDW14_field}" )"
          total="$(echo "scale=0; x=$VDW; y=$VDW14; print x+y" | bc -l )"
#          echo "VDW=$VDW   VDW14=$VDW14   total=$total"
          printf "%-15s \t" "${total}" >>  energy_plot.temp

       ### PolSol(kJ/mol) ###
          if [[ $EPB_field != "" ]] && [[ $ENPOLAR_field != "" ]]; then
            EPB="$(echo "$line" | cut -d"," -f"${EPB_field}")";
            ENPOLAR="$(echo "$line" | cut -d"," -f"${ENPOLAR_field}" )"
            total="$(echo "scale=0; x=$EPB; y=$ENPOLAR; print x+y" | bc -l )"
          else
            total="$(echo "$line" | cut -d"," -f"${EGB_field}")";
          fi
#          echo "EPB_field=$EPB_field  ENPOLAR_field=$ENPOLAR_field  EPB=$EPB   ENPOLAR=$ENPOLAR   total=$total"
          printf "%-15s \t" "${total}" >>  energy_plot.temp

       ### NpoSol(kJ/mol) ###
          [[ $EDISPER_field != "" ]] && non_pol_solv="$(echo "$line" | cut -d"," -f"${EDISPER_field}" )"
          [[ $ESURF_field != "" ]] && non_pol_solv="$(echo "$line" | cut -d"," -f"${ESURF_field}" )"
#          echo "EDISPER_field=$EDISPER_field   ESURF_field=$ESURF_field   non_pol_solv=$non_pol_solv"
          printf "%-15s \n" "${non_pol_solv}" >>  energy_plot.temp
        done < gmx_MMPBSA_plot_delta.temp

				sleep 1
				if [ "$NUMframe" == "all" ]; then
					tail -n +2 ./energy_plot.temp > ../energy_plot.temp
				else
					tail -n +"${NUMframe}" ./energy_plot.temp > ../energy_plot.temp
				fi

				msg "\t$(date +%H:%M:%S) Cleaning up.. " | tee -a "$LOGFILENAME"
				# -cp topol.top -> I don't need to pass the topology if I am using AMBER ff
			  mv ./_GMXMMPBSA* "${removed_files_FOLDER}"/
        mv ./*.temp "${removed_files_FOLDER}"/
				rm -fr ./*# ./*~ ./*.ff &> "${removed_files_FOLDER}"/rm.out
        cd "$cycle_number_MD_FOLDER" || fatal 1 "Cannot enter '$cycle_number_MD_FOLDER' folder"
        ;;
			*)	fatal 1 "EnergyCalculation ERROR: $EnergyCalculation is not a valid OPTION!\n";;
		esac
		DataAnalysis -f "energy_plot.temp" -o "${results_FOLDER}/cycle${Cycle_Number}_results.dat"
		
		#cycle${Cycle_Number}_results.dat:
		#frame   dG(kJ/mol)      Coul(kJ/mol)      vdW(kJ/mol)    PolSol(kJ/mol)    NpoSol(kJ/mol)     SF=C/10-PS/10+NpS*10     SF2=3*C+PS      C_AVG=norm(SUM Gi*e^BGi)      Median DeltaG 
		#0        1619.990        -543.800          -372.700         2590.280          -53.790                -701.308            958.880 
		##AVG      1640.779        -488.387          -347.700         2528.373          -51.506                -816.731           1063.213              1522.750                1629.555
		##STD        62.466         130.032            21.534          113.449            2.098                  45.332            503.545
		
		#====================================================================================================================================================
		# msg "                            --FINALYZING, MOVING FILES ON repository_FOLDER folder AND INITIALIZING NAMES FOR THE NEXT RUN-- 			"
		#====================================================================================================================================================

		# Finalize the results
		printf "%-10i \t" ${Cycle_Number} >> "${results_FOLDER}/MoleculesResults.dat"
		grep "#AVG" "${results_FOLDER}/cycle${Cycle_Number}_results.dat" | cut -f 2- >> "${results_FOLDER}/MoleculesResults.dat"
		
		#results_FOLDER/MoleculesResults.dat:
		#RUNnumb   dG(kJ/mol)      Coul(kJ/mol)      vdW(kJ/mol)    PolSol(kJ/mol)    NpoSol(kJ/mol)     SF=C/10-PS/10+NpS*10     SF2=3*C+PS      C_AVG=norm(SUM Gi*e^BGi)      Median DeltaG 
		#0         1640.779        -488.387          -347.700         2528.373          -51.506                -816.731           1063.213              1522.750                1629.555
		
		# DeltaEnergy(DG)->2  ScoreFunct->7  ScoreFunct2->8  CanonicalG->9  MedianDG->10  DeltaG_2s->11   dG_PotEn->12
		msg "$(date +%H:%M:%S) **cycle${Cycle_Number} -> " | tee -a "$LOGFILENAME"
		for ResultCOLUMN in 2 7 8 9 10 11 12; do 
			ResultNAME="$( head -n 1 ${results_FOLDER}/MoleculesResults.dat | cut -f $ResultCOLUMN )"
			ResultVALUE="$( tail -n 1 ${results_FOLDER}/MoleculesResults.dat | cut -f $ResultCOLUMN )"
			ResultSTD="$( grep "#STD" ${results_FOLDER}/cycle${Cycle_Number}_results.dat  | cut -f "$ResultCOLUMN" )"
#			ResultSTD=$( echo "$( grep "#STD" ${results_FOLDER}/cycle${Cycle_Number}_results.dat  | cut -f "$ResultCOLUMN" )" )
      printf "\n\t\t\t%15s (%2s) %10s +- %5s" "$ResultNAME" "$ResultCOLUMN" "$ResultVALUE" "$ResultSTD" | tee -a "$LOGFILENAME"
		done
		msg -t "\t\t\t\t\t$(date +%H:%M:%S) **" | tee -a "$LOGFILENAME"
		#msg "**cycle${Cycle_Number} -> DeltaG ${DeltaEnergy}kJ/mol | CanonicalG ${CanonicaG} | ScoreFunction ${ScoreFunct} **" | tee -a $LOGFILENAME
	  msg "\t$(date +%H:%M:%S) Cleaning up.." | tee -a "$LOGFILENAME"
    rm -fr ./*# ./*~ ./*temp* &> "${removed_files_FOLDER}"/rm.out

		msg "$(date +%H:%M:%S) Moving files of interest.. " | tee -a "$LOGFILENAME"
		# Copy all the files of interest on repository_FOLDER folder
		mv RUN1_cycle${Cycle_Number}_prot ${rootName} ./*.out "${repository_FOLDER}/" 2> /dev/null    ;# All possible BE results
		cp system_Compl_MDstart.gro "${repository_FOLDER}/system_cycle${Cycle_Number}_MDstart.gro"
		# mv "${trjNAME}".xtc "${repository_FOLDER}/traj_cycle${Cycle_Number}_MD.xtc"
		cp -r "$cycle_number_MD_FOLDER" "${repository_FOLDER}/" 2> /dev/null

    #### If you decomposed the energy and you want to use it as weight to select the residue to mutate
    if [[ ${use_decomp_as_weights} == "True" ]] && [[ -r "${repository_FOLDER}/${rootName}/FINAL_DECOMP_MMPBSA.dat" ]]; then
      resid_be_decomp_files+=("${repository_FOLDER}/${rootName}/FINAL_DECOMP_MMPBSA.dat")
      msg "\t$(date +%H:%M:%S) Using resid_be_decomp.. " | tee -a "$LOGFILENAME"
    fi

		msg "\t$(date +%H:%M:%S) Removing the folder up.." | tee -a "$LOGFILENAME"
		# Remove ALL the other files
#		mkdir -p removed_files_FOLDER        # This is done in BuildFoldersAndPrintHeadingFiles
#		rm ./* "${removed_files_FOLDER}"/ 2> "${removed_files_FOLDER}"/cp_err.out
    for f in *; do if [ -f "$f" ]; then mv "$f" "${removed_files_FOLDER}"/; fi; done
		rm -f ./* &>> "${removed_files_FOLDER}"/rm.out
		cd ../; rm -fr "$cycle_number_MD_FOLDER"
		# rm -fr backup* &>> "${removed_files_FOLDER}"/rm.out
		
		# Different runs on the same configuration
		((Cycle_Number+=1))
		confNAME="cycle${Cycle_Number}"
		rootName="cycle${Cycle_Number}_BE"
	  cycle_number_MD_FOLDER="$current_conf_PATH/cycle${Cycle_Number}_MD"

	done

  cd "$current_conf_PATH" || fatal 1 "Cannot enter '$cycle_number_MD_FOLDER' folder"
  # Save the last minima-configuration found in the RUN folder to be used as starting configuration for the next mutation
  # system_cycle${Cycle_Number}_MD (previous system_Compl_MDstart.gro) -> starting configuration for MD (after SAMD+NVP+NPT)
  ((Cycle_Number-=1))
  cycle_number_MD_FOLDER="${repository_FOLDER}/cycle${Cycle_Number}_MD"
  cp "${cycle_number_MD_FOLDER}/LastFrame_cycle${Cycle_Number}.gro" "${repository_FOLDER}" || fatal 32 "Cannot copy the LastFrameMD!"
  msg "$(date +%H:%M:%S) --Making the starting PDB for the next Mutation from LastFrame_cycle${Cycle_Number}.gro.. " | tee -a "$LOGFILENAME"
  # the pdb file is used to keep all the chains informations. the output file name is set by -o or equal to the gro file
  #GRO_to_PDB -gp "${repository_FOLDER}" -gn "system_cycle${Cycle_Number}_MD" -pp "${repository_FOLDER}" -pn "${complex_FILE}"
  #addTERpdb "${repository_FOLDER}/system_cycle${Cycle_Number}_MD.pdb"
	#all_to_HIS -f "${repository_FOLDER}/system_cycle${Cycle_Number}_MD.pdb" \
	#           -o "$RUN_FOLDER"/Mutant"${SEQUENCE}"_cycle"${Cycle_Number}"_MD.pdb  || fatal 33 "GRO_to_PDB probably failed!"
	GRO_to_PDB -gp "${repository_FOLDER}" -gn "LastFrame_cycle${Cycle_Number}" -pp "${repository_FOLDER}" -pn "${complex_FILE}"
  addTERpdb "${repository_FOLDER}/LastFrame_cycle${Cycle_Number}.pdb"
	all_to_HIS -f "${repository_FOLDER}/LastFrame_cycle${Cycle_Number}.pdb" \
	           -o "$RUN_FOLDER"/Mutant"${SEQUENCE}"_cycle"${Cycle_Number}"_LastFrameMD.pdb  || fatal 33 "GRO_to_PDB probably failed!"
  complex_FILE=Mutant"${SEQUENCE}"_cycle"${Cycle_Number}"_LastFrameMD

	#====================================================================================================================================================
	# msg "                            --COMPUTING the AVERAGE among all the RUNS-- 			"
	#====================================================================================================================================================
	if [[ $average_all_frames == True ]]; then
    msg "$(date +%H:%M:%S) --collecting all the results and make the averages(average_all_frames=$average_all_frames).. " | tee -a "$LOGFILENAME"
    flag=$( ls ${results_FOLDER}/cycle?_results.dat ${results_FOLDER}/cycle??_results.dat ${results_FOLDER}/cycle???_results.dat 2> /dev/null )
    allResultsFromRUN -rl "$flag" -o "AllData.out"
    # AllData.out:
    #configNum      #frame               dG(kJ/mol)            Coul(kJ/mol)             vdW(kJ/mol)          PolSol(kJ/mol)          NpoSol(kJ/mol)         SF=C/10-PS/10+NpS*10         SF2=3*C+PS         C_AVG=norm(SUM Gi*e^BGi)          Median DeltaG
    #0               0                         2.718               -1153.020                -777.270                2032.203                 -99.195               -1160.472               -1426.857
    #0               1                        78.944               -1282.980                -746.150                2208.483                -100.409               -1203.236               -1640.457
    #0               2                      -147.515               -1304.750                -892.400                2152.740                -103.106               -1226.809               -1761.510
    #1               0                       -20.366               -1345.940                -785.360                2213.256                -102.322               -1229.140               -1824.564
    #1               1                     -2371.150               -2918.880               -1625.820                2280.007                -106.459               -1434.479               -6476.633
    #1               2                     -1119.780               -2155.900               -1120.490                2262.407                -105.798               -1349.811               -4205.293

    cut -f 2- AllData.out > DataAnalysis.temp
    #	grep -E -h "(complex)|(ligand)|(receptor)" repository_FOLDER/RUN1_cycle*_prot/cycle*_prot/SUMMARY_FILES/PotEn.PotEn > PotEn.temp

    #	DataAnalysis -f "DataAnalysis.temp" -o "AllData.temp" -p "PotEn.temp"
    DataAnalysis -f "DataAnalysis.temp" -o "AllData.temp"
    sed -i -e 's/#AVG/#AVG          	/g' AllData.temp;  sed -i -e 's/#STD/#STD         	/g' AllData.temp
    grep "^#AVG" AllData.temp >> AllData.out; grep "^#STD" AllData.temp >> AllData.out
    mv AllData.temp DataAnalysis.temp "${removed_files_FOLDER}"
    #AvgANDStd2 -if "AllData.out"		; # compute the average and standard deviation for every column starting from the 2nd
	else
	  msg "$(date +%H:%M:%S) --Making the average of the cycles results(average_all_frames=$average_all_frames).. " | tee -a "$LOGFILENAME"

#    cp "${results_FOLDER}"/MoleculesResults.dat ./"AllData.out"
#   copy the MoleculesResults.dat file and add one column to be similar to the $average_all_frames=True setup (chabuduo solution)
    _flag_header=True
    [ -r "AllData.out" ] && rm -f ./"AllData.out"
    while read -r line; do
      if [[ $_flag_header == True ]]; then
        printf "#%-10s \t$line\n" "configNum" >> ./"AllData.out"
        _flag_header=False
      else
        printf "%-10s \t$line\n" "avg" >> ./"AllData.out"
      fi
    done < "${results_FOLDER}"/MoleculesResults.dat
    cut -f 2- AllData.out > DataAnalysis.temp
    DataAnalysis -f ./"DataAnalysis.temp" -o "AllData.temp"
    sed -i -e 's/#AVG/#AVG          	/g' AllData.temp;  sed -i -e 's/#STD/#STD         	/g' AllData.temp
    grep "^#AVG" AllData.temp >> AllData.out; grep "^#STD" AllData.temp >> AllData.out
    mv AllData.temp DataAnalysis.temp "${removed_files_FOLDER}"
	fi

	for EnergySelected in ${EnergyFunction}; do
		#EnergyFunction=3 12
		FunctionSelected=$( grep "^#configNum" AllData.out | cut -f "${EnergySelected}" )
		AVG=$( echo $( grep "^#AVG" AllData.out | cut -f "${EnergySelected}" ))
		STD=$( echo $( grep "^#STD" AllData.out | cut -f "${EnergySelected}" ))
		msg "\tRESULT(${FunctionSelected}): ${AVG} -+ ${STD}kJ/mol" | tee -a "$LOGFILENAME"
	done
	#The last one will be used in the Metropolitas algorithm
	
	
	# SKIP THE METROPOLIS IF I WAS COMPUTING THE ENERGY OF THE WT. (MUTATE FOR SURE)
	if [ "${SEQUENCE}" -eq "0" ]; then
		Make_new_mutation="True"
		Stored_AVG=${AVG}
		Stored_STD=${STD}
		Stored_system_FILE="${complex_FILE}"

	  msg "FINISHED with Config$SEQUENCE "  | tee -a "$LOGFILENAME"
		((SEQUENCE+=1))
		cd "${RUN_FOLDER}" || fatal 1 "Cannot enter '${RUN_FOLDER}' folder"
		if [[ "$FAST" != "True" ]]; then
		  rm -fr "${removed_files_FOLDER}"
		  # rm -fr "${current_conf_PATH}/"cycle*_MD
		fi
		echo "${AVG} -+ ${STD} kJ/mol" >> "$CONFOUT_FILENAME"
		continue
	fi
	
	msg "$(date +%H:%M:%S) --Metropolis algorithm.. (Correction=$metropolis_correction)" | tee -a "$LOGFILENAME"
	#==============================================================================================================================
	# echo " 				--Metropolis-- 			"
	#==============================================================================================================================
	Metropolis_flag=
	if [ "$AcceptProb" == "" ]; then
		RandNum="$(dd if=/dev/urandom count=1 2>/dev/null | od -t u | head -1 | awk '{ r=($2%1000000)/1000000; print r }' )"		; # good pseudo Random number between 0 and 1
	else
		RandNum="$AcceptProb"
	fi

  if [[ $metropolis_correction == True ]]; then
#    Metropolis_Prob=$( awk -v Ef="${AVG}" -v sf="${STD}" -v Ei="${Stored_AVG}" -v si="${Stored_STD}" -v Tm="${Eff_Metropolis_Temp}" \
#       'BEGIN { Mp=exp(-(Ef+sf/2-(Ei-si/2))/Tm); if (Mp<1) printf "%5.4f", Mp; else print "1"}')
    Metropolis_Prob=$( awk -v Ef="${AVG}" -v sf="${STD}" -v Ei="${Stored_AVG}" -v si="${Stored_STD}" -v Tm="${Eff_Metropolis_Temp}" \
        'BEGIN { Mp=exp(-(Ef+sf/2-(Ei))/Tm); if (Mp<1) printf "%5.4f", Mp; else print "1"}')
		msg "Random Number:${RandNum} Metropolis prob:${Metropolis_Prob} " | tee -a "$LOGFILENAME"
		msg "[ =exp(-(${AVG}+${STD}/2-(${Stored_AVG}))/${Eff_Metropolis_Temp}) ]" | tee -a "$LOGFILENAME"
  else
	  Metropolis_Prob=$( awk -v Ei="${Stored_AVG}" -v Ef="${AVG}" -v Tm="${Eff_Metropolis_Temp}" \
	  'BEGIN { Mp=exp(-(Ef-Ei)/Tm); if (Mp<1) printf "%5.4f", Mp; else print "1"}')
		msg "Random Number:${RandNum} Metropolis prob:${Metropolis_Prob} " | tee -a "$LOGFILENAME"
		msg "[ =exp(-(${AVG}-${Stored_AVG})/${Eff_Metropolis_Temp}) ]" | tee -a "$LOGFILENAME"
	fi
	Metropolis_flag=$( awk -v Mp="${Metropolis_Prob}" -v Rnum="${RandNum}" 'BEGIN { if (Rnum<Mp) print "1"; else print "0"}')		; # check if I accept the new configuration (1=true) or not (0=false)

	if [ "$Metropolis_flag" -eq "1" ]; then
		msg  "\tNew configuration **ACCEPTED** " | tee -a "$LOGFILENAME"
		echo "$AVG -+ ${STD} kJ/mol T_met= $Eff_Metropolis_Temp (**ACCEPTED**)" >> "$CONFOUT_FILENAME"

		# I keep the name of the new accepted mutant as 'old configuration' for the next test 
		Stored_AVG=${AVG}
		Stored_STD=${STD}
		Stored_system_FILE="${complex_FILE}"

    Consecutive_DISCARD_Count=0
    Eff_Metropolis_Temp=${Metropolis_Temp}
  # the last configuration will be used for the mutation
	else
		msg " \tNew configuration **DECLINED** "  | tee -a "$LOGFILENAME"
		echo "$AVG -+ ${STD} kJ/mol T_met= $Eff_Metropolis_Temp (**DECLINED**)" >> "$CONFOUT_FILENAME"
		complex_FILE=${Stored_system_FILE}
	  ((Consecutive_DISCARD_Count++))
	  # I must get rid of the float because bash cannot deal with float numbers (bc and awk do not have problem with floats)
	  Eff_Metropolis_Temp_x10=$(echo "et=$Eff_Metropolis_Temp; print et*10" | bc -l)
	  Eff_Metropolis_Temp_x10=${Eff_Metropolis_Temp_x10%.*}
	  Metropolis_Temp_cap_x10=$(echo "tc=$Metropolis_Temp_cap; print tc*10" | bc -l)
	  Metropolis_Temp_cap_x10=${Eff_Metropolis_Temp_x10%.*}
	  if [[ $Consecutive_DISCARD_Count -gt 5 ]] && [[ $Eff_Metropolis_Temp_x10 -lt $Metropolis_Temp_cap_x10 ]]; then
	    # ((Eff_Metropolis_Temp=Metropolis_Temp+1*(Consecutive_DISCARD_Count-5)))
	    Eff_Metropolis_Temp=$(echo "t=$Metropolis_Temp; c=$Consecutive_DISCARD_Count; print t+0.5*(c-5)" | bc -l)
	  fi
	  # Check that the resulting Eff_Metropolis_Temp isn't bigger than the max set (I had some errors before after restart)
	  Eff_Metropolis_Temp_x10=$(echo "et=$Eff_Metropolis_Temp; print et*10" | bc -l)
	  Eff_Metropolis_Temp_x10=${Eff_Metropolis_Temp_x10%.*}
	  if [[ $Eff_Metropolis_Temp_x10 -gt $Metropolis_Temp_cap_x10 ]]; then
	    msg  "New Eff_Metropolis_Temp bigger than the max value ($Metropolis_Temp_cap). Reset." | tee -a "$LOGFILENAME"
	    Eff_Metropolis_Temp=$Metropolis_Temp_cap
	  fi
		# the previous configuration (stored files) will be used for the mutation!!
	fi

	Make_new_mutation="True"
	msg "FINISHED with Mutant$SEQUENCE "  | tee -a "$LOGFILENAME"
	((SEQUENCE+=1))
	cd "${RUN_FOLDER}" || { fatal 1 "Cannot enter \"${RUN_FOLDER}\" folder"; }
	if [[ "$FAST" != "True" ]]; then
	  rm -fr "$removed_files_FOLDER"
	  # rm -f "${current_conf_PATH}/"cycle*_MD
	fi

done

msg "ALL DONE!"
echo -e "\n\n\n\t\t\t\t*** All work and no play makes Jack a dull boy. ***\n"
exit



