#Name of the system that is going to be run. (Default: CXCR2) - Default: CXCR2
SystemName=CXCR2
#Name (with no ext) of the tpr FILE used for the production MD and compute BE - Default: 
tprFILE=system_Compl_MD
#Name (with no ext) of the xtc FILE from production MD and used to compute BE - Default: 
trjNAME=traj_MD
#Name (with no ext) of the top FILE - Default: 
topName=topol
#Number of Fragment in the receptor (FIRST molecule in the starting pdb file) - Default: 
receptorFRAG="12"
#Number of Fragment in the antibody (SECOND molecule in the starting pdb file) - Default: 
ABchains="1"
#Use the merge interactive to make topology of the protein.If set to -merge, the mergeC, mergeR and mergeL must be set. - Default: 
mergeFragments=-merge
#Merge string for the Complex - Default: 
mergeC=y\nn\ny\nn\ny\nn\ny\nn\ny\nn\ny\nn\n
#Merge string for Receptor only - Default: 
mergeR=y\nn\ny\nn\ny\nn\ny\nn\ny\nn\ny\n
#Merge string for Ligand (antibody) only - Default: 
mergeL=
#List of the Energy function that will be printed in output. The last one will be used by Metropolis. 3: dG | 8: ScoreF | 9:ScoreF2 | 10: CanonicalAVG | 11: Median | 12: dG_2sigma - Default: 
EnergyFunction=3 12
#False-> the final energy is computed as average of the single cyclesTrue ->  - Default: 
average_all_frames=False
#If the program will run a fast test or not - Default: 
FAST=
#Method used to compute the BE. OPTs: GMXPBSA, Jmmpbsa, gmxMMPBSA - Default: 
EnergyCalculation=gmxMMPBSA
#gmxpbsa program inside ABISS folder (PPATH). DO NOT CHANGE - Default: 
GMXPBSApath=${ProgramPATH}/gmxpbsa-master
#Jerkwin program inside ABISS folder (PPATH). DO NOT CHANGE - Default: 
JerkwinPROGRAM=${ABiSS_LIB}/Jerkwin_mmpbsa.bsh
#(NEVER USED) path to the 'Coulomb' program - Default: 
CPATH=/usr/bin
#Path to the 'APBS' program - Default: 
APATH=findPATH
#Path to the 'Gromacs4.6.7' program - Default: 
GPATH=/home/iqb/anaconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/bin
#Used with GMXPBSA. '-l' to use APBS with linearize PB - Default: 
linearizedPB=
#Used with GMXPBSA. - Default: 
precF=0
#Used with GMXPBSA. - Default: 
pdie=2
#Used with GMXPBSA. 'y' if you want to run minim before BE calculations - Default: 
GMXPBSAminim=n
#Used with GMXPBSA. - Default: 
GMXPBSA_use_tpbcon=
#Used with GMXPBSA. - Default: 
GMXPBSA_NO_topol_ff=
#Path to Jerkwin program - Default: 
JerkwinPATH=${ABiSS_LIB}
#Used with Jerkwin. To set the option of trjconv. - Default: 
trjconvOPT=-skip 100
#Used with Jerkwin. Path to gromacs - Default: 
GsourcePATH=/usr/local/gromacs/bin/GMXRC
#Used with gmxMMPBSA. Pre-built input file to use. - Default: 
mmpbsa_inFILE=${ABiSS_LIB}/mmpbsa_noLinearPB_amber99SB_ILDN.in
#Time of first frame to read {ps} when the xtc is prepared to compute BE (Default: 500ps) - Default: 
startingFrameGMXPBSA=500
#Number of frames (starting from the last) on which the energy will be averaged (default: all) -almost computational costless- - Default: 
NUMframe=all
#Number of cycle per system. e.g. '1' will run only one time every configuration - Default: 
TotRunningNum=10
#'yes' if the program have to restart a previous calculations - Default: 
Restart_calculations=no
#Max number of mutation that will be attempted during the maturation - Default: 
MaxMutant=100
#Which ForceField to use for the MD and energy calculations - Default: 
ForceFieldNUM=6
#Residues that will be restraint during MD. Generally used with Cx - Default: 
POSRES_RESIDUES=
#Pool of residues from witch choose for the mutation - Default: 
ResiduePool_list=ALA ARG ASN ASP GLN GLU ILE LYS PHE PRO
#List of the antibody residues:chain that are allowed to be mutated - Default: 
TargetResidueList=29:H 30:H 31:H 74:H
#Option of editconf to be used when building the systemsNOTE that the long range interactions cut-off is set at 1.2nm - Default: 
editconf_opt=-d 1.2 -bt triclinic -c
#If position restraint will be used or not - Default: 
POSRES=_posres
#Pressure Coupling keyword to use during simulations - Default: 
KEY_pcoupl=Parrinello-Rahman
#Simulated annealing keyword to use during simulations - Default: 
KEY_annealing=single
#Number of points in the Simulated annealing simulations - Default: 
KEY_SA_npoints=4
#Temperatures in the Simulated annealing simulations - Default: 
KEY_SA_temp=10 380 380 80
#Time steps during the Simulated annealing simulations - Default: 
KEY_SA_time=0 60 70 130
# - Default: 
KEY_nsteps_minim=2000
# - Default: 
KEY_nsteps_SAMD=150000
# - Default: 
KEY_nsteps_NVT=50000
# - Default: 
KEY_nsteps_NPT=75000
# - Default: 
KEY_nsteps_MD=750000
# - Default: 
KEY_nstouts_SAMD=15000.0
# - Default: 
KEY_nstouts_NVT=5000.0
# - Default: 
KEY_nstouts_NPT=7500.0
# - Default: 
KEY_nstouts_MD=25000.0
# - Default: 
KEY_compressed=nstxtcout
# - Default: 
KEY_define=KEY_
#True-> Take into account the STD of results for the Metropolis algorithm - Default: 
metropolis_correction=True
#Use a different method to select the new residue type (Carol K. paper) - Default: 
keep_hydration=-kh
#This option will activate the 'cluster' starting variables - Default: 
cluster=no
#Number of OpenMP threads per MPI rank to start (-ntomp option on gmx mdrun) - Default: 
NP=4
#Path to the conda 'activate' program - Default: 
CONDA_activate_path=/home/iqb/anaconda3/bin/
#Name of the conda environment for gmxMMPBSA - Default: 
CONDA_gmxmmpbsa_name=gmxMMPBSA-1.6.1
#Name of the conda environment for modeller - Default: 
CONDA_modeller_name=modeller
#Random probability (that change every mutant) used by the metropolis algorith - Default: 
AcceptProb=
#Metropolis Temperature - Default: 
Metropolis_Temp=2
#Configuration from witch to start (or restart). 0->WT - Default: 
Starting_Configuration=0
#Stored Average BE from the last configuration. - Default: 
Stored_AVG=no
#Stored BE standard deviation from the last configuration. - Default: 
Stored_STD=no
