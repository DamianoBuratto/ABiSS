#!/bin/bash

##########################################################################
# Title      :	namd_config - part of the ABiSM program
# Author     :	Damiano Buratto dburatto@shanghaitech.edu.cn
# Date       :	2018 Jan 29
# Requires   :	
# Category   :	
# Version    :	1.0 (2018 Jan 30)
##########################################################################
# Description
#    o	
#	
#	
#	
#    o	
#	
#	
#	
# Examples:
#	namd_config.sh FileName.psf FileName.pdb
#	
#	
##########################################################################

PN=`basename "$0"`			# Program name
Ppath=`dirname "$0"`			# Program path
VER='1.0'

#embedding the library file script functions.sh
. $Ppath/functions.sh

usage () {
    echo -e >&2 "\n$PN - namd_config - $VER\n
usage: $PN -psf <psffile> -pdb <pdbfile> [OPTIONS]
    -psf <PSFfile>:	[only with CHARMM ff] Insert the file .psf to use fo the in silico computation
    -pdb <PDBfile>:	Insert the file .pdf to use fo the in silico computation
    -top <FileNameTOP>:	[only with AMBER ff] Insert the parameter AMBER file.
    OPTIONS:
    -s  <SimulType>:	Insert the type of simulation that the .conf will run (Default: minim). Options are: 
    			   minim	->	simple minimization ad short MD run
    			   MD		->	long MD simulation
    			   GBIS		->	Generalized Born Implicit Solvent simulation
    			   ENG		->	Compute the energy on vacuum
    			   restart	->	restart the simulation (not available yet)
    -ff <ForceField>:	Set the ForceField (AMBER or CHARMM), that will be use for the simulation (Default: CHARMM).
    -in <inputname>	REQUIRED only with restart. Its the name of the old simulation.
    -d  <dcdList>	REQUIRED only with GBIS option. It is a list of the trajectories that have to be analyzed (Default: *MD.dcd)
    -c  <ConfigName>:	Insert the name of the NAMD configuration file (Default: <SimulationType>)
    -o  <FileNameOUT>:	Insert the name of the output of NAMD simulation (Default: confout)
    -t  <Temperature>:	Insert the temperature [kelvin] (Default: 300)
    -p  <Parameter>:	[only with CHARMM] Insert the CHARMM parameter to use (Default: par_all27_prot_lipid.inp)
    -m  <minimSteps>:	Number of steps during the minimization. It works ONLY for \"minim\" simulation type (Default: 500)
    -n  <MD-Steps>:	Number of steps during the MD (Default: 50000(minim) | 5000000(MD & restart) | always 0 for GBIS )
    -gs <GIBS_start>:	Starting frame for the GBIS energy calculations. It is REQUIRED for GBIS and optional for MD.
    -f  <restartfreq> <dcdfreq> <xstFreq> <outputEnergies> <outputPressure>:	
    			Parameters...
    -sa <sasa_opt>	Onlt with GBIS option. Set sasa energy calculation 'on' or 'off'. (Default: on)
    -st <surfTension>:	REQUIRED only with GBIS option. Surface tension used when calculating hydrophobic SASA energy [kcal/mol/A^2]. (Defalut: 0.00542)
    -ic <ionConcentr>:	REQUIRED only with GBIS option. Ion concentration during Generalized Born Implicit Solvent simulation [Molar]. (Default: 0.15)
    -pv <PathVMD>:	Insert the custom path for vmd program (Default on \$PATH)
    -q  <QueueName>:	Insert the name of the queue system (Torque | ). If no queue is used, set it to 'no' (Default: no).
    -v:			(verbose) Be loud and noisy (Default: off) NOT IMPLEMENTED YET
    -h:			(help)    Print this help
    "
    exit 1
}

OptionsUSED="$@"		#; msg "$OptionsUSED";

minimize=
run=
VMD=
Queue=
GIBS_start=
sasa_opt="on"

restartfreq=
dcdfreq=
xstFreq=
outputEnergies=
outputPressure=

surfaceTension=
ionConcentration=

ForceField="CHARMM"
TempK="300"
declare -a FileNameCHARMMpar=
NumberParCHARMM="1"
FileNameOUT="confout"
SimulationType="minim"
FileNameTOP=
FileNamePSF=
FileNamePDB=
ConfNAME=
dcdList=
dcdNum="0"
Verbose="off"

FileNameCHARMMpar[1]="par_all27_prot_lipid.inp"
[ $# -lt 4 ] && { msg "ERROR: 2 mandatory FILEs"; usage; }
while [ $# -gt 0 ]
do
    case "$1" in
	-psf)	shift; FileNamePSF=$1;;
	-pdb)	shift; FileNamePDB=$1;;
	-top)	shift; FileNameTOP=$1;;
	 # I want to inser 1 array (that may work with *dcd)
	-d)	shift; while [[ $1 != -* ]]; do [ $# -gt 0 ] || break; ((dcdNum+=1)); dcdList[$dcdNum]=$1
		#msg "dcdNum= $dcdNum   dcdList[$dcdNum]=${dcdList[$dcdNum]}"
		shift; done
		[ $dcdNum -eq 0 ] && fatal 11 "ERROR: expected a list of name (at least 1) after \"-d\"\n"
		continue;;
	-t)	shift; TempK=$1;;
	-ff)	shift; ForceField=$1;;
	-p)	shift; NumberParCHARMM="0";
		while [[ $1 != -* ]]; do 
			((NumberParCHARMM+=1)); FileNameCHARMMpar[$NumberParCHARMM]=$1
			shift; [ $# -gt 0 ] || break
		done
		[ $NumberParCHARMM -eq 0 ] && fatal 12 "Ther must be a list of value (at least 1) after \"-p\"\n"
		continue;;
	-s)	shift; SimulationType=$1;;
	-c)	shift; ConfNAME=$1;;
	-in)	shift; inputname=$1;;
	-o)	shift; FileNameOUT=$1;;
	-m)	shift; minimize=$1;;
	-n)	shift; run=$1;;
	-gs)	shift; GIBS_start=$1;;
	-f)	shift; restartfreq=$1; dcdfreq=$2; xstFreq=$3; outputEnergies=$4; outputPressure=$5; shift; shift; shift; shift;;	#I should add controls for the inputs
	-sa)	shift; sasa_opt=$1;;
	-st)	shift; surfaceTension=$1;;
	-ic)	shift; ionConcentration=$1;;
	-pv)	shift; VMD=$1;;
	-q)	shift; Queue=$1;;
	-h)	usage;;
	-v)	Verbose="on";;
	*)	fatal 13 "ERROR: $1 is not a valid OPTION! Type $PN -h for usage information\n";;			
    esac
    shift
done
#INPUT check!!
[ -z "$ConfNAME" ] && ConfNAME=$SimulationType
[ "$Queue" = "" ] && Queue="no"
if [ $SimulationType == "GBIS" ] || [ $SimulationType == "ENG" ]; then
	if [ $SimulationType == "GBIS" ] && [ $sasa_opt != "on" ] && [ $sasa_opt != "off" ]; then 
		msg "'sasa_opt' must be on or off!! AUTOMATICALY set it on default value (on)"
		sasa_opt="on"
	fi
	[ -z "${dcdList[1]}" ] && { 	for i in `ls *MD.dcd 2> /dev/null`; do ((dcdNum+=1)); dcdList[$dcdNum]=$i; msg "--dcdNum= $dcdNum   dcdList[]=${dcdList[$dcdNum]}"; done
				[ $dcdNum -eq 0 ] && fatal 21 "ERROR: I cannot find any trajectory *MD.dcd \n"; }
fi
if [ $ForceField == "CHARMM" ]; then
	[ -z "$FileNamePSF" ] && fatal 22 "the parameter -psf MUST be set!! \n" 
	[ -z "$FileNamePDB" ] && fatal 23 "the parameter -pdb MUST be set!! \n"
elif [ $ForceField == "AMBER" ]; then 
	[ -z "$FileNameTOP" ] && fatal 24 "the parameter -top MUST be set!! \n" 
else
	fatal 28 "ERROR: $ForceField is not a valid ForceField! Type $PN -h for usage information\n"
fi



# 	** get rid of the extensions, if they have one **
pathPSF="`readlink -f $FileNamePSF`"						# I want the file with the whole path, and then I will strip off the name of the file
pathPSF="${pathPSF%/*}/"							# ${string%substring}  ->  Deletes shortest match of $substring from back of $string.
FileNamePSF="${FileNamePSF##*/}"						# ${string##substring}  ->  Deletes longest match of $substring from front (beginning) of $string.
FileNamePSF="${FileNamePSF%.psf}"		

pathPDB="`readlink -f $FileNamePDB`"
pathPDB="${pathPDB%/*}/"
FileNamePDB="${FileNamePDB##*/}"
FileNamePDB="${FileNamePDB%.pdb}"

#echo -e "\n\nFileNameTOP: $FileNameTOP\t"
pathTOP="`readlink -f $FileNameTOP`"						
pathTOP="${pathTOP%/*}/"							
FileNameTOP="${FileNameTOP##*/}"						
FileNameTOP="${FileNameTOP%.top}"
#echo -e "pathTOP: $pathTOP \t FileNameTOP: $FileNameTOP\n"

#	** Check for vmd start file **
if [ "$VMD" == "" ]; then
	VMD=`which vmd`
	if [ "$VMD" != "" ]; then
		msg "--vmd program found on -> $VMD"
	else
		fatal 29 "Cannot find any vmd program in the \$PATH!!"
	fi
fi

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#@ 	Starting vmd to compute the box-size of the system			@#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

if [ "$SimulationType" != "GBIS" ]; then
	msg "\n--computing the box size..."
	VMD_function -pdb "${pathPDB}${FileNamePDB}" -t "BOX"

	centerX=$( awk '$1 ~ /centerX:/ {printf "%-7.2f", $2}' ${TEMP_FILES_FOLDER}/measure_box.temp )
	centerY=$( awk '$1 ~ /centerY:/ {printf "%-7.2f", $2}' ${TEMP_FILES_FOLDER}/measure_box.temp )
	centerZ=$( awk '$1 ~ /centerZ:/ {printf "%-7.2f", $2}' ${TEMP_FILES_FOLDER}/measure_box.temp )
	vectorX=$( awk '$1 ~ /min-maxX/ {r=$3-$2; printf "%-7.2f", r}' ${TEMP_FILES_FOLDER}/measure_box.temp )
	vectorY=$( awk '$1 ~ /min-maxY/ {r=$3-$2; printf "%-7.2f", r}' ${TEMP_FILES_FOLDER}/measure_box.temp )
	vectorZ=$( awk '$1 ~ /min-maxZ/ {r=$3-$2; printf "%-7.2f", r}' ${TEMP_FILES_FOLDER}/measure_box.temp )
fi

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#@ 	Starting to write the common part of the .conf file			@#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

msg "--initializing the .conf file..."
echo > $ConfNAME \
"#############################################################
## JOB DESCRIPTION                                         ##
#############################################################

# NAMD configuration file build with $PN
# Options: $OptionsUSED

#############################################################
## ADJUSTABLE PARAMETERS                                   ##
#############################################################

set temperature		$TempK
set outputname		$FileNameOUT

firsttimestep		0

#############################################################
## SIMULATION PARAMETERS                                   ##
#############################################################

# Input

coordinates		${pathPDB}${FileNamePDB}.pdb"
if [ $ForceField == "CHARMM" ]; then
	echo -n -e >> $ConfNAME \
	"\nstructure		${pathPSF}${FileNamePSF}.psf
	\nparaTypeCharmm		on"
	for _Num in `seq 1 $NumberParCHARMM`; do
		echo -n -e >> $ConfNAME \
		"\nparameters		${FileNameCHARMMpar[$_Num]}"
	done
else 
	echo -n -e >> $ConfNAME \
	"\namber			on\
	\nparmfile		${pathTOP}${FileNameTOP}.top
	"
fi


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#@ 	Starting to write the different part of the .conf file			@#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

case "$SimulationType" in
	#@@@@@@@@@@@@@@@@@@@@@@@@@
	#@	minim type	@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@
	minim)	[ -z "$restartfreq" ] && { restartfreq="10000"; dcdfreq="10000"; xstFreq="5000" outputEnergies="2500"; outputPressure="2500"; }	# default values
		[ -z "$minimize" ] && { minimize="500"; }
		[ -z "$run" ] && { run="50000"; }
		msg "--writing the .conf file for a minim simulation..."; echo -n >> $ConfNAME \
"
temperature		\$temperature
mergeCrossterms		yes


# Constant Temperature Control
langevin		on    			;# do langevin dynamics
langevinDamping		1     			;# damping coefficient (gamma) of 1/ps
langevinTemp		\$temperature
langevinHydrogen	off    			;# don't couple langevin bath to hydrogens


# Constant Pressure Control (variable volume)
useGroupPressure	yes 			;# needed for rigidBonds
useFlexibleCell		no
useConstantArea		no

langevinPiston		on
langevinPistonTarget	1.01325 		;#  in bar -> 1 atm
langevinPistonPeriod	100.0
langevinPistonDecay	50.0
langevinPistonTemp	\$temperature

# Periodic Boundary Conditions
cellBasisVector1	$vectorX 0.0     0.0
cellBasisVector2	0.0     $vectorY 0.0
cellBasisVector3	0.0     0.0     $vectorZ
cellOrigin		$centerX $centerY $centerZ

wrapAll			on


# Integrator Parameters
timestep		2.0  			;# 2fs/step
rigidBonds		all  			;# needed for 2fs steps
nonbondedFreq		1
fullElectFrequency	2  
stepspercycle		10


# PME (for full-system periodic electrostatics)
PME			yes
PMEGridSpacing		1.0

#manual grid definition
#PMEGridSizeX		45
#PMEGridSizeY		45
#PMEGridSizeZ		48


# Force-Field Parameters
exclude			scaled1-4
1-4scaling		1.0
cutoff			12.0
switching		on
switchdist		10.0
pairlistdist		14.0


# Output
outputName		\$outputname
# restartname		\$outputname		;# (def: outputName.restart)
# DCDfile		\$outputname		;# the binary dcd position coordinate trajectory file (def: outputName.dcd)


restartfreq		$restartfreq     		;# 10000steps = every 20ps
dcdfreq			$dcdfreq
xstFreq			$xstFreq
outputEnergies		$outputEnergies			;# how often NAMD output the current energy values to stdout
outputPressure		$outputPressure

# to avoid the blowup for box shrink
margin 			3

#############################################################
## EXTRA PARAMETERS                                        ##
#############################################################

# Put here any custom parameters that are specific to 
# this job (e.g., SMD, TclForces, etc...)

#############################################################
## EXECUTION SCRIPT                                        ##
#############################################################

# Minimization
minimize		$minimize
reinitvels		\$temperature

run			$run 			;# fs";;
#ENDTEXT
	#@@@@@@@@@@@@@@@@@@@@@@@@@
	#@	MD type		@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@
	MD)	[ -z "$restartfreq" ] && { restartfreq="50000"; dcdfreq="50000"; xstFreq="5000" outputEnergies="25000"; outputPressure="25000"; }	# default values
		[ -z "$run" ] && { run="5000000"; }
		msg "--writing the .conf file for a MD simulation..."; echo >> $ConfNAME \
"
temperature		\$temperature


# Constant Temperature Control
langevin		on    			;# do langevin dynamics
langevinDamping		1     			;# damping coefficient (gamma) of 1/ps
langevinTemp		\$temperature
langevinHydrogen	off    			;# don't couple langevin bath to hydrogens


# Constant Pressure Control (variable volume)
useGroupPressure	yes 			;# needed for rigidBonds
useFlexibleCell		no
useConstantArea		no

langevinPiston		on
langevinPistonTarget	1.01325 		;#  in bar -> 1 atm
langevinPistonPeriod	100.0
langevinPistonDecay	50.0
langevinPistonTemp	\$temperature

# Periodic Boundary conditions
cellBasisVector1	$vectorX 0.0     0.0
cellBasisVector2	0.0     $vectorY 0.0
cellBasisVector3	0.0     0.0     $vectorZ
cellOrigin		$centerX $centerY $centerZ

wrapAll			on


# Integrator Parameters
timestep		2.0  			;# 2fs/step
rigidBonds		all  			;# needed for 2fs steps
nonbondedFreq		1
fullElectFrequency	2  
stepspercycle		10


# PME (for full-system periodic electrostatics)
PME			yes
PMEGridSpacing		1.0

#manual grid definition
#PMEGridSizeX		45
#PMEGridSizeY		45
#PMEGridSizeZ		48


# Force-Field Parameters
exclude			scaled1-4
1-4scaling		1.0
cutoff			12.0
switching		on
switchdist		10.0
pairlistdist		14.0


# Output
outputName		\$outputname
# restartname		\$outputname		;# (def: outputName.restart)
# DCDfile		\$outputname		;# the binary dcd position coordinate trajectory file (def: outputName.dcd)


restartfreq		$restartfreq     		;# 10000steps = every 20ps
dcdfreq			$dcdfreq
xstFreq			$xstFreq
outputEnergies		$outputEnergies			;# how often NAMD output the current energy values to stdout
outputPressure		$outputPressure


#############################################################
## EXTRA PARAMETERS                                        ##
#############################################################

# Put here any custom parameters that are specific to 
# this job (e.g., SMD, TclForces, etc...)

#############################################################
## EXECUTION SCRIPT                                        ##
#############################################################

"
if ! [ -z "$GIBS_start" ]; then
	msg "-- MD with minimization --"
	echo >> $ConfNAME \
"# Minimization
minimize		500
"

fi

	echo >> $ConfNAME \
"
reinitvels		\$temperature
run			$run 		;# 2ns";;	

	#@@@@@@@@@@@@@@@@@@@@@@@@@
	#@	GBIS type	@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@
	GBIS)	[ -z "$restartfreq" ] && { restartfreq="500"; dcdfreq="500"; xstFreq="250" outputEnergies="100"; outputPressure="100"; }	# default values
		[ -z "$surfaceTension" ] && { surfaceTension="0.00542"; }	# default values
		[ -z "$ionConcentration" ] && { ionConcentration="0.15"; }	# default values
		[ -z "$run" ] && { run="0"; }				
		msg "--writing the .conf file for a GBIS simulation..."; echo >> $ConfNAME \
"
temperature		\$temperature


# implicit solvent
gbis 			on
solventDielectric 	78.5
ionConcentration 	$ionConcentration
alphaCutoff 		15
sasa 			$sasa_opt		;# SASA does not yet support periodic boundary conditions.
surfaceTension 		$surfaceTension		;# 0.00542


# Constant Temperature Control
langevin		on    			;# do langevin dynamics
langevinDamping		1     			;# damping coefficient (gamma) of 1/ps
langevinTemp		\$temperature
langevinHydrogen	off    			;# don't couple langevin bath to hydrogens


# Constant Pressure Control (variable volume)
# Not used on GBIS tutorial
# useGroupPressure	yes 			;# needed for rigidBonds
# useFlexibleCell		no
# useConstantArea		no

# langevinPiston		on
# langevinPistonTarget	1.01325 		;#  in bar -> 1 atm
# langevinPistonPeriod	100.0
# langevinPistonDecay	50.0
# langevinPistonTemp	\$temperature


# Integrator Parameters
timestep		2.0  			;# 2fs/step
rigidBonds		all  			;# needed for 2fs steps
nonbondedFreq		1
fullElectFrequency	2  
stepspercycle		10


# PME (for full-system periodic electrostatics)
PME			no			;# user's should not use PME (because it is not compatible with GBIS)


# Force-Field Parameters
exclude			scaled1-4		;# user's can choose any value for exclude without affecting GBIS
1-4scaling		1.0
switching		on
switchdist		15.0
cutoff			16.0
pairlistdist		18.0


# Output
outputName		\$outputname

restartfreq		$restartfreq     		
dcdfreq			$dcdfreq
xstFreq			$xstFreq
outputEnergies		$outputEnergies			;# how often NAMD output the current energy values to stdout
outputPressure		$outputPressure

#############################################################
## EXTRA PARAMETERS                                        ##
#############################################################

# Put here any custom parameters that are specific to 
# this job (e.g., SMD, TclForces, etc...)

#############################################################
## EXECUTION SCRIPT                                        ##
#############################################################

set ts 			$GIBS_start			;# ts = time step
set dcdList [list ${dcdList[@]}]
foreach dcd \$dcdList {
	coorfile open dcd \$dcd
	while { ![coorfile read] } {
		firsttimestep \$ts
		run 0				;# You can \"run 0\" just to get energies
		incr ts $dcdfreq		;# This value MUST be equal to the dcd frequency of MD used to make the trj 
	}
	coorfile close
} 
";;	

	#@@@@@@@@@@@@@@@@@@@@@@@@@
	#@	ENERGY type	@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@
	ENG)	[ -z "$restartfreq" ] && { restartfreq="500"; dcdfreq="500"; xstFreq="250" outputEnergies="100"; outputPressure="100"; }	# default values
		[ -z "$run" ] && { run="0"; }				
		msg "--writing the .conf file for a GBIS simulation..."; echo >> $ConfNAME \
"
temperature		\$temperature

# Constant Temperature Control
langevin		on    			;# do langevin dynamics
langevinDamping		1     			;# damping coefficient (gamma) of 1/ps
langevinTemp		\$temperature
langevinHydrogen	off    			;# don't couple langevin bath to hydrogens


# Constant Pressure Control (variable volume)
# Not used on GBIS tutorial
# useGroupPressure	yes 			;# needed for rigidBonds
# useFlexibleCell		no
# useConstantArea		no

# langevinPiston		on
# langevinPistonTarget	1.01325 		;#  in bar -> 1 atm
# langevinPistonPeriod	100.0
# langevinPistonDecay	50.0
# langevinPistonTemp	\$temperature


# Integrator Parameters
timestep		2.0  			;# 2fs/step
rigidBonds		all  			;# needed for 2fs steps
nonbondedFreq		1
fullElectFrequency	2  
stepspercycle		10


# PME (for full-system periodic electrostatics)
PME			no			;# user's should not use PME (because it is not compatible with GBIS)


# Force-Field Parameters
exclude			scaled1-4		;# user's can choose any value for exclude without affecting GBIS
1-4scaling		1.0
switching		on
switchdist		15.0
cutoff			16.0
pairlistdist		18.0


# Output
outputName		\$outputname

restartfreq		$restartfreq     		
dcdfreq			$dcdfreq
xstFreq			$xstFreq
outputEnergies		$outputEnergies			;# how often NAMD output the current energy values to stdout
outputPressure		$outputPressure

#############################################################
## EXTRA PARAMETERS                                        ##
#############################################################

# Put here any custom parameters that are specific to 
# this job (e.g., SMD, TclForces, etc...)

#############################################################
## EXECUTION SCRIPT                                        ##
#############################################################

set ts 			$GIBS_start			;# ts = time step
set dcdList [list ${dcdList[@]}]
foreach dcd \$dcdList {
	coorfile open dcd \$dcd
	while { ![coorfile read] } {
		firsttimestep \$ts
		run 0				;# You can \"run 0\" just to get energies
		incr ts $dcdfreq		;# This value MUST be equal to the dcd frequency of MD used to make the trj 
	}
	coorfile close
} 
";;
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	#@	restart type		@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	restart)	[ -z "$restartfreq" ] && { restartfreq="50000"; dcdfreq="50000"; xstFreq="5000" outputEnergies="25000"; outputPressure="25000"; }	# default values
			[ -z "$run" ] && { run="5000000"; }
			msg "--writing the .conf file for restart a simulation..."; echo >> $ConfNAME \
"
# temperature		\$temperature

# Continuing a job from the restart files
set inputname      ${inputname}
binCoordinates     \$inputname.restart.coor
binVelocities      \$inputname.restart.vel  	;# remove the \"temperature\" entry if you use this!
extendedSystem	   \$inputname.restart.xsc


# Constant Temperature Control
langevin		on    			;# do langevin dynamics
langevinDamping		1     			;# damping coefficient (gamma) of 1/ps
langevinTemp		\$temperature
langevinHydrogen	off    			;# don't couple langevin bath to hydrogens


# Constant Pressure Control (variable volume)
useGroupPressure	yes 			;# needed for rigidBonds
useFlexibleCell		no
useConstantArea		no

langevinPiston		on
langevinPistonTarget	1.01325 		;#  in bar -> 1 atm
langevinPistonPeriod	100.0
langevinPistonDecay	50.0
langevinPistonTemp	\$temperature

# Periodic Boundary conditions
# NOTE: Do not set the periodic cell basis if you have also 
# specified an .xsc restart file!
# cellBasisVector1	$vectorX 0.0     0.0
# cellBasisVector2	0.0     $vectorY 0.0
# cellBasisVector3	0.0     0.0     $vectorZ
# cellOrigin		$centerX $centerY $centerZ

wrapAll			on


# Integrator Parameters
timestep		2.0  			;# 2fs/step
rigidBonds		all  			;# needed for 2fs steps
nonbondedFreq		1
fullElectFrequency	2  
stepspercycle		10


# PME (for full-system periodic electrostatics)
PME			yes
PMEGridSpacing		1.0

#manual grid definition
#PMEGridSizeX		45
#PMEGridSizeY		45
#PMEGridSizeZ		48


# Force-Field Parameters
exclude			scaled1-4
1-4scaling		1.0
cutoff			12.0
switching		on
switchdist		10.0
pairlistdist		14.0


# Output
outputName		\$outputname

restartfreq		$restartfreq   		;# 100000steps = every 200ps
dcdfreq			$dcdfreq
xstFreq			$xstFreq
outputEnergies		$outputEnergies		;# how often NAMD output the current energy values to stdout
outputPressure		$outputPressure


#############################################################
## EXTRA PARAMETERS                                        ##
#############################################################

# Put here any custom parameters that are specific to 
# this job (e.g., SMD, TclForces, etc...)

#############################################################
## EXECUTION SCRIPT                                        ##
#############################################################

reinitvels		\$temperature

run			$run 		;# 10ns";;	
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	#@	unidentified type	@#
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	*)	fatal 31 "ERROR: $SimulationType is not a valid simulation type! Check the help menu\n"; rm $ConfNAME;;			# First file name
esac
msg "--DONE\n"



