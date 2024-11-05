#!/bin/bash

# e.g.
# comp="sh"; run="13"; mut="1"; rev="_R"
# cp ../../mutations_* ./mutations_${comp}R${run}_M${mut}${rev}.txt
# cp ../Forward/mutations_* ./mutations_${comp}R${run}_M${mut}${rev}.txt
# gedit ./mutations_${comp}R${run}_M${mut}${rev}.txt
# bash FEP_setup.sh HLA_BiAB_beforeMD HLA_BiAB_${comp}R${run}_M${mut}_hybrid_wt_complex${rev} BiAB_${comp}R${run}_M${mut}_hybrid_wt_complex${rev}

# e.g.
# bash FEP_setup.sh -I ../hz_cluster/RUN14/RUN1/conf_RUN1.out -n HLA_BiAB -c hz -r 14 -m 3 -rc "A P"

function make_posres_Cx() {
  echo " > Generating POSRE for the TM-helices.. "
  head -n4 ${BASE_NAME}_ff_box.pdb > ${BASE_NAME}_ch${mut_ch}.pdb;
  grep '^ATOM.*[A-Z] '$mut_ch' ' ${BASE_NAME}_ff_box.pdb >> ${BASE_NAME}_ch${mut_ch}.pdb;
  tail -n2 ${BASE_NAME}_ff_box.pdb >> ${BASE_NAME}_ch${mut_ch}.pdb
  # r 36 38 40 74 76 78 151 153 155 191 193 195\n10 & 2\nname 11 posres-H
  echo -e "r 36 38 40 74 76 78 151 153 155 191 193 195\n10 & 2\nname 11 posres-H\n\nq\n" | gmx make_ndx -f ${BASE_NAME}_ch${mut_ch}.pdb -o index_restr_hybrid.ndx &> make_ndx_restr_hybrid.out || { echo "Error at make_ndx restr_hybrid.."; exit; }
  #
  echo -e "11" | gmx genrestr -f ${BASE_NAME}_ch${mut_ch}.pdb -n index_restr_hybrid.ndx -fc 500 500 500 -o posre_Cx32hybrid_36to78_151to195.itp &> genrestr_hybrid.out || { echo "Error at genrestr_hybrid.."; exit; }
  # 11
  # add posres to every Cx32hybrid chain (A B C D)
  for chain in A B C D E F; do
      if [[ "$chain" == "$mut_ch" ]]; then
        printf "\n; POSRES for hybrid chain ${mut_ch}" >> pmx_topol_Protein_chain_${mut_ch}.itp
        echo -e '\n#ifdef POSRES_cx32\n#include "posre_Cx32hybrid_36to78_151to195.itp"\n#endif\n' >> pmx_topol_Protein_chain_${mut_ch}.itp
      fi
  done

  head -n4 ${BASE_NAME}_ff_box.pdb > ${BASE_NAME}_chF.pdb; grep '^ATOM.*[A-Z] F ' ${BASE_NAME}_ff_box.pdb >> ${BASE_NAME}_chF.pdb; tail -n2 ${BASE_NAME}_ff_box.pdb >> ${BASE_NAME}_chF.pdb
  # r 36 38 40 74 76 78 151 153 155 191 193 195\n10 & 2\nname 11 posres-H
  echo -e "r 36 38 40 74 76 78 151 153 155 191 193 195\n10 & 2\nname 11 posres-H\n\nq\n" | gmx make_ndx -f ${BASE_NAME}_chF.pdb -o index_restr_${STARTING_structure_id}.ndx &> make_ndx_restr_${STARTING_structure_id}.out || { echo "Error at make_ndx restr_${STARTING_structure_id}.."; exit; }
  #
  echo -e "11" | gmx genrestr -f ${BASE_NAME}_chF.pdb -n index_restr_${STARTING_structure_id}.ndx -fc 500 500 500 -o posre_Cx32${STARTING_structure_id}_36to78_151to195.itp &> genrestr_${STARTING_structure_id}.out || { echo "Error at genrestr_${STARTING_structure_id}.."; exit; }
  # add posres to every Cx32D178Y chain (E F)
  for chain in A B C D E F; do
      if [[ "$chain" == "$mut_ch" ]]; then continue; fi
        printf "\n; POSRES for normal chain ${chain}" >> pmx_topol_Protein_chain_${chain}.itp
        echo -e '\n#ifdef POSRES_cx32\n#include "posre_Cx32'${STARTING_structure_id}'_36to78_151to195.itp"\n#endif\n' >> pmx_topol_Protein_chain_${chain}.itp
  done
}

# HZ Zonta - gro2022
# source /home/zonta/anaconda3/bin/activate pmx
# source /opt/gromacs-2022.6/bin/GMXRC.bash
# export GMXLIB=/home/zonta/Downloads/pmx/src/pmx/data/mutff/
# export PATH=$PATH:/home/zonta/Downloads/pmx/src/pmx/scripts/
# FEP_FOLDER="/media/zonta/MyPassport2/ZJU_work/BiSpecificAB/Maturation/FEP"
#ABiSS_folder=

# HZ Desktop - gro2021
source /home/iqb/anaconda3/bin/activate pmx
source /usr/local/gromacs-2021.5/bin/GMXRC
export GMXLIB=/home/iqb/Documents/ZJU_work/PROGRAMMING/pmx/src/pmx/data/mutff/
export PATH=$PATH:/home/iqb/Documents/ZJU_work/PROGRAMMING/pmx/src/pmx/scripts/
FEP_FOLDER="/media/iqb/MyPassport2/ZJU_work/BiSpecificAB/Maturation/FEP"
ABiSS_folder="/home/iqb/Documents/ZJU_work/PROGRAMMING/InSilicoMaturation/ABiSS_custom_v6"

COMPUTER="hz"
RUN="1"
MUTATION="1"
STARTING_FOLDER="$(pwd)"
INPUT_BASE_NAME="HLA_BiAB"
CHAINS_TO_REMOVE="A P"
while [ $# -gt 0 ]
do
  case "$1" in
  # e.g. RUN14/RUN1/conf_RUN1.out
  -I)   shift; INPUT_CONF_RUN="$1";;
  # e.g. HLA_BiAB
  -n)   shift; INPUT_BASE_NAME="$1";;
  # e.g. sh / hz
  -c)   shift; COMPUTER="$1";;
  # e.g. 1 (for RUN1)
  -r)   shift; RUN="$1";;
  # e.g. 1 (for M1)
  -m)   shift; MUTATION="$1";;
  # e.g. "A P" (to remove HLA and Peptide on the unbound simulation)
  -rc)   shift; CHAINS_TO_REMOVE="$1";;
  *)		echo "UserInput ERROR: $1 is not a valid OPTION!\n$*"; exit 1;;
  esac
  shift
done
# HLA_BiAB_${comp}R${run}_M${mut}_hybrid_wt_complex${rev}
# BiAB_${comp}R${run}_M${mut}_hybrid_wt_complex${rev}
FORWARD_NAME_bound="${INPUT_BASE_NAME}_wt_hybrid_${COMPUTER}R${RUN}_M${MUTATION}_complex"
FORWARD_NAME_unbound="${INPUT_BASE_NAME}_wt_hybrid_${COMPUTER}R${RUN}_M${MUTATION}"
REVERSE_NAME_bound="${INPUT_BASE_NAME}_${COMPUTER}R${RUN}_M${MUTATION}_hybrid_wt_complex"
REVERSE_NAME_unbound="${INPUT_BASE_NAME}_${COMPUTER}R${RUN}_M${MUTATION}_hybrid_wt"

python ${ABiSS_folder}/setup_FEP.py -i "${INPUT_CONF_RUN}" -m "${MUTATION}" -d "${COMPUTER}RUN${RUN}_M${MUTATION}" \
      || { echo "Error at ${ABiSS_folder}/setup_FEP.py.."; exit; }
cd "${COMPUTER}RUN${RUN}_M${MUTATION}" || { echo "Cannot enter ${COMPUTER}RUN${RUN}_M${MUTATION}"; exit 2; }
RUN_FOLDER="$(pwd)"

for direction in Forward Reverse; do
  echo -e "\ndirection -> ${direction}"
  if [[ $direction == "Forward" ]]; then
    INPUT_BASE_NAME_bound="${FORWARD_NAME_bound}"
    INPUT_BASE_NAME_unbound="${FORWARD_NAME_unbound}"
  elif [[ $direction == "Reverse" ]]; then
    INPUT_BASE_NAME_bound="${REVERSE_NAME_bound}"
    INPUT_BASE_NAME_unbound="${REVERSE_NAME_unbound}"
  fi
  cd "${RUN_FOLDER}/${direction}" || { echo "Cannot enter ${RUN_FOLDER}/${direction}"; exit 2; }
  DIRECTION_FOLDER="$(pwd)"
  mkdir -p Bound_state_1 UNBound_state_1

  # Make topology with pmx (following pmx tutorial)
  # Use the local pmx version (python3)
  ################################################      BOUND ################################
  STARTING_PDB=$(ls ./*pdb)
  STARTING_PDB=${STARTING_PDB%.pdb}
  BASE_NAME=${INPUT_BASE_NAME_bound}
  sed -i 's/HISE/HIS /g' "${STARTING_PDB}.pdb" || { echo "Error at sed on ${STARTING_PDB}.pdb.."; exit; }
  sed -i 's/HISD/HIS /g' "${STARTING_PDB}.pdb";
  sed -i 's/HISH/HIS /g' "${STARTING_PDB}.pdb"

  echo "Running pdb2gmx on BOUND structure.."
  _num_his=$(grep -E -c "(HIS     CA)|(CA  HIS)" ./"${STARTING_PDB}.pdb")
  _pdb2gmx_string=
  for i in $(seq 1 "$_num_his"); do
    _pdb2gmx_string="${_pdb2gmx_string}1\n"
  done
  _pdb2gmx_string="${_pdb2gmx_string}q\n"
  echo -e "${_pdb2gmx_string}" | gmx pdb2gmx -f "${STARTING_PDB}.pdb" -o "${STARTING_PDB}_ff.pdb" -ignh \
        -ff amber99sb-star-ildn-mut -water tip3p -his &> pdb2gmx.out || { echo "Error at pdb2gmx.."; exit; }
  # 1 1 1 1 1 1 1 1 1 1 1 1
  # change name HISE HISD HISH ->HIS
  sed -i 's/HISE/HIS /g' "${STARTING_PDB}_ff.pdb" || { echo "Error at sed on ${STARTING_PDB}_ff.pdb.."; exit; };
  sed -i 's/HISD/HIS /g' "${STARTING_PDB}_ff.pdb";
  sed -i 's/HISH/HIS /g' "${STARTING_PDB}_ff.pdb"

  echo "Running pmx mutate on BOUND structure.."
  pmx mutate -f "${STARTING_PDB}_ff.pdb" -o "${BASE_NAME}.pdb" -ff amber99sb-star-ildn-mut --script ./mutations*.txt \
              --keep_resid || { echo "Error at pmx mutate.."; exit; } | tee -a pmx_mutate.out

  echo "Running pdb2gmx 2nd time on BOUND structure.. (this will give the right posres)"
  cp "${BASE_NAME}.pdb" Bound_state_1; cd Bound_state_1 || { echo "Cannot enter Bound_state_1"; exit 2; }
  _num_his=$(grep -E -c "(HIS     CA)|(CA  HIS)" ./"${BASE_NAME}.pdb")
  _pdb2gmx_string=
  for i in $(seq 1 "$_num_his"); do
    _pdb2gmx_string="${_pdb2gmx_string}1\n"
  done
  _pdb2gmx_string="${_pdb2gmx_string}q\n"
  echo -e "${_pdb2gmx_string}" | gmx pdb2gmx -f "${BASE_NAME}.pdb" -o "${BASE_NAME}_ff.pdb" -ff amber99sb-star-ildn-mut \
              -water tip3p -his  &> pdb2gmx_2.out || { echo "Error at pdb2gmx_2.."; exit; }
  # 1 1 1 1 1 1 1 1 1 1
  # change name HISE HISD HISH ->HIS
  sed -i 's/HISE/HIS /g' "${BASE_NAME}_ff.pdb";
  sed -i 's/HISD/HIS /g' "${BASE_NAME}_ff.pdb";
  sed -i 's/HISH/HIS /g' "${BASE_NAME}_ff.pdb"

  echo "Running editconf on BOUND structure.."
  echo -e "1\n" | gmx editconf -f "${BASE_NAME}_ff.pdb"  -o "${BASE_NAME}_ff_box.pdb" -d 1.0 -bt cubic -c -princ \
        &> editconf.out
  # 1
  #BOX_VECTORS=`tail -n1 ${BASE_NAME}_ff_box.gro`
  echo "Running pmx gentop on BOUND structure.."
  pmx gentop -p topol.top -o topol_hybrid.top | tee -a pmx_gentop.out
  cp ./pmx*itp ./posre*itp ./*hybrid.top ./"${BASE_NAME}_ff_box.pdb" ../UNBound_state_1

  rm ./*#

  cd "${DIRECTION_FOLDER}/Bound_state_1" || { echo "Cannot enter ${DIRECTION_FOLDER}/Bound_state_1"; exit 2; }
  echo "Running gmx solvate on BOUND structure.."
  gmx solvate -cp "${BASE_NAME}_ff_box.pdb" -cs spc216.gro -o "${BASE_NAME}_ff_water.gro" -p topol_hybrid.top \
        &> gensolvate.out || { echo "Error at BOUND gensolvate.."; exit; }
  touch minim.mdp
  echo "Running gmx genion on BOUND structure.."
  gmx grompp -f minim.mdp -c "${BASE_NAME}_ff_water.gro" -p topol_hybrid.top -o "${BASE_NAME}_ff_ions.tpr" -maxwarn 1 \
        &> grompp_genion.out
  echo -e "SOL\n" | gmx genion -s "${BASE_NAME}_ff_ions.tpr" -o "${BASE_NAME}_ff_ions.gro" -p topol_hybrid.top \
              -nname CL -pname K -neutral -conc 0.15 &> genion.out || { echo "Error at BOUND genion.."; exit; }
  echo -e "keep 0\nr SOL K CL\n0 & ! 1\n name 2 SOLU\n name 1 SOLV\n\nq\n" | gmx make_ndx -f "${BASE_NAME}_ff_ions.gro" \
        &> make_ndx.out || { echo "Error at BOUND make_ndx.."; exit; }

  cp ${FEP_FOLDER}/hrex_fep_gmx_HLA.sh ./
  rm ./*#
  ################################################# UNBOUND (or FREE) ###############################
  STARTING_PDB=${BASE_NAME}
  BASE_NAME2=${INPUT_BASE_NAME_unbound}

  #gmx pdb2gmx -f ${STARTING_PDB}.pdb -o ${STARTING_PDB}_ff.pdb -ignh -ff amber99sb-star-ildn-mut -water tip3p -his
  # 0 2 0 0 0 0 0 2

  # change name HISE HISD HISH ->HIS
  #sed -i 's/HISE/HIS /g' ${STARTING_PDB}_ff.pdb; sed -i 's/HISD/HIS /g' ${STARTING_PDB}_ff.pdb; sed -i 's/HISH/HIS /g' ${STARTING_PDB}_ff.pdb

  #pmx mutate -f ${STARTING_PDB}_ff.pdb -o ${BASE_NAME2}.pdb -ff amber99sb-star-ildn-mut --script ./mutations*.txt --keep_resid

  #cp ${BASE_NAME2}.pdb UNBound_state_1; cd UNBound_state_1
  #gmx pdb2gmx -f ${BASE_NAME2}.pdb -o ${BASE_NAME2}_ff.pdb -ff amber99sb-star-ildn-mut -water tip3p -his
  # 0 2 0 0 0 0 0 2
  # change name HISE HISD HISH ->HIS
  #sed -i 's/HISE/HIS /g' ${BASE_NAME}_ff.pdb; sed -i 's/HISD/HIS /g' ${BASE_NAME2}_ff.pdb; sed -i 's/HISH/HIS /g' ${BASE_NAME2}_ff.pdb

  cd "${DIRECTION_FOLDER}/UNBound_state_1" || { echo "Cannot enter ${DIRECTION_FOLDER}/UNBound_state_1"; exit 2; }
  mv "${STARTING_PDB}_ff_box.pdb" "${BASE_NAME2}_ff_box.pdb"
  # gedit ${BASE_NAME}_ff_box.pdb

  for chain in $CHAINS_TO_REMOVE; do
    sed -i '/^ATOM.*[A-Z] '"${chain}"' /d' "${BASE_NAME2}_ff_box.pdb";
    sed -i '/Protein_chain_'"${chain}"'/d' topol_hybrid.top;
    rm "posre_Protein_chain_${chain}.itp" "pmx_topol_Protein_chain_${chain}.itp"
  done
  # gmx editconf -f ${BASE_NAME2}_ff.pdb  -o ${BASE_NAME2}_ff_box.gro -box ${BOX_VECTORS}

  echo "Running gmx solvate on FREE structure.."
  gmx solvate -cp "${BASE_NAME2}_ff_box.pdb" -cs spc216.gro -o "${BASE_NAME2}_ff_water.gro" -p topol_hybrid.top \
        &> gensolvate.out || { echo "Error at FREE gensolvate.."; exit; }
  touch minim.mdp
  echo "Running gmx genion on FREE structure.."
  gmx grompp -f minim.mdp -c "${BASE_NAME2}_ff_water.gro" -p topol_hybrid.top -o "${BASE_NAME2}_ff_ions.tpr" -maxwarn 1 \
        &> grompp_genion.out
  echo -e "SOL\n" | gmx genion -s "${BASE_NAME2}_ff_ions.tpr" -o "${BASE_NAME2}_ff_ions.gro" -p topol_hybrid.top \
            -nname CL -pname K -neutral -conc 0.15 &> genion.out || { echo "Error at FREE genion.."; exit; }
  echo -e "keep 0\nr SOL K CL\n0 & ! 1\n name 2 SOLU\n name 1 SOLV\n\nq\n" | gmx make_ndx -f "${BASE_NAME2}_ff_ions.gro" \
        &> make_ndx.out || { echo "Error at FREE make_ndx.."; exit; }

  cp ${FEP_FOLDER}/hrex_fep_gmx_HLA.sh ./
  sed -i 's/cd ..\/UNBound_state_1/cd ..\/Bound_state_2/g' hrex_fep_gmx_HLA.sh
  rm ./*#
  ################################################################################

  cd "${DIRECTION_FOLDER}" || { echo "Cannot enter ${DIRECTION_FOLDER}"; exit 2; }
  cp -r Bound_state_1 Bound_state_2; sed -i 's/cd ..\/UNBound_state_1/cd ..\/UNBound_state_2/g' Bound_state_2/hrex_fep_gmx_HLA.sh
  cp -r Bound_state_1 Bound_state_3; sed -i 's/cd ..\/UNBound_state_1/cd ..\/UNBound_state_3/g' Bound_state_3/hrex_fep_gmx_HLA.sh
  cp -r UNBound_state_1 UNBound_state_2; sed -i 's/cd ..\/Bound_state_2/cd ..\/Bound_state_3/g' UNBound_state_2/hrex_fep_gmx_HLA.sh
  cp -r UNBound_state_1 UNBound_state_3; sed -i 's/cd ..\/Bound_state_2/exit/g' UNBound_state_3/hrex_fep_gmx_HLA.sh

  echo -e "\n\t -> You can start EM calculations of Bound_state_1 with: \n\t bash hrex_fep_gmx_HLA.sh ${BASE_NAME}_ff_ions.gro ${BASE_NAME2}_ff_ions.gro\n"

done

exit






gmx solvate -cp ${BASE_NAME}_ff_box.pdb -cs spc216.gro -o ${BASE_NAME}_ff_water.gro -p topol_hybrid.top
touch minim.mdp
gmx grompp -f minim.mdp -c ${BASE_NAME}_ff_water.gro -p topol_hybrid.top -o ${BASE_NAME}_ff_ions.tpr -maxwarn 1
gmx genion -s ${BASE_NAME}_ff_ions.tpr -o ${BASE_NAME}_ff_ions.gro -p topol_hybrid.top -nname CL -pname K -neutral -conc 0.15
# 13

# I need the groups SOLU & SOLV
gmx make_ndx -f ${BASE_NAME}_ff_ions.gro
# keep 1\nr SOL K CL\n name 0 SOLU\n name 1 SOLV\nq\n

cp -r Bound_state_1/ Bound_state_2; cp -r Bound_state_1/ Bound_state_3
cp -r UNBound_state_1/ UNBound_state_2; cp -r UNBound_state_1/ UNBound_state_3
######################################### test #########################################
# WORKING test for window -> 0
mkdir lambda0; cd lambda0
sed -e "s/KEY_win_idx/0/g" "${FEP_FOLDER}/MDPs/em.mdp" > em.mdp
sed -e "s/KEY_win_idx/0/g" "${FEP_FOLDER}/MDPs/nvt.mdp" > nvt.mdp
sed -e "s/KEY_win_idx/0/g" "${FEP_FOLDER}/MDPs/npt.mdp" > npt.mdp
sed -e "s/KEY_win_idx/0/g" "${FEP_FOLDER}/MDPs/prod.mdp" > prod.mdp

# EM
gmx grompp -f em.mdp -c ../${BASE_NAME}_ff_ions.gro -p ../topol_hybrid.top -n ../index.ndx -o ${BASE_NAME}_ff_EM.tpr -maxwarn 2
gmx mdrun -s ${BASE_NAME}_ff_EM.tpr -c ${BASE_NAME}_ff_EM.gro -v

# NVT
gmx grompp -f nvt.mdp -c ${BASE_NAME}_ff_EM.gro -r ${BASE_NAME}_ff_EM.gro -n ../index.ndx -p ../topol_hybrid.top -o ${BASE_NAME}_ff_NVT.tpr -maxwarn 3
gmx mdrun -s ${BASE_NAME}_ff_NVT.tpr -c ${BASE_NAME}_ff_NVT.gro -v

# NPT
gmx grompp -f npt.mdp -c ${BASE_NAME}_ff_NVT.gro -r ${BASE_NAME}_ff_NVT.gro -n ../index.ndx -p ../topol_hybrid.top -o ${BASE_NAME}_ff_NPT.tpr -maxwarn 3
gmx mdrun -s ${BASE_NAME}_ff_NPT.tpr -c ${BASE_NAME}_ff_NPT.gro -nb gpu -bonded gpu -v

# Production
gmx grompp -f prod.mdp -c ${BASE_NAME}_ff_NPT.gro -r ${BASE_NAME}_ff_NPT.gro -n ../index.ndx -p ../topol_hybrid.top -o ${BASE_NAME}_ff_PROD.tpr -maxwarn 3
gmx mdrun -s ${BASE_NAME}_ff_PROD.tpr -c ${BASE_NAME}_ff_PROD.gro -nb gpu -bonded gpu -pin on -dhdl dhdl -v




######################################### Analysis #########################################
conda activate FEP_anal
#mkdir results;for l in `seq 0 31`; do cp lambda$l/PROD/dhdl.xvg results/dhdl$l.xvg; done; alchemical_analysis -t 310 -u kcal -m MBAR -d results > alchemical_analysis.out

mkdir results;
echo -e "avg bound\tstd bound\tavg free\tstd free" > results.out
for run in `seq 1 3`; do
  for l in `seq 0 31`; do
    cp Bound_state_${run}/lambda$l/PROD/dhdl.xvg results/bound_${run}_dhdl$l.xvg;
    cp UNBound_state_${run}/lambda$l/PROD/dhdl.xvg results/free_${run}_dhdl$l.xvg;
  done
  alchemical_analysis -t 310 -u kcal -m MBAR -d results -p bound_${run}_dhdl -j results_bound_${run} > alchemical_analysis_bound_${run}.out
  alchemical_analysis -t 310 -u kcal -m MBAR -d results -p free_${run}_dhdl -j results_free_${run} > alchemical_analysis_free_${run}.out

  value_b=`tail -n1 results/results_bound_${run}.txt | cut -b11- | cut -d+ -f1`
  err_b=`tail -n1 results/results_bound_${run}.txt   | cut -b11- | cut -d- -f2`
  value_f=`tail -n1 results/results_free_${run}.txt | cut -b11- | cut -d+ -f1`
  err_f=`tail -n1 results/results_free_${run}.txt   | cut -b11- | cut -d- -f2`
  echo -e "$value_b\t$err_b\t$value_f\t$err_f" >> results.out
done



#########################################    RUNNING      #########################################
# How to RUN (hrex_fep_gmx_HLA.sh):

### Run the script seperatly for Bond and UnBond    ###
### Specify the simulations variables               ###
### Make sure: 1. number of replicas/windows (x OMP_NUM_THREADS) equals the number in ppn=<nproc>
###            2. number of replicas/windows is divisible by the number in gpus=<ngpu>

NUMBER_OF_WINDOWS=32
STARTING_FOLDER="$(pwd)"
STRUCTURE_FILE="${STARTING_FOLDER}/HLA_BiAB_pWT_hybrid_complex_B_ff_ions.gro"
TOPOLOGY_ILE="${STARTING_FOLDER}/topol_hybrid.top"
INDEX_FILE="${STARTING_FOLDER}/index.ndx"
MDPs_FOLDER="/media/iqb/My Passport1/ZJU_work/BiSpecificAB/Maturation/FEP/MDPs"

######

echo "Start time: $(date)"
echo "Starting folder: $STARTING_FOLDER"

export GMXLIB=/home/iqb/Documents/ZJU_work/PROGRAMMING/pmx/src/pmx/data/mutff/
export PATH:$PATH:/home/iqb/Documents/ZJU_work/PROGRAMMING/pmx/src/pmx/scripts/

# Define variables
num_windows=${NUMBER_OF_WINDOWS}
window_start=0
window_end=$((num_windows - 1))
directories="$(seq "$window_start" "$window_end" | awk '{printf "lambda%s ", $0}')"

# Make the directories with the mdp files
echo "$(date) Building the folders.. "
for window_idx in $(seq "$window_start" "$window_end"); do
  mkdir "lambda$window_idx"
  mkdir "lambda$window_idx/EM" "lambda$window_idx/NVT" "lambda$window_idx/NPT" "lambda$window_idx/PROD"
  cp "${MDPs_FOLDER}/em.mdp" "${MDPs_FOLDER}/npt.mdp" "${MDPs_FOLDER}/nvt.mdp" "${MDPs_FOLDER}/prod.mdp" "lambda$window_idx"
  sed -i -e "s/KEY_win_idx/$window_idx/g" "lambda$window_idx"/em.mdp
  sed -i -e "s/KEY_win_idx/$window_idx/g" "lambda$window_idx"/nvt.mdp
  sed -i -e "s/KEY_win_idx/$window_idx/g" "lambda$window_idx"/npt.mdp
  sed -i -e "s/KEY_win_idx/$window_idx/g" "lambda$window_idx"/prod.mdp
done

#
#GENBOX
#GROMPP
#MAKE_NDX
#GENION
#source buildBoxWaterIons
#buildBoxWaterIons  -s "system.gro" -t "topol.top" -m "${MDPs_FOLDER}/em.mdp" || exit

# Energy Minimization
echo "$(date) Starting Energy minimization.. "
for window_idx in $(seq "$window_start" "$window_end"); do
  cd "${STARTING_FOLDER}/lambda$window_idx"

  echo "$(date) PWD=$PWD -> Starting EM"
  # EM
  gmx grompp -f em.mdp -c "${STRUCTURE_FILE}" -r "${STRUCTURE_FILE}" -p "${TOPOLOGY_ILE}" -n "${INDEX_FILE}" -o "./em.tpr" -maxwarn 2
  gmx mdrun -v -deffnm em || { echo "Something went wrong on the mdrun.."; exit; }
  mv ./em* ./EM

  echo "$(date)  Starting NVT"
  # NVT
  gmx grompp -f nvt.mdp -c "./EM/em.gro" -r "./EM/em.gro" -p "${TOPOLOGY_ILE}" -n "${INDEX_FILE}" -o "./nvt.tpr" -maxwarn 3
  gmx mdrun -v -deffnm nvt -nb gpu -bonded gpu || { echo "Something went wrong on the mdrun.."; exit; }
  mv ./nvt* ./NVT

  echo "$(date)  Starting NPT"
  # NPT
  gmx grompp -f npt.mdp -c "./NVT/nvt.gro" -r "./NVT/nvt.gro" -p "${TOPOLOGY_ILE}" -n "${INDEX_FILE}" -o "./npt.tpr" -maxwarn 3
  gmx mdrun -v -deffnm npt -nb gpu -bonded gpu || { echo "Something went wrong on the mdrun.."; exit; }
  mv ./npt* ./NPT

  echo "$(date)  Starting Production"
  # Production
  gmx grompp -f prod.mdp -c "./NPT/npt.gro" -r "./NPT/npt.gro" -p "${TOPOLOGY_ILE}" -n "${INDEX_FILE}" -o "./prod.tpr" -maxwarn 3
  gmx mdrun -v -deffnm prod -nb gpu -bonded gpu -pin on -dhdl dhdl || { echo "Something went wrong on the mdrun.."; exit; }
  mv ./prod* ./dhdl* ./PROD

done

cd $STARTING_FOLDER/; cd ../UNBound_state_2
bash hrex_fep_gmx_HLA.sh
