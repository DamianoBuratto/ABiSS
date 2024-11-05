#!/bin/bash

echo -e "\t > VMD_function.sh"



VMD_function () {
#################################################################################################################################################################
# usage: VMD_function -psf <$psffile> -pdb <$pdbfile> -s <ServiceType> [OPTIONS]										#
#     -pv  <PathVMD>:		Insert the path for vmd program													#
#     -psf <PSFfile>:		[not necessary on BOX ServiceType] Insert the structure file .psf that will be used as starting configuration.			#
#     -pdb <PDBfile>:		Insert the coordinate file .pdf that will be used as starting configuration.							#
#     -t   <ServiceType>:	Insert the type of service that vmd will perform. Options are: 									#
# 	     BOX	->	print a file with the box dimensions.												#
# 	     LAST	->	print the last $n (.pdb) configurations from a trajectory.									#
# 	     SEL	->	print a new trajectory (dcd) and the first frame (pdb and psf) with only the selection.						#
# 	     RNAME	->	print the name of a (or a list of) selected residue in standard output following the key word 'NAME_RESIDUE_SEARCHED:'		#
# 	     MUT	->	start the tcl program "mutator"													#
# 	     SOL	->	solvate the system														#
#     OPTIONS:																			#
#     -n   <ConfigNum>:		used with "LAST" ServiceType. Number of configurations that will be extracted from the (end of) trajectory (Default: 1)		#
#     -dcd <dcdFile>:		REQUIRED with "LAST" and "SEL" ServiceType. It is the trajectory file.								#
#     -s   <Selections>:	REQUIRED with "SEL" ServiceType. It is the list of Selections that will be extracted.						#
#     -m   <SelectName>:	REQUIRED with "SEL" ServiceType. It is the list of Name of the Selections that will be extracted.				#
#     -ri  <ResID>:		REQUIRED with "RNAME" and "MUTATE" ServiceType. It is the ID number of the residue you are looking for.				#
#				  It may be a vector list ONLY with RNAME option.										#
#     -sn  <SegName>:		REQUIRED with "RNAME" and "MUTATE" ServiceType. It is the name of the segment where the residue is located.			#
#     -cn  <ChainName>:		REQUIRED with "RNAME" 														#
#     -rm  <ResMutation>:	REQUIRED with "MUTATE" ServiceType. It is the name of the new residue.								#
#     -o   <OutputName>:	used with "MUTATE" ServiceType. It is the name of the .pdb and .psf output. (optional for other options)			#
#################################################################################################################################################################
	local _FileNamePSF=
	local _pathPSF=
	local _FileNamePDB=
	local _pathPDB=
	local _FileNameDCD=
	local _ServiceType=
	#local _Selection=
	declare -a _Selection=		# When used in a function, declare makes each name local, as with the local command, unless the -g option is used.
	declare -a _SelectName=
	local _SelectNUM="0"
	local _ConfigNum="1"
	local _ResID=
	local _SegName=
	local _ChainName=
	local _VMD="$VMD"

	local _ResMutation=
	local _OutputName=

	# msg "VMD_function $@"
	while [ $# -gt 0 ]
	do
	    case "$1" in
	    	-pv)	shift; _VMD=$1;;
#	    	-l)	shift; _libPATH=$1;;
		    -psf)	shift; _FileNamePSF=$1;;
		    -pdb)	shift; _FileNamePDB=$1;;
        -dcd)	shift; _FileNameDCD=$1;;
        -n)	shift; _ConfigNum=$1;;
        -t)	shift; _ServiceType=$1;;
        -s)	shift; _SelectNUM="0"		# there must be at least 1 element
          while [[ $1 != -* ]]; do
            ((_SelectNUM+=1)); _Selection[$_SelectNUM]=$1
            # msg "SelectNum= $_SelectNUM _Selection[$_SelectNUM]=${_Selection[$_SelectNUM]}"
            shift; [ $# -gt 0 ] || break
          done
          [ "$_SelectNUM" -eq 0 ] && fatal 1 "VMD_function () ERROR: a list of value (at least 1) after \"-s\"\n"
          continue;;
        -m)	shift; _SelectNUM="0"		# there must be at least 1 element
          while [[ $1 != -* ]]; do
            ((_SelectNUM+=1)); _SelectName[$_SelectNUM]=$1
            # msg "SelectNum= $_SelectNUM _SelectName[$_SelectNUM]=${_SelectName[$_SelectNUM]}"
            shift; [ $# -gt 0 ] || break
          done
          [ "$_SelectNUM" -eq 0 ] && fatal 1 "VMD_function () ERROR: expect a list of name (at least 1) after \"-m\"\n"
          continue;;
        -ri)	shift; _ResID="$1"; shift; [ $# -gt 0 ] || break
          while [[ $1 != -* ]]; do
            _ResID="$_ResID $1";
            #echo "_ResID: $_ResID"
            shift; [ $# -gt 0 ] || break
          done
          continue;;
        -sn)	shift; _SegName=$1;;
        -cn)	shift; _ChainName=$1;;
        -rm)	shift; _ResMutation=$1;;
        -o)	shift; _OutputName=$1;;
        *)	fatal 1 "VMD_function () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done

	if ! [ -x "$(which "$_VMD")" ]; then
	  msg "(VMD='$_VMD') Searching for vmd.."
		_VMD="$(which vmd)"
		if [ "$_VMD" != "" ]; then
			msg "VMD_function() : vmd program found on -> $_VMD" >&2
		else
			fatal 11 "Cannot find any vmd program in the \$PATH!! (VMD->$_VMD) Please install it or specify a custom path."
		fi
	fi

	# check the variables that must be set on the main program
	[ "$Env" == "" ] && [ "$_ServiceType" == "" ] && fatal 3 "ERROR VMD_function (MUT): the variable 'Env' ($Env) must be set in the main program!!"

	# if _OutputName is not set, put it equal to _FileNameDCD
	[ "$_OutputName" == "" ] && _OutputName=$_FileNameDCD

	# there must be a folder for temporary files
#	mkdir -p TEMP_FILES_FOLDER

	if ! [ -z "$_FileNamePSF" ]; then
		#[ $_ServiceType != "BOX" ] && fatal 1 "VMD_function () ERROR: The parameter -psf MUST be set!\n"
		_pathPSF=$(dirname "$_FileNamePSF")
		_FileNamePSF=$(basename "$_FileNamePSF")
		#echo -e "\t _FileNamePSF->$_FileNamePSF _FileNamePDB->$_FileNamePDB _FileNameDCD->$_FileNameDCD _ConfigNum->$_ConfigNum _ServiceType->$_ServiceType _SelectNUM->$_SelectNUM _ResID->$_ResID _SegName->$_SegName _ResMutation->$_ResMutation _OutputName->$_OutputName"
	fi
	_pathPDB=$(dirname "$_FileNamePDB")
	_FileNamePDB=$(basename "$_FileNamePDB")

	case "$_ServiceType" in
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	extract the box size	@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		BOX)	echo -n -e > "${TEMP_FILES_FOLDER}"/vmd"${_ServiceType}".temp "\
				\nmol load pdb ${_pathPDB}/${_FileNamePDB}.pdb\
				\nset outfile [open ${TEMP_FILES_FOLDER}/measure_box.temp w]\
				\nset everyone [atomselect top all]\
				\nset CENTER [measure center \$everyone]\
				\nputs \$outfile \"centerX: [lindex \$CENTER 0] \ncenterY: [lindex \$CENTER 1] \ncenterZ: [lindex \$CENTER 2]\"\
				\nset BOX [measure minmax \$everyone]\
				\nputs \$outfile \"min-maxX: [lindex [lindex \$BOX 0] 0] [lindex [lindex \$BOX 1] 0]\"\
				\nputs \$outfile \"min-maxY: [lindex [lindex \$BOX 0] 1] [lindex [lindex \$BOX 1] 1]\"\
				\nputs \$outfile \"min-maxZ: [lindex [lindex \$BOX 0] 2] [lindex [lindex \$BOX 1] 2]\"\
				\nclose \$outfile\
				\nexit\
			"
			;;

		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	extract the last frame and save a new pdb	@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		LAST)	[ -z "${_FileNameDCD}" ] && fatal 3 "To run VMD_function -t LAST, the option -dcd is MANDATORY!"
			if [ $ForceField == "CHARMM" ]; then
				echo -n -e > ${TEMP_FILES_FOLDER}/vmd${_ServiceType}.temp "\
					\npackage require psfgen
					\nreadpsf ${_pathPSF}/${_FileNamePSF}.psf\
					\ncoordpdb ${_pathPDB}/${_FileNamePDB}.pdb
				"
			fi
			echo -n -e >> ${TEMP_FILES_FOLDER}/vmd${_ServiceType}.temp "\
				\npackage require pbctools\
				\n#mol new ${_pathPSF}/${_FileNamePSF}.psf waitfor all\
				\nmol new ${_pathPDB}/${_FileNamePDB}.pdb waitfor all\
				\nmol addfile ${_FileNameDCD}.dcd waitfor all\
				\npbc unwrap\
				\nsource $fitframes\
				\nfitframes top \"chain A B C\"
				\nputs -nonewline \"current frame: \"
				\nset FrameNow [expr [molinfo top get numframes]-1]\
				\nputs -nonewline \"Configurations desired: \"
				\nset CountFrame $_ConfigNum\
				\nset Count_mol 1\

				\nsource $autopsf\
				\nset env(SOLVATEDIR) $Env\

				\nif { \${CountFrame}==0 } {\
				\n	set nLastFrame [atomselect 0 \"all\" frame \$FrameNow] \
				\n	\$nLastFrame writepdb ${_FileNameDCD}_last_F\${CountFrame}.pdb \
				\n	writepsf ${_FileNameDCD}_last_F\${CountFrame}.psf \
				\n	exit
				\n}

				\nwhile { \$FrameNow > 0 } { \
				\n	set nLastFrame [atomselect 0 \"not water and not ion\" frame \$FrameNow] \
				\n	\$nLastFrame writepdb ${_FileNameDCD}_last_F\${CountFrame}.pdb \
				\n	\$nLastFrame writepsf ${_FileNameDCD}_last_F\${CountFrame}.psf \

				\n	mol new ${_FileNameDCD}_last_F\${CountFrame}.psf waitfor all \
				\n	mol addfile ${_FileNameDCD}_last_F\${CountFrame}.pdb waitfor all \
				\n	set MolID [molinfo top] \
				\n\n	autopsf -top ${FileNameCHARMMtop[*]} -mol \$MolID -prefix \"${_FileNameDCD}_last_F\${CountFrame}_autopsf\" -solvate -ionize \
				\n	puts \"*** FINISH with frame $CountFrame ***\" \
				\n	if { \$CountFrame<=1 } { \
				\n		break \
				\n	} \
				\n	puts \"*** deletting molecule \$Count_mol ***\" \
				\n	mol delete \$Count_mol\
				\n	set Count_mol [expr \$Count_mol+10] \
				\n	set FrameNow [expr \$FrameNow-1] \
				\n	set {CountFrame} [expr \$CountFrame-1] \
				\n}\
				\nif { \${CountFrame}>1 } {\
				\n	puts \"ERROR: number of configurations required ($_ConfigNum) exceed the number of frame on the trajectory ([expr [molinfo top get numframes]-1]) \"\
				\n}\
				\nexit\
			"
			;;

		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	extract the selection from a dcd and save the new dcd and starting pdb	@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		SEL)	[ -z "${_FileNameDCD}" ] && fatal 3 "To run VMD_function -t SEL, the option -dcd is MANDATORY!"
			[ -z "${_Selection[1]}" ] && fatal 3 "To run VMD_function -t SEL, the option -s is MANDATORY!"
			[ -z "${_SelectName[1]}" ] && fatal 3 "To run VMD_function -t SEL, the option -m is MANDATORY!"

			echo -n -e > ${TEMP_FILES_FOLDER}/vmd${_ServiceType}.temp "\
				\nset _ForceField $ForceField
				\npackage require pbctools\

				\nif { \${_ForceField}==\"CHARMM\" } {\
				\n	puts \"*** forcefield -> \$_ForceField\"
				\n	package require psfgen\
				\n	readpsf ${_pathPSF}/${_FileNamePSF}.psf\
				\n	coordpdb ${_pathPDB}/${_FileNamePDB}.pdb\
				\n	mol new ${_pathPSF}/${_FileNamePSF}.psf waitfor all\
				\n	mol addfile ${_pathPDB}/${_FileNamePDB}.pdb waitfor all\
				\n} else {\
				\n	puts \"forcefield -> \$_ForceField\"
				\n	mol new ${_pathPDB}/${_FileNamePDB}.pdb waitfor all\
				\n}

				\nmol addfile ${_FileNameDCD}.dcd waitfor all\
				\npbc unwrap\
				\nsource $fitframes\
				\nfitframes top \"protein\"
			"
			for i in `seq 1 $_SelectNUM`; do
				echo -n -e >> ${TEMP_FILES_FOLDER}/vmdSEL.temp "\
					\nputs \"*** atomselect top \\\"${_Selection[$i]} and (not water and not ions)\\\" frame first\"\
					\nset SelecStructure [atomselect top \"${_Selection[$i]} and (not water and not ions)\" frame first]\
					\n\$SelecStructure writepsf ${_OutputName}_${_SelectName[$i]}.psf\
					\n\$SelecStructure writepdb ${_OutputName}_first_${_SelectName[$i]}.pdb\
					\nanimate write dcd ${_OutputName}_${_SelectName[$i]}.dcd sel \$SelecStructure waitfor all\
				"
			done
			echo -e >> ${TEMP_FILES_FOLDER}/vmdSEL.temp "\nexit"
			;;

		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	extract the name of the a selected residue				@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		RNAME)	[ -z "${_ResID}" ] && fatal 3 "To run VMD_function -t RNAME, the option -ri (_ResID='$_ResID') is MANDATORY!"
			# Save the input values in the output as a reference
			echo -e "_pathPDB \"$_pathPDB\" \n_FileNamePDB \"$_FileNamePDB\" \n_ResID \"$_ResID\" \n_SegName \"$_SegName\" \
			\n_ChainName \"$_ChainName\"" >> ${TEMP_FILES_FOLDER}/vmd"${_ServiceType}".out
			if [ -n "${_SegName}" ]; then
				echo -n -e > ${TEMP_FILES_FOLDER}/vmd"${_ServiceType}".temp "\
					\nvariable _pathPDB \"$_pathPDB\" \nvariable _FileNamePDB \"$_FileNamePDB\" \nvariable _ResID \"$_ResID\" \
					\nvariable _SegName \"$_SegName\"
				"
				cat "${ProgramPATH}/ABiSS_lib/VMD_function_RNAME_SegName.tcl" >> ${TEMP_FILES_FOLDER}/vmd"${_ServiceType}".temp
			# I generally use the Chain Name
			elif [ -n "${_ChainName}" ]; then
				echo -n -e > ${TEMP_FILES_FOLDER}/vmd"${_ServiceType}".temp "\
					\nvariable _pathPDB \"$_pathPDB\" \nvariable _FileNamePDB \"$_FileNamePDB\" \nvariable _ResID \"$_ResID\" \
					\nvariable _ChainName \"$_ChainName\"
				"
				cat "${ProgramPATH}/ABiSS_lib/VMD_function_RNAME_chain.tcl" >> ${TEMP_FILES_FOLDER}/vmd"${_ServiceType}".temp
			# This is the case for the new version (21April2023)
			else
				echo -n -e > ${TEMP_FILES_FOLDER}/vmd"${_ServiceType}".temp "\
					\nvariable _pathPDB \"$_pathPDB\" \
					\nvariable _FileNamePDB \"$_FileNamePDB\" \
					\nvariable _ResID_Chain \"$_ResID\"
				"
				cat "${ProgramPATH}/ABiSS_lib/VMD_function_RNAME_chain2.tcl" >> ${TEMP_FILES_FOLDER}/vmd"${_ServiceType}".temp
			fi
			;;


		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	Mutate the selected residue 						@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		MUT)	[ -z "${_ResID}" ] && fatal 3 "To run VMD_function -t MUTATE, the option -ri is MANDATORY!"
			[ -z "${_SegName}" ] && fatal 3 "To run VMD_function -t MUTATE, the option -sn is MANDATORY!"
			[ -z "${_ResMutation}" ] && fatal 3 "To run VMD_function -t MUTATE, the option -rm is MANDATORY!"
			[ -z "${_OutputName}" ] && _OutputName="mutant_X${_ResID}${_ResMutation}"
			echo -n -e > ${TEMP_FILES_FOLDER}/vmd${_ServiceType}.temp "\
				\nset _ForceField $ForceField
				\nset _FileName ${_FileNamePSF}_TempMol
				\npackage require psfgen

				\nif { \${_ForceField}==\"CHARMM\" } {
				\n	puts \"*** forcefield -> \$_ForceField\"
				\n
				\n	readpsf ${_pathPSF}/${_FileNamePSF}.psf\
				\n	coordpdb ${_pathPDB}/${_FileNamePDB}.pdb\
				\n	mol new ${_pathPSF}/${_FileNamePSF}.psf waitfor all\
				\n	mol addfile ${_pathPDB}/${_FileNamePDB}.pdb waitfor all\
				\n	set NoSolvent [atomselect top \"all and (not water and not ions)\"]\
				\n	\$NoSolvent writepsf ${TEMP_FILES_FOLDER}/\${_FileName}.psf\
				\n	\$NoSolvent writepdb ${TEMP_FILES_FOLDER}/\${_FileName}.pdb\
				\n	\$NoSolvent writexbgf ${TEMP_FILES_FOLDER}/\${_FileName}.xbgf\
				\n	\$NoSolvent delete
				\n} else {
				\n	puts \"*** forcefield -> \$_ForceField\"
				\n	mol new ${_pathPDB}/${_FileNamePDB}.pdb waitfor all\
				\n

resetpsf

set pr [atomselect top \"protein\"]
\$pr writepdb ${TEMP_FILES_FOLDER}/protein.pdb
\$pr delete
set pr [atomselect top \"protein and not hydrogen\"]
\$pr writepdb ${TEMP_FILES_FOLDER}/protein_noH.pdb
\$pr delete
set pr [atomselect top \"segname AP1 and not hydrogen\"]
\$pr writepdb ${TEMP_FILES_FOLDER}/AP1_noH.pdb
\$pr delete
set pr [atomselect top \"segname BP1 and not hydrogen\"]
\$pr writepdb ${TEMP_FILES_FOLDER}/BP1_noH.pdb
\$pr delete
set pr [atomselect top \"segname CP1 and not hydrogen\"]
\$pr writepdb ${TEMP_FILES_FOLDER}/CP1_noH.pdb
\$pr delete

psfgen << ENDMOL

topology ${FileNameCHARMMtop[*]}
pdbalias residue CYX CYS
pdbalias residue HIE HSD
segment AP1 {
	pdb ${TEMP_FILES_FOLDER}/AP1_noH.pdb
}
segment BP1 {
	pdb ${TEMP_FILES_FOLDER}/BP1_noH.pdb
}
segment CP1 {
	pdb ${TEMP_FILES_FOLDER}/CP1_noH.pdb
}

pdbalias atom ILE CD1 CD
pdbalias atom PRO O OT1
pdbalias atom PRO OXT OT2
pdbalias atom GLU O OT1
pdbalias atom GLU OXT OT2
pdbalias atom ALA O OT1
pdbalias atom ALA OXT OT2

coordpdb ${TEMP_FILES_FOLDER}/protein_noH.pdb

guesscoord

writepdb ${TEMP_FILES_FOLDER}/\${_FileName}.pdb
writepsf ${TEMP_FILES_FOLDER}/\${_FileName}.psf

mol new ${TEMP_FILES_FOLDER}/\${_FileName}.psf waitfor all
mol addfile ${TEMP_FILES_FOLDER}/\${_FileName}.pdb waitfor all
set NoSolvent [atomselect top \"all and (not water and not ions)\"]
\$NoSolvent writepsf ${TEMP_FILES_FOLDER}/\${_FileName}.xbgf
\$NoSolvent delete

ENDMOL


				\n}


				\nsource $mutator
				\nsource $autopsf
				\nset env(SOLVATEDIR) $Env


				\nputs \"\n*** \t MUTATOR:\"\
				\nif { [catch {mutator -psf ${TEMP_FILES_FOLDER}/\${_FileName} -pdb ${TEMP_FILES_FOLDER}/\${_FileName} -o ${TEMP_FILES_FOLDER}/${_OutputName} -ressegname ${_SegName} -resid ${_ResID} -mut ${_ResMutation}} err] } { \
				\n	puts \"***		ERROR! '$mutator' fail!\"\
				\n	exit 1\
				\n}\

				\nmol new ${TEMP_FILES_FOLDER}/${_OutputName}.psf waitfor all\
				\nmol addfile ${TEMP_FILES_FOLDER}/${_OutputName}.pdb waitfor all\
				\nset MolID [molinfo top]\


				\nputs \"\n*** \t AUTOPSF to correct the structure (CYS and HIS):\"\
				\nif { \${_ForceField}==\"CHARMM\" } {
				\n	autopsf -top ${FileNameCHARMMtop[*]} -mol \$MolID -prefix \"${_OutputName}_autopsf\" -solvate -ionize
				\n} else {
				\n	autopsf -top ${FileNameCHARMMtop[*]} -mol \$MolID -prefix \"${_OutputName}_autopsf\" -protein
				\n}

				\nexit
			"
			;;

		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	Build a solvation box for the input system				@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		SOL)	[ -z "${_OutputName}" ] && _OutputName="Solvated_${_ResID}${!_FileNamePSF}"
			echo -n -e > ${TEMP_FILES_FOLDER}/vmd${_ServiceType}.temp "\
				\nmol new ${_pathPSF}/${_FileNamePSF}.psf waitfor all\
				\nmol addfile ${_FileNamePDB}.pdb waitfor all\
				\nset NoSolvent [atomselect top \"all and (not water and not ions)\"]\
				\n\$NoSolvent writepsf ${TEMP_FILES_FOLDER}/${_FileNamePSF}_NoSolvent.psf\
				\n\$NoSolvent writepdb ${TEMP_FILES_FOLDER}/${_FileNamePSF}_NoSolvent.pdb\
				\n\$NoSolvent writexbgf ${TEMP_FILES_FOLDER}/${_FileNamePSF}_NoSolvent.xbgf\

				\nsource $solvate\
				\nsource $autoionize\

				\nset env(SOLVATEDIR) $Env\

				\nputs \"\n\t SOLVATE:\"\
				\nsolvate ${TEMP_FILES_FOLDER}/${_FileNamePSF}_NoSolvent.psf ${TEMP_FILES_FOLDER}/${_FileNamePSF}_NoSolvent.pdb -o ${_OutputName} -t 12\

				\nputs \"\n\t AUTOIONIZE:\"\
				\nautoionize -psf ${_OutputName}.psf -pdb ${_OutputName}.pdb -o ${_OutputName} -sc 0.15 -cation POT\
				\nexit
			"
			;;

		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		#@	unidentified type	@#
		#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		*)	fatal 2 "VMD_function () ERROR: \"$_ServiceType\" is not a valid ServiceType!\n";;			# First file name
	esac
	$_VMD -dispdev none -e ${TEMP_FILES_FOLDER}/vmd${_ServiceType}.temp &> vmd_${_ServiceType}.out

	if [ "$_ServiceType" != "MUT" ]; then
		[ "`grep -v "^psfgen" vmd_${_ServiceType}.out | egrep "(ERROR)|(can't read)"`" ] && fatal 4 "There is an \"ERROR\" or \"can't read\" on \"vmd_${_ServiceType}.out\"!! Check it!!"
		[ "`egrep 'usage' vmd_${_ServiceType}.out`" ] && fatal 4 "There is an \"usage\" on \"vmd_${_ServiceType}.out\"!! Check it!!"
	fi
}

