#!/bin/bash

echo -e "\t > MDPs_setup.sh and custom_mdpFILE"
# GLOBAL VARIABLE
# shellcheck disable=SC2154
#[[ -d ${ABiSS_LIB} ]] || { echo "functions_list ERROR: I cannot find the folder ABiSS_LIB($ABiSS_LIB)"; return 1; }
#source "${ABiSS_LIB}"/FUNCTIONs/Custom_mdpFILE.sh

function MDPs_setup {

  ####### FAST option ===================
  if [ "$FAST" == "True" ]; then
    if [[ $VERBOSE == "True" ]]; then
      msg -v "(FAST=$FAST)Setting the variables to FAST values.."
      msg -v "editconf_opt=$editconf_opt \n\t\t startingFrameGMXPBSA=$startingFrameGMXPBSA \n\t\t RunningNum_PerSystem=$RunningNum_PerSystem \
       MaxMutant=$MaxMutant \n\t\t linearizedPB=$linearizedPB \n\t\t mmpbsa_inFILE=$mmpbsa_inFILE \n\t\t precF=$precF \n\t\t pdie=$pdie \
       KEY_annealing=$KEY_annealing \n\t\t KEY_SA_npoints=$KEY_SA_npoints \n\t\t KEY_SA_temp=$KEY_SA_temp \n\t\t KEY_SA_time=$KEY_SA_time \
       KEY_nsteps_minim=$KEY_nsteps_minim \n\t\t KEY_nsteps_SAMD=$KEY_nsteps_SAMD \n\t\t KEY_nsteps_NVT=$KEY_nsteps_NVT \
       KEY_nsteps_NPT=$KEY_nsteps_NPT \n\t\t KEY_nsteps_MD=$KEY_nsteps_MD \n\t\t KEY_nstouts_SAMD=$KEY_nstouts_SAMD \n\t\t KEY_nstouts_NVT=$KEY_nstouts_NVT \
       KEY_nstouts_NPT=$KEY_nstouts_NPT \n\t\t KEY_nstouts_MD=$KEY_nstouts_MD \n"
    fi
    #editconf_opt="-d 1.0 -bt triclinic -c";
    startingFrameGMXPBSA="0"	# starting ps
    if [[ $RunningNum_PerSystem -ge 5 ]]; then RunningNum_PerSystem=2; fi
    if [[ $MaxMutant == "" ]]; then MaxMutant=2; fi
    linearizedPB='-l';
    [[ $mmpbsa_inFILE == "" ]] && mmpbsa_inFILE="mmpbsa_GB_amber99SB_ILDN.in"           # mmpbsa_noLinearPB_charmm.in
    precF="1"
    pdie="2"
    KEY_annealing="single"; KEY_SA_npoints="4";
    KEY_SA_temp="280 290 300 310"
    KEY_SA_time="0 10 15 20";
    KEY_nsteps_minim="500"					# nsteps for minim
    ((KEY_nsteps_SAMD=20*1000))		# 20ps (time step 1fs) nsteps for SAMD
    KEY_nsteps_NVT="5000"					# 10ps nsteps for NVT
    KEY_nsteps_NPT="7000"					# 15ps nsteps for NPT
    KEY_nsteps_MD="2000"					# 4ps nsteps for MD production
    ((KEY_nstouts_SAMD=KEY_nsteps_SAMD/10))			# nstouts for SAMD
    ((KEY_nstouts_NVT=KEY_nsteps_NVT/10))			# nstouts for NVT
    ((KEY_nstouts_NPT=KEY_nsteps_NPT/10))			# nstouts for NPT
    KEY_nstouts_MD="500"					# 1ps nstouts for MD production -> 4 frames
  fi

  ######## POSRES ===================
  if [[ "${POSRES}" == "" ]] || [[ "${POSRES}" == "no" ]]; then
    # the funciton to handle the custom mdp file will delete all the lines containing the keyword "KEY_"
    KEY_define_MD="KEY_"
    KEY_commmode="Linear"
    msg "Setting KEY_define_MD to \"$KEY_define_MD\" (No posres during MD)"
  else
    msg "Setting KEY_define_MD to \"$KEY_define_MD\" (Default value)"
    KEY_pcoupl="C-rescale"			  # Berendsen->not a good ensamble | Parrinello-Rahman may have artifact with PosRes
    KEY_commmode="none"
    # C-rescale is better but implemented only from 2021
    if [[ $VERBOSE == "True" ]]; then
        msg "(POSRES=$POSRES)Setting the variables to POSRES values.."
        msg "KEY_define_MD=$KEY_define_MD \t KEY_pcoupl=$KEY_pcoupl"
        msg "KEY_define_SAMD=$KEY_define_SAMD"
        msg "KEY_commmode=$KEY_commmode"
    fi
  fi


  ######## MDPs ===================
  #  mkdir "${SETUP_PROGRAM_FOLDER}"
  # minim.mdp  SAMD.mdp  NVT.mdp  NPT.mdp
  cd "${SETUP_PROGRAM_FOLDER}" || fatal 1 "Cannot access '${SETUP_PROGRAM_FOLDER}' folder"

  # MINIM
  $PYTHON "${FUNCTIONs_FOLDER}/Custom_mdpFILE.py" "${MDPs_FOLDER}/minim_custom.mdp" -KEY_nsteps "${KEY_nsteps_minim}" || exit
  # NVT
  $PYTHON "${FUNCTIONs_FOLDER}/Custom_mdpFILE.py" "${MDPs_FOLDER}/NVT_custom.mdp" \
    -KEY_define "-DPOSRES" -KEY_nsteps "${KEY_nsteps_NVT}" \
    -KEY_nstouts "${KEY_nstouts_NVT}" -KEY_compressed "${KEY_compressed}" -KEY_commmode "${KEY_commmode}" || exit
  # NPT
  $PYTHON "${FUNCTIONs_FOLDER}/Custom_mdpFILE.py" "${MDPs_FOLDER}/NPT_custom.mdp" \
    -KEY_define "-DPOSRES" -KEY_nsteps "${KEY_nsteps_NPT}" \
    -KEY_nstouts "${KEY_nstouts_NPT}" -KEY_pcoupl "Berendsen"  \
    -KEY_compressed "${KEY_compressed}" -KEY_commmode "${KEY_commmode}" || exit
  # SAMD
  $PYTHON "${FUNCTIONs_FOLDER}/Custom_mdpFILE.py" "${MDPs_FOLDER}/SAMD_custom.mdp" -KEY_define "${KEY_define_SAMD}" \
    -KEY_nsteps "${KEY_nsteps_SAMD}" -KEY_nstouts "${KEY_nstouts_SAMD}" -KEY_annealing "${KEY_annealing} ${KEY_annealing}" \
    -KEY_SA_npoints "${KEY_SA_npoints} ${KEY_SA_npoints}" -KEY_SA_time "${KEY_SA_time} ${KEY_SA_time}" \
    -KEY_SA_temp "${KEY_SA_temp} ${KEY_SA_temp}" -KEY_compressed "${KEY_compressed}" \
    -KEY_pcoupl "Berendsen"  -KEY_commmode "${KEY_commmode}" || exit
  # PRODUCTION
  $PYTHON "${FUNCTIONs_FOLDER}/Custom_mdpFILE.py" "${MDPs_FOLDER}/EngComp_ff14sb_custom.mdp" \
    -KEY_define "${KEY_define_MD}" -KEY_nsteps "${KEY_nsteps_MD}" \
    -KEY_nstouts "${KEY_nstouts_MD}" -KEY_pcoupl "${KEY_pcoupl}" \
    -KEY_compressed "${KEY_compressed}"  -KEY_commmode "${KEY_commmode}" || exit
  # same as EngComp_ff14sb_custom.mdp but without POSRES and no compressed trj (the keyword change with gromacs version)
  # PRODUCTION -> PROTEIN
  $PYTHON "${FUNCTIONs_FOLDER}/Custom_mdpFILE.py" "${MDPs_FOLDER}/Protein_EngComp_ff14sb_custom.mdp" \
    -KEY_define "${KEY_define_MD}" -KEY_nsteps "${KEY_nsteps_MD}" \
    -KEY_nstouts "${KEY_nstouts_MD}" -KEY_pcoupl "${KEY_pcoupl}" \
    -KEY_compressed "${KEY_compressed}"  -KEY_commmode "${KEY_commmode}" || exit

  export minim_NAME="${SETUP_PROGRAM_FOLDER}/minim_custom.mdp"
  export SAMD_NAME="${SETUP_PROGRAM_FOLDER}/SAMD_custom.mdp"
  export NVT_NAME="${SETUP_PROGRAM_FOLDER}/NVT_custom.mdp"
  export NPT_NAME="${SETUP_PROGRAM_FOLDER}/NPT_custom.mdp"
  export MD_EngComp_ff14sb_NAME="${SETUP_PROGRAM_FOLDER}/EngComp_ff14sb_custom.mdp"
  export Protein_MD_EngComp_ff14sb_NAME="${SETUP_PROGRAM_FOLDER}/Protein_EngComp_ff14sb_custom.mdp"
  cd "${RUN_FOLDER}" || fatal 1 "Cannot access '${RUN_FOLDER}' folder"


  ######## gmx_MMPBSA input ===================




}

