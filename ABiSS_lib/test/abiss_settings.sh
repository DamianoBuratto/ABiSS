#path and name of the temp file folder. Set by the program to ${RUN_FOLDER}/tempFILES - Default: 
TEMP_FILES_FOLDER="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/tempFILES"

#Name of the system that is going to be run. - Default: CXCR2
SystemName="HLA_biAB"

#Name of the file with the complex structure. MANDATORY. - Default: 
Complex_file_name="HLA_BiAB_protein_50ns.pdb"

#Name (with no ext) of the tpr FILE used for the production MD and compute BE - Default: system_Compl_MD
tprFILE="system_Compl_MD"

#Name (with no ext) of the xtc FILE from production MD and used to compute BE - Default: traj_MD
trjNAME="traj_MD"

#Name (with no ext) of the top FILE - Default: topol
topName="topol"

#Number of Fragment in the receptor (FIRST molecule in the starting pdb file) - Default: 1
receptorFRAG="2"

#Number of Fragment in the antibody (SECOND molecule in the starting pdb file) - Default: 2
ABchains="2"

#Use the merge interactive to make topology of the protein.If set to -merge, the mergeC, mergeR and mergeL need to be set accordingly. - Default: 
mergeFragments=""

#Merge string for Receptor only (Cx: r'y\nn\ny\nn\ny\nn\ny\nn\ny\nn\ny\n'). - Default: 
mergeC=""

#Merge string for Receptor only (Cx: r'y\nn\ny\nn\ny\nn\ny\nn\ny\nn\ny\n'). - Default: 
mergeR=""

#Merge string for Ligand (antibody) only. - Default: 
mergeL=""

#List of the Energy function that will be printed in output. The last one will be used by Metropolis. 3: dG | 8: ScoreF | 9:ScoreF2 | 10: CanonicalAVG | 11: Median | 12: dG_2sigma - Default: 3 12
EnergyFunction="12 3"

#False-> the final energy is computed as average of the single cycles.True -> all the single energies are used to compute the final value. - Default: False
average_all_frames="False"

#If the program will run a fast test or not. - Default: False
FAST="False"

#If the program will be talkative or not. - Default: False
VERBOSE="True"

#Method used to compute the BE. OPTs: GMXPBSA(old), Jmmpbsa, gmxMMPBSA - Default: gmxMMPBSA
EnergyCalculation="gmxMMPBSA"

#gmxpbsa program inside ABISS folder (PPATH). DO NOT CHANGE - Default: ${ProgramPATH}/gmxpbsa-master
GMXPBSApath="/public/home/damiano/Programs/ABiSS/ABiSS_custom_v6/gmxpbsa-master"

#(NEVER USED) path to the 'Coulomb' program - Default: /usr/bin
CPATH="/public/home/damiano"

#Path to the 'APBS' program - Default: findPATH
APATH="/public/home/damiano/Programs/APBS-1.5-linux64/bin"

#Path to the 'Gromacs4.6.7' program - Default: /home/iqb/anaconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/bin
GPATH="/public/home/damiano/Programs/miniconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/bin"

#Used with GMXPBSA. '-l' to use APBS with linearize PB - Default: -l
linearizedPB="-l"

#Used with GMXPBSA. - Default: 0
precF="0"

#Used with GMXPBSA. - Default: 2
pdie="2"

#Used with GMXPBSA. 'y' if you want to run minim before BE calculations - Default: n
GMXPBSAminim="n"

#Used with GMXPBSA. (e.g. -utc) - Default: 
GMXPBSA_use_tpbcon=""

#Used with GMXPBSA. (e.g. -noTF) - Default: 
GMXPBSA_NO_topol_ff=""

#Jerkwin program inside ABISS folder (PPATH). DO NOT CHANGE - Default: ${ABiSS_LIB}/Jerkwin_mmpbsa.bsh
JerkwinPROGRAM="/public/home/damiano/Programs/ABiSS/ABiSS_custom_v6/ABiSS_lib/Jerkwin_mmpbsa.bsh"

#Used with Jerkwin. To set the option of trjconv. - Default: -skip 100
trjconvOPT="-skip 100"

#Used with Jerkwin. Path to gromacs - Default: /usr/local/gromacs/bin/GMXRC
GsourcePATH="/usr/local/gromacs/bin/GMXRC"

#Used with gmxMMPBSA. Pre-built input file to use. - Default: mmpbsa_noLinearPB_amber99SB_ILDN.in
mmpbsa_inFILE="mmpbsa_LinearPB_amber99SB_ILDN.in"

#Set to True to select the residue to mutate using weight probability.The weights are derived from energy decomposition. (Must use MMGBSA_decomp) - Default: False
use_decomp_as_weights="False"

#Name with path of the files with the per-residue binding energy decomposition - Default: None
resid_be_decomp_files="None"

#Time of first frame to read {ps} when the xtc is prepared to compute BE (Default: 500ps) - Default: 500
startingFrameGMXPBSA="2000"

#Number of frames (starting from the last) on which the energy will be averaged (default: all) -almost computational costless- - Default: all
NUMframe="all"

#Number of cycle per system. e.g. '1' will run only one time every configuration - Default: 10
RunningNum_PerSystem="7"

#'yes' if the program have to restart a previous calculations - Default: no
Restart_calculations="no"

#Set to True if you want to use previously computed trajectories. You must set the reuse_MD_PATH variable. - Default: False
reuse_MD="False"

#Set to the path where the $cycle_number_MD_FOLDER of the previous MD can be found - Default: 
reuse_MD_PATH=""

#Set to the path where the abiss_settings of the previous run is. - Default: 
reuse_MD_abiss_settings=""

#Max number of mutation that will be attempted during the maturation - Default: 100
MaxMutant="30"

#Which ForceField to use for the MD and energy calculations - Default: 6
ForceField="amber99sb-ildn"

#Residues that will be restraint during MD. Generally used with Cx - Default: 
POSRES_RESIDUES=""

#Pool of residues from witch choose for the mutation. - Default: ALA ARG ASN ASP GLN GLU ILE LYS PHE PRO SER THR VAL TRP TYR LEU MET
ResiduePool_list="ALA ARG ASN ASP GLN GLU ILE LYS PHE PRO SER THR VAL TRP TYR LEU MET"

#List of the antibody RESIDUE:CHAIN that are allowed to be mutated - Default: 100:H 101:H 102:H 103:H
TargetResidueList="28:H 29:H 30:H 31:H 32:H 52:H 54:H 55:H 56:H 57:H 98:H 100:H 102:H 105:H 93:L 94:L 95:L"

#Option of editconf to be used when building the systemsNOTE that the long range interactions cut-off is set at 1.2nm - Default: -d 1.2 -bt triclinic -c
editconf_opt="-d 1.2 -bt triclinic -princ"

#Option for a possible 2nd editconf  - Default: 
editconf_opt2=""

#Option for a possible 3rd editconf - Default: 
editconf_opt3=""

#If position restraint will be used or not - Default: _posres
POSRES="_posres"

#Pressure Coupling keyword to use during simulations - Default: Parrinello-Rahman
KEY_pcoupl="C-rescale"

#Simulated annealing keyword to use during simulations - Default: single
KEY_annealing="single"

#Number of points in the Simulated annealing simulations - Default: 4
KEY_SA_npoints="4"

#Temperatures in the Simulated annealing simulations - Default: 310 380 380 310
KEY_SA_temp="310 380 380 310"

#Time steps during the Simulated annealing simulations - Default: 0 100 150 250
KEY_SA_time="0 100 150 250"

# - Default: 50000
KEY_nsteps_minim="50000"

# - Default: (int) (250 * 1000 + 100000)/2
KEY_nsteps_SAMD="175000"

# - Default: 50000
KEY_nsteps_NVT="50000"

# - Default: 50000
KEY_nsteps_NPT="50000"

# - Default: 750000
KEY_nsteps_MD="2500000"

#Removing the Center of Mass Motion in combination with PosRes may lead to artifacts - Default: none
KEY_commmode="none"

# - Default: (int) (250 * 1000 + 100000) / 2 / 50
KEY_nstouts_SAMD="3500"

# - Default: (int) 50000 / 10
KEY_nstouts_NVT="5000"

# - Default: (int) 75000 / 10
KEY_nstouts_NPT="7500"

# - Default: (int) 20000
KEY_nstouts_MD="10000"

# - Default: nstxtcout
KEY_compressed="nstxout-compressed"

#Set it to KEY_ to not use it - Default: -DPOSRES_abiss or -DPOSRES_BB
KEY_define_SAMD="-DPOSRES_abiss"

#Set it to KEY_ to not use it - Default: -DPOSRES_abiss
KEY_define_MD="-DPOSRES_abiss"

#Use a different method to select the new residue type (Carol K. paper) - Default: 
keep_hydration=""

#This option will activate the 'cluster' starting variables - Default: no
cluster="IQB"

#Number of OpenMP threads per MPI rank to start (-ntomp option on gmx mdrun) - Default: 4
NP_value="33"

#Path to the conda 'activate' program - Default: /home/iqb/anaconda3/bin/
CONDA_activate_path="/public/home/damiano/Programs/miniconda3/bin"

#Name of the conda environment for gmxMMPBSA - Default: gmxMMPBSA-1.6.1
CONDA_gmxmmpbsa_name="gmxMMPBSA_1.6.2"

#PATH to the gromacs GMXRC that you want to use. - Default: 
source_GMX="/public/software/apps/gromacs/2023.2/bin/GMXRC.bash"

#Name of the conda environment for modeller - Default: modeller
CONDA_modeller_name="modeller"

#Name of the CUDA devices that can be used. - Default: 0
CUDA_visible_devices="0"

#True-> Take into account the STD of results for the Metropolis algorithm - Default: True
metropolis_correction="True"

#Metropolis Temperature - Default: 2
Metropolis_Temp="1.5"

#Metropolis Temperature top limit - Default: 4
Metropolis_Temp_cap="3"

#Metropolis Temperature Used during the calculations. It could change. - Default: 
Eff_Metropolis_Temp="1.5"

#Number of consecutive discarded results. - Default: 0
Consecutive_DISCARD_Count="4"

#Name of the configuration in use. - Default: 
complex_FILE="Mutant25_cycle7_LastFrameMD"

#Extension of the configuration in use. - Default: 
complex_EXT="pdb"

#Name of the last configuration accepted. - Default: 
Stored_system_FILE="Mutant25_cycle7_LastFrameMD"

#Current configuration number. - Default: 
SEQUENCE="30"

#Program name. Retrieve at the beginning of the program. - Default: 
PN="ABiSS_custom.sh"

#Program PATH. Retrieve at the beginning of the program. - Default: 
ProgramPATH="/public/home/damiano/Programs/ABiSS/ABiSS_custom_v6"

#Starting folder. Retrieve at the beginning of the program. - Default: 
STARTING_FOLDER="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220"

#PATH to ABiSS_lib folder. Retrieve at the beginning of the program. - Default: 
ABiSS_LIB="/public/home/damiano/Programs/ABiSS/ABiSS_custom_v6/ABiSS_lib"

#PATH to FUNCTIONs_FOLDER folder. Retrieve at the beginning of the program. - Default: 
FUNCTIONs_FOLDER="/public/home/damiano/Programs/ABiSS/ABiSS_custom_v6/ABiSS_lib/FUNCTIONs"

#PATH to MDPs_FOLDER folder. Retrieve at the beginning of the program. - Default: 
MDPs_FOLDER="/public/home/damiano/Programs/ABiSS/ABiSS_custom_v6/ABiSS_lib/MDPs"

#Version of the Program. Retrieve at the beginning of the program. - Default: 
VER="0.6"

#Used to determine if you do a new mutation or not. - Default: False
Make_new_mutation="True"

#Could be used instead of the Random number to have a fixed acceptance probability. - Default: 
AcceptProb=""

#Configuration from witch to start (or restart). 0->WT - Default: 0
Starting_Configuration="0"

#Stored Average BE from the last configuration. - Default: no
Stored_AVG="-92.8"

#Stored BE standard deviation from the last configuration. - Default: no
Stored_STD="4.3"

# - Default: 
RUN_FOLDER="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1"

# - Default: 
LOGFILENAME="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/RUN1.out"

# - Default: 
CONFOUT_FILENAME="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/conf_RUN1.out"

# - Default: 
SETUP_PROGRAM_FOLDER="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/SETUP_PROGRAM_FILES"

# - Default: 
DOUBLE_CHECK_FOLDER="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/DOUBLE_CHECK"

# - Default: 
SELFAVOIDING_FILENAME="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/SETUP_PROGRAM_FILES/self_avoiding_file.out"

# - Default: 
current_conf_PATH="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/Mutant29"

# - Default: 
GROMPP="/public/software/apps/gromacs/2023.2/bin/gmx grompp"

# - Default: 
MDRUN="/public/software/apps/gromacs/2023.2/bin/gmx mdrun -ntmpi 1"

# - Default: 
MDRUN_md="/public/software/apps/gromacs/2023.2/bin/gmx mdrun -ntmpi 1 -nb gpu -pme gpu -bonded gpu -update gpu"

# - Default: 
PDB2GMX="/public/software/apps/gromacs/2023.2/bin/gmx pdb2gmx"

# - Default: 
EDITCONF="/public/software/apps/gromacs/2023.2/bin/gmx editconf"

# - Default: 
GENBOX="/public/software/apps/gromacs/2023.2/bin/gmx solvate"

#S - Default: 
GENION="/public/software/apps/gromacs/2023.2/bin/gmx genion"

# - Default: 
MAKE_NDX="/public/software/apps/gromacs/2023.2/bin/gmx make_ndx"

# - Default: 
TRJCONV="/public/software/apps/gromacs/2023.2/bin/gmx trjconv"

# - Default: 
GENRESTR="/public/software/apps/gromacs/2023.2/bin/gmx genrestr"

# - Default: 
CHECK="/public/software/apps/gromacs/2023.2/bin/gmx check"

# - Default: 
ENERGY="/public/software/apps/gromacs/2023.2/bin/gmx energy"

# - Default: 
RMS=""

# - Default: 
GROMACSver=""

# - Default: 
PYTHON="/public/home/damiano/Programs/miniconda3/bin/python"

# - Default: 
AWK="gawk"

# - Default: 
VMD="/public/home/damiano/Programs/bin/vmd"

# - Default: 
CHIMERA="/public/home/damiano/Programs/UCSF-Chimera64_1.16/bin"

# - Default: 
minim_NAME="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/SETUP_PROGRAM_FILES/minim_custom.mdp"

# - Default: 
SAMD_NAME="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/SETUP_PROGRAM_FILES/SAMD_custom.mdp"

# - Default: 
NVT_NAME="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/SETUP_PROGRAM_FILES/NVT_custom.mdp"

# - Default: 
NPT_NAME="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/SETUP_PROGRAM_FILES/NPT_custom.mdp"

# - Default: 
MD_EngComp_ff14sb_NAME="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/SETUP_PROGRAM_FILES/EngComp_ff14sb_custom.mdp"

# - Default: 
Protein_MD_EngComp_ff14sb_NAME="/public/home/damiano/BiSpecificAB/ABiSS_maturation2/RUN220/RUN1/SETUP_PROGRAM_FILES/Protein_EngComp_ff14sb_custom.mdp"

