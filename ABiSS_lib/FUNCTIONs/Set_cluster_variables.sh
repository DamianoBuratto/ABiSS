#!/bin/bash

# OLD OPTIONS ON ABiSS_CONNEXIN
# GROMPP="gmx grompp"
# MDRUN="mpirun -np $NP_value mdrun -ntomp $NTOMP"
# MDRUN="mpirun -np $NP_value $MDRUN -ntomp $NTOMP"
# [ $MNP -eq 1 ] && let MNP=NP_value
# PDB2GMX="gmx pdb2gmx"
# EDITCONF="gmx editconf"
# GENBOX="gmx solvate"
# GENION="gmx genion"
# MAKE_NDX="gmx make_ndx"

echo -e "\t > Set_cluster_variables.sh"

#==========================================================================================================
#	 Set_cluster_variables
#==========================================================================================================
# shellcheck disable=SC2154
function Set_cluster_variables {
  local _cluster=$1

  #if [ "$_cluster" == "" ]; then _cluster="no"; fi
  msg "cluster = ${_cluster:=no}"

  case "$_cluster" in

    IQB)
    echo -e "\n**USING ZJU-IQB CLUSTER VARIABLES**" | tee -a "${LOGFILENAME}"
  	# FUNCTIONS_PATH="/public/home/damiano/Programs/ABiSS_custom_v3"
#  	"/public/home/damiano/Programs/miniconda3/envs/gmxMMPBSA_1.6.1/bin"
  	PYTHON="${PYTHON:-/public/home/damiano/Programs/miniconda3/bin/python}"
  	CONDA_activate_path="$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${input_file}" -k CONDA_activate_path)"
  	CONDA_gmxmmpbsa_name="$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${input_file}" -k CONDA_gmxmmpbsa_name)"
  	CONDA_modeller_name="$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${input_file}" -k CONDA_modeller_name)"
  	GMXPBSApath="$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${input_file}" -k GMXPBSApath)"
  	CPATH="$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${input_file}" -k CPATH)"
  	APATH="$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${input_file}" -k APATH)"
  	GPATH="$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${input_file}" -k GPATH)"
  	CHIMERA="$(python "${FUNCTIONs_FOLDER}"/load_input_file.py -i "${input_file}" -k CHIMERA)"

  	msg "CONDA_activate_path -> ${CONDA_activate_path:=/public/home/damiano/Programs/miniconda3/bin}"
    msg "CONDA_gmxmmpbsa_name -> ${CONDA_gmxmmpbsa_name:-gmxMMPBSA_1.6.2}"
    msg "CONDA_modeller_name -> ${CONDA_modeller_name:=modeller}"
    msg "GMXPBSApath -> ${GMXPBSApath:=${ProgramPATH}/gmxpbsa-master}"
    msg "CPATH -> ${CPATH:=/public/home/damiano}"
  	msg "APATH -> ${APATH:=/public/home/damiano/Programs/APBS-1.5-linux64/bin}"
    msg "GPATH -> ${GPATH:=/public/home/damiano/Programs/miniconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/bin}"
    msg "CHIMERA -> ${CHIMERA:=/public/home/damiano/Programs/UCSF-Chimera64_1.16/bin}"
  	VMD="findPATH"
    # source /public/software/apps/gromacs/2022.2-openmpi/bin/GMXRC.bash
  	# WITH "source /public/software/apps/gromacs/2022.2-openmpi/bin/GMXRC.bash" ->
  	# From '/public/software/apps/gromacs/2022.2-openmpi/share/gromacs/top':
    # 1: AMBER03 protein, nucleic AMBER94 (Duan et al., J. Comp. Chem. 24, 1999-2012, 2003)
    # 2: AMBER94 force field (Cornell et al., JACS 117, 5179-5197, 1995)
    # 3: AMBER96 protein, nucleic AMBER94 (Kollman et al., Acc. Chem. Res. 29, 461-469, 1996)
    # 4: AMBER99 protein, nucleic AMBER94 (Wang et al., J. Comp. Chem. 21, 1049-1074, 2000)
    # 5: AMBER99SB protein, nucleic AMBER94 (Hornak et al., Proteins 65, 712-725, 2006)
    # 6: AMBER99SB-ILDN protein, nucleic AMBER94 (Lindorff-Larsen et al., Proteins 78, 1950-58, 2010)
    # 7: AMBERGS force field (Garcia & Sanbonmatsu, PNAS 99, 2782-2787, 2002)
    # 8: CHARMM27 all-atom force field (CHARM22 plus CMAP for proteins)
    # 9: GROMOS96 43a1 force field
    # 10: GROMOS96 43a2 force field (improved alkane dihedrals)
    # 11: GROMOS96 45a3 force field (Schuler JCC 2001 22 1205)
    # 12: GROMOS96 53a5 force field (JCC 2004 vol 25 pag 1656)
    # 13: GROMOS96 53a6 force field (JCC 2004 vol 25 pag 1656)
    # 14: GROMOS96 54a7 force field (Eur. Biophys. J. (2011), 40,, 843-856, DOI: 10.1007/s00249-011-0700-9)
    # 15: OPLS-AA/L all-atom force field (2001 aminoacid dihedrals)
  	# ---------------------------------------------------------------------------------------------------------
  	# WITH Gpath="/public/home/damiano/miniconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/bin"
    # From '/public/home/damiano/miniconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/share/gromacs/top':
    # 1: AMBER03 protein, nucleic AMBER94 (Duan et al., J. Comp. Chem. 24, 1999-2012, 2003)
    # 2: AMBER94 force field (Cornell et al., JACS 117, 5179-5197, 1995)
    # 3: AMBER96 protein, nucleic AMBER94 (Kollman et al., Acc. Chem. Res. 29, 461-469, 1996)
    # 4: AMBER99 protein, nucleic AMBER94 (Wang et al., J. Comp. Chem. 21, 1049-1074, 2000)
    # 5: AMBER99SB protein, nucleic AMBER94 (Hornak et al., Proteins 65, 712-725, 2006)
    # 6: AMBER99SB-ILDN protein, nucleic AMBER94 (Lindorff-Larsen et al., Proteins 78, 1950-58, 2010)
    # 7: AMBERGS force field (Garcia & Sanbonmatsu, PNAS 99, 2782-2787, 2002)
    # 8: CHARMM27 all-atom force field (with CMAP) - version 2.0
    # 9: GROMOS96 43a1 force field
    # 10: GROMOS96 43a2 force field (improved alkane dihedrals)
    # 11: GROMOS96 45a3 force field (Schuler JCC 2001 22 1205)
    # 12: GROMOS96 53a5 force field (JCC 2004 vol 25 pag 1656)
    # 13: GROMOS96 53a6 force field (JCC 2004 vol 25 pag 1656)
    # 14: GROMOS96 54a7 force field (Eur. Biophys. J. (2011), 40,, 843-856, DOI: 10.1007/s00249-011-0700-9)
    # 15: OPLS-AA/L all-atom force field (2001 aminoacid dihedrals)
    # 16: [DEPRECATED] Encad all-atom force field, using full solvent charges
    # 17: [DEPRECATED] Encad all-atom force field, using scaled-down vacuum charges
    # 18: [DEPRECATED] Gromacs force field (see manual)
    # 19: [DEPRECATED] Gromacs force field with hydrogens for NMR

#  	FORCE_FIELD="6"

  	#gmx="gmx_mpi"
    if [[ "${source_GMX}" != "" ]]; then source "${source_GMX}"; fi
  	_gromacs="$(command -v gmx_mpi)"
    if [ "$_gromacs" == "" ]; then
      _gromacs="$(command -v gmx)"
      if [ "$_gromacs" == "" ]; then
        fatal 1 "Set_cluster_variables ERROR: Cannot find any Gromacs."
      fi
    fi
	
	GMX=${_gromacs}
  	GROMPP="${GMX} grompp"
#  	MDRUN="${GMX} mdrun"
  	EDITCONF="${GMX} editconf"
  	PDB2GMX="${GMX} pdb2gmx"
  	GENBOX="${GMX} solvate"
  	GENION="${GMX} genion"
  	MAKE_NDX="${GMX} make_ndx"
  	TRJCONV="${GMX} trjconv"
  	GENRESTR="${GMX} genrestr"
  	CHECK="${GMX} check"
  	ENERGY="${GMX} energy"


  	# MPI_RUN is good for parallel simulations (replica exchange) otherwise is slow
  	#MPI_RUN="mpirun -np $NP_value -hostfile $PBS_NODEFILE --mca orte_rsh_agent ssh --mca btl self,openib,sm "
#    MDRUN="gmx mdrun -ntmpi 1 -ntomp ${NP_value} -nb gpu -pme gpu -bonded gpu -update gpu -gpu_id $CUDA_visible_devices"
#   not necessary to specify -gpu_id -> it automatically uses all
#    MDRUN="${GMX} mdrun -ntmpi 1 -ntomp ${NP_value}"
#    MDRUN_md="${GMX} mdrun -ntmpi 1 -ntomp ${NP_value} -nb gpu -pme gpu -bonded gpu -update gpu"
    MDRUN="${GMX} mdrun -ntmpi 1"
    MDRUN_md="${GMX} mdrun -ntmpi 1 -nb gpu -pme gpu -bonded gpu -update gpu"

  	KEY_compressed="nstxout-compressed"	   # this "command" changed name from gromacs5 on
    ;;

  ######===============================================================================================
    SIAIS)
    echo -e "\n**USING ShanghaiTech CLUSTER VARIABLES**" | tee -a "${LOGFILENAME}"
  	# FUNCTIONS_PATH="/public/home/damiano/ABiSS_custom_v2"
  	# FUNCTIONS_PATH="/public/home/damiano/ABiSS_custom_v3"
    GMXPBSApath="${ProgramPATH}/gmxpbsa-master"
    CPATH="/public/home/damiano"
    GPATH="/public/home/damiano/miniconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/bin"
  	# Apath="/public/software/gromacs/apbs/APBS-1.3/bin"    # module load apps/APBS/1.3
    APATH="/public/home/damiano/programs/APBS-3.0.0.Linux/bin/"
  	VMD="/public/home/damiano/programs/vmd"
    CHIMERA="/public/software/chimera-1.14/bin/chimera"     # module load apps/chimera/1.14
  	# WITH "module load apps/gromacs/2020_4_intelmpi_gpu" ->
  	# 1: AMBER03 protein, nucleic AMBER94 (Duan et al., J. Comp. Chem. 24, 1999-2012, 2003)
  	# 2: AMBER94 force field (Cornell et al., JACS 117, 5179-5197, 1995)
  	# 3: AMBER96 protein, nucleic AMBER94 (Kollman et al., Acc. Chem. Res. 29, 461-469, 1996)
  	# 4: AMBER99 protein, nucleic AMBER94 (Wang et al., J. Comp. Chem. 21, 1049-1074, 2000)
  	# 5: AMBER99SB protein, nucleic AMBER94 (Hornak et al., Proteins 65, 712-725, 2006)
  	# 6: AMBER99SB-ILDN protein, nucleic AMBER94 (Lindorff-Larsen et al., Proteins 78, 1950-58, 2010)
  	# 7: AMBERGS force field (Garcia & Sanbonmatsu, PNAS 99, 2782-2787, 2002)
  	# 8: CHARMM27 all-atom force field (CHARM22 plus CMAP for proteins)
  	# 9: GROMOS96 43a1 force field
  	# 10: GROMOS96 43a2 force field (improved alkane dihedrals)
  	# 11: GROMOS96 45a3 force field (Schuler JCC 2001 22 1205)
  	# 12: GROMOS96 53a5 force field (JCC 2004 vol 25 pag 1656)
  	# 13: GROMOS96 53a6 force field (JCC 2004 vol 25 pag 1656)
  	# 14: GROMOS96 54a7 force field (Eur. Biophys. J. (2011), 40,, 843-856, DOI: 10.1007/s00249-011-0700-9)
  	# 15: OPLS-AA/L all-atom force field (2001 aminoacid dihedrals)
  	# ---------------------------------------------------------------------------------------------------------
  	# WITH "module load apps/gromacs/4.5.7" ->
  	# 1: AMBER03 protein, nucleic AMBER94 (Duan et al., J. Comp. Chem. 24, 1999-2012, 2003)
    # 2: AMBER94 force field (Cornell et al., JACS 117, 5179-5197, 1995)
    # 3: AMBER96 protein, nucleic AMBER94 (Kollman et al., Acc. Chem. Res. 29, 461-469, 1996)
    # 4: AMBER99 protein, nucleic AMBER94 (Wang et al., J. Comp. Chem. 21, 1049-1074, 2000)
    # 5: AMBER99SB protein, nucleic AMBER94 (Hornak et al., Proteins 65, 712-725, 2006)
    # 6: AMBER99SB-ILDN protein, nucleic AMBER94 (Lindorff-Larsen et al., Proteins 78, 1950-58, 2010)
    # 7: AMBERGS force field (Garcia & Sanbonmatsu, PNAS 99, 2782-2787, 2002)
    # 8: CHARMM27 all-atom force field (with CMAP) - version 2.0
    # 9: GROMOS96 43a1 force field
    # 10: GROMOS96 43a2 force field (improved alkane dihedrals)
    # 11: GROMOS96 45a3 force field (Schuler JCC 2001 22 1205)
    # 12: GROMOS96 53a5 force field (JCC 2004 vol 25 pag 1656)
    # 13: GROMOS96 53a6 force field (JCC 2004 vol 25 pag 1656)
    # 14: OPLS-AA/L all-atom force field (2001 aminoacid dihedrals)
    # 15: [DEPRECATED] Encad all-atom force field, using full solvent charges
    # 16: [DEPRECATED] Encad all-atom force field, using scaled-down vacuum charges
    # 17: [DEPRECATED] Gromacs force field (see manual)
    # 18: [DEPRECATED] Gromacs force field with hydrogens for NMR
  	# ---------------------------------------------------------------------------------------------------------
    # WITH Gpath="/public/home/damiano/miniconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/bin"
    # From '/public/home/damiano/miniconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/share/gromacs/top':
    # 1: AMBER03 protein, nucleic AMBER94 (Duan et al., J. Comp. Chem. 24, 1999-2012, 2003)
    # 2: AMBER94 force field (Cornell et al., JACS 117, 5179-5197, 1995)
    # 3: AMBER96 protein, nucleic AMBER94 (Kollman et al., Acc. Chem. Res. 29, 461-469, 1996)
    # 4: AMBER99 protein, nucleic AMBER94 (Wang et al., J. Comp. Chem. 21, 1049-1074, 2000)
    # 5: AMBER99SB protein, nucleic AMBER94 (Hornak et al., Proteins 65, 712-725, 2006)
    # 6: AMBER99SB-ILDN protein, nucleic AMBER94 (Lindorff-Larsen et al., Proteins 78, 1950-58, 2010)
    # 7: AMBERGS force field (Garcia & Sanbonmatsu, PNAS 99, 2782-2787, 2002)
    # 8: CHARMM27 all-atom force field (with CMAP) - version 2.0
    # 9: GROMOS96 43a1 force field
    # 10: GROMOS96 43a2 force field (improved alkane dihedrals)
    # 11: GROMOS96 45a3 force field (Schuler JCC 2001 22 1205)
    # 12: GROMOS96 53a5 force field (JCC 2004 vol 25 pag 1656)
    # 13: GROMOS96 53a6 force field (JCC 2004 vol 25 pag 1656)
    # 14: GROMOS96 54a7 force field (Eur. Biophys. J. (2011), 40,, 843-856, DOI: 10.1007/s00249-011-0700-9)
    # 15: OPLS-AA/L all-atom force field (2001 aminoacid dihedrals)
    # 16: [DEPRECATED] Encad all-atom force field, using full solvent charges
    # 17: [DEPRECATED] Encad all-atom force field, using scaled-down vacuum charges
    # 18: [DEPRECATED] Gromacs force field (see manual)
    # 19: [DEPRECATED] Gromacs force field with hydrogens for NMR
  	FORCE_FIELD="6"
  	GMX="gmx_mpi"
  	GROMPP="${GMX} grompp"
  	MDRUN="${GMX} mdrun -ntomp ${NP_value}"
  	EDITCONF="${GMX} editconf"
  	PDB2GMX="${GMX} pdb2gmx"
  	GENBOX="${GMX} solvate"
  	GENION="${GMX} genion"
  	MAKE_NDX="${GMX} make_ndx"
  	TRJCONV="${GMX} trjconv"
  	GENRESTR="${GMX} genrestr"
  	CHECK="${GMX} check"
  	ENERGY="${GMX} energy"
  	RMS="${GMX} rms"
#  	mnp="4"
  	# MPI_MDRUN="mpirun -np $NP_value -hostfile $PBS_NODEFILE --mca orte_rsh_agent ssh --mca btl self,openib,sm $MDRUN"
#  	MPI_RUN="mpirun -np $NP_value "
    MDRUN_md="${GMX} mdrun -ntmpi 1 -ntomp ${NP_value} -nb gpu -pme gpu -bonded gpu -update gpu -gpu_id 0"
    ;;

  ######===============================================================================================
    no)
    msg "cluster option is OFF"
    PYTHON="$(which python)"
    ;;
    *)	fatal 1 "Set_cluster_variables ERROR: _cluster=$_cluster is not a valid OPTION!\n";;
	esac
}
