#!/bin/bash

echo -e "\t > Starting_Values.sh"

# shellcheck disable=SC2154
# shellcheck disable=SC2034
function Starting_Values {
  #
  #############################
  ## >>> GROMACS TOOLS
  GROMACSver=
  # USE_EXPECT="false"    DEPRECATED
  # EXPECT="/bin/expect"  DEPRECATED

  #############################
  ## >>> SYSTEM VARIABLES
#  declare -a protein_ITPname=
#  declare -a nameCHAIN=
  tprFILE="system_Compl_MD"
  trjNAME="traj_MD"			; # [xtc]
  topName="topol"
  receptorFRAG="1"        # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< SYSTEM DEPENDENT
  ABchains="2"            # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< SYSTEM DEPENDENT

  #############################
  ## >>> BindingEnergy VARIABLES
  # List of the Energy function that will be printed in output. The last one will be used by Metropolis
  # 3: dG | 8: ScoreF | 9:ScoreF2 | 10: CanonicalAVG | 11: Median | 12: dG_2sigma
  EnergyFunction="3 12"

  average_all_frames="False"
  EnergyCalculation="gmxMMPBSA"	                      # GMXPBSA, Jmmpbsa, gmxMMPBSA
  GMXPBSApath="${ProgramPATH}/gmxpbsa-master"                 # (OLD) gmxpbsa program must be inside ABISS folder (PPATH)
  JerkwinPROGRAM="${ABiSS_LIB}/Jerkwin_mmpbsa.bsh"            # (OLD) Jerkwin_mmpbsa program must be inside ABISS_LIB
  CPATH="/usr/bin"				          	                        # I have nerver used "Coulomb" program
  APATH="findPATH"                                                          # Path to APBS (depends on the computer)
  GPATH="/home/iqb/anaconda3/pkgs/gromacs-4.6.7-0.1.0-py35_1/gromacs/bin"		# Path to gromacs4.7.6 for (OLD) gmxpbsa
  linearizedPB=
  precF="0"
  pdie="2"
  GMXPBSAminim="n"
  GMXPBSA_use_tpbcon=""
  GMXPBSA_NO_topol_ff=""
  NO_top_ff=""
  JerkwinPATH="${ABiSS_LIB}"                    # Jerkwin script must be inside ABiSS_LIB (${PPATH}/ABiSS_lib)
  trjconvOPT="-skip 100"		                    # only for Jerkwin_mmpbsa.bsh
  GsourcePATH="/usr/local/gromacs/bin/GMXRC"		# used on Jerkwin_mmpbsa
  mmpbsa_inFILE="mmpbsa_noLinearPB_amber99SB_ILDN.in"           # mmpbsa_noLinearPB_charmm.in

  #############################
  ## >>> PROGRAM SET-UP
#  declare -a TargetResidueList=
  SystemName="CXCR2"
  startingFrameGMXPBSA="500"    ; # Time of first frame to read [ps] when the xtc is prepared for GMXPBSA ( on MakeFiles_GMXPBSA -s with trjconv )
  NUMframe="all"							  ; # Number of frames (starting from the end of the simulation) on which the energy will be computed (default on 2ns -> 200) -almost computational costless-
  TotRunningNum="10"						; # Number of runs for the program: TotRunningNum="1" will run only one time every configuration
  RestartEnergy="no"
  ComputeOnlyEnergy="no"
  Stored_AVG="no"
  StartingMutant="0"
  MaxMutant="100"
  ForceFieldNUM="6"
  POSRES_RESIDUES=""
  # ResiduePool_list="ALA ARG ASN ASP GLN GLU ILE LYS PHE PRO SER THR VAL TRP TYR LEU MET GLY CYH CYS HID HIE HIP HIS"
  # ResiduePool_list="ALA ARG ASN ASP GLN GLU ILE LYS PHE PRO SER THR VAL"
  ResiduePool_list="ALA ARG ASN ASP GLN GLU ILE LYS PHE PRO SER THR VAL TRP TYR LEU MET"
  TargetChainName="H"
  #TargetResidueList_num="7"
  #TargetResidueList[1]="102"; TargetResidueList[2]="103"; TargetResidueList[3]="104"; TargetResidueList[4]="105"; TargetResidueList[5]="106"; TargetResidueList[6]="107"; TargetResidueList[7]="108";
  TargetResidueList_num="9"
  TargetResidueList[1]="100:H"; TargetResidueList[2]="101:H"; TargetResidueList[3]="102:H"; TargetResidueList[4]="103:H";
  TargetResidueList[5]="104:H"; TargetResidueList[6]="105:H"; TargetResidueList[7]="106:H"; TargetResidueList[8]="107:H";
  TargetResidueList[9]="108:H";
  editconf_opt="-d 1.4 -bt triclinic -c"; # -d 1 -bt cubic		# with 1.5 on every side I have a 3nm total distance

#  declare -a KEY_SA_time=
#  declare -a KEY_nsteps=
#  declare -a KEY_nstouts=
  POSRES="_posres"
  FAST=""
  KEY_pcoupl="Parrinello-Rahman"
  KEY_annealing="single"
  KEY_SA_npoints="4"
  KEY_SA_temp="10 380 380 80"
  KEY_SA_time[1]="0"; KEY_SA_time[2]="60"; KEY_SA_time[3]="70"; KEY_SA_time[4]="130";
  KEY_nsteps[1]="2000"					                                  # nsteps for minim
  (( KEY_nsteps[2]=KEY_SA_time[KEY_SA_npoints]*1000+20000 ))		  # [1fs] 150ps (time step 1fs) nsteps for SAMD
  KEY_nsteps[3]="50000"					                                  # 100ps nsteps for NVT
  KEY_nsteps[4]="75000"					                                  # 150ps nsteps for NPT
  KEY_nsteps[5]="750000"					                                # 1500ps nsteps for MD production
  KEY_nstouts[1]=""				 	                                      # (NOT USED) nstouts for minim
  ((KEY_nstouts[2]=KEY_nsteps[2]/10))			# nstouts for SAMD
  ((KEY_nstouts[3]=KEY_nsteps[3]/10))			# nstouts for NVT
  ((KEY_nstouts[4]=KEY_nsteps[4]/10))			# nstouts for NPT
  KEY_nstouts[5]="25000"					# 50ps nstouts for MD production -> 30 frames
  KEY_compressed="nstxtcout"   # this "command" changed name with the gromacs version
  DEBUG="false"
  KEY_define="KEY_"

  ## >>> METROPOLIS
  AcceptProb=
  Metropolis_Temp="4"

  ## >>> CLUSTER options
  cluster="no"
  NP="16"

#  ## >>> OTHER PROGRAMS PATHs
#  export VMD="findPATH"
#  export CHIMERA="findPATH"
}
