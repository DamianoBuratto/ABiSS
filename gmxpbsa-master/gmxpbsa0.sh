#!/bin/bash

# GMXPBSA tool is free software. You can redistribute it and/or modify it under the GNU Lessere General Public Lincese as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version (http://www.gnu.org/licenses/lgpl-2.1.html).
# GMXPBSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# For any problem, doubt, comment or suggestion please contact me at dimitris3.16@gmail.com or paissoni.cristina@hsr.it

# Copyright 2013 Dimitrios Spiliotopoulos, Cristina Paissoni

#export LC_NUMERIC="en_US.UTF-8"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
##########################################################################
echo -e "- Loading FUNCTIONS.."
source $DIR/function_base.dat
source $DIR/function_gmx.dat
source $DIR/function_apbs.dat
source $DIR/print_files.dat
PPATH=${DIR%/*}
source $PPATH/functions.sh
_gmxpbsa_StartFolder=$PWD
echo -e "starting folder: $_gmxpbsa_StartFolder"

#@@@@@@@@@@@@@@@@@@@#
# (0) Print version #
#@@@@@@@@@@@@@@@@@@@#

INPUT_FILE="INPUT.dat"
while [ $# -gt 0 ]
do
	case "$1" in
		-i)		shift; INPUT_FILE=$1;;
		-h)		clear; echo -e "\n\nGMXPBSA version 2.1.2\n\n";exit ;;
		*)		fatal 1 "MakeFiles_GMXPBSA ERROR: $1 is not a valid OPTION!\n";;
	esac
	shift
done


#@@@@@@@@@@@@@@@@@@#
# (1) Let's start #
#@@@@@@@@@@@@@@@@@@#
# clear
if [ -f REPORTFILE0 ]  ; then  rm REPORTFILE0; fi
if [ -f WARNINGS_gmxpbsa0.dat ]  ; then rm WARNINGS_gmxpbsa0.dat; fi

touch REPORTFILE0
# check that the file ($1) exist and report any error on the output file ($2). It will exit in case of error.
check ${INPUT_FILE} REPORTFILE0
rm -f \#* *~


#@@@@@@@@@@@@@@@#
# (2) Variables #
#@@@@@@@@@@@@@@@#

# NOT USED OPTIONS (DELETED)
set_variable_default "use_topology" "n";
set_variable_default "NO_topol_ff" "n";
#NO_topol_ff="n"
set_variable_default2 "gmx_suffix" "";
set_variable_default2 "gmx_prefix" "";
set_variable_default "read_vdw_radii" "n";
#*****************************************

# set variable with key ($1) and use the default value ($2) if the key is not found on the INPUT file
set_variable_default "run" "1";
# set variable with key ($1). If no key is found the program exit with error
set_variable "root";

set_variable_default "multitrj" "n";
if [ $multitrj == "y" ]; then
	set_variable_multiple "root_multitrj";
	N_start_dir=`echo $root_multitrj | awk '{N=split($0,v," "); print N}'`
	for ((i=0; i<$N_start_dir; i++)); do
		start_dir[$i]=`echo $root_multitrj | awk -v i=$(($i+1)) '{N=split($0,v," "); print v[i]}'`
		check_DIR ${start_dir[$i]}
	done
else
	check_DIR $root
fi

# MD variables
set_variable_default "protein_alone" "n";

set_variable_default "name_xtc" "npt";
set_variable_default "name_tpr" "npt";

set_variable "complex";
set_variable "receptor";
set_variable "ligand";

set_variable "ffield";
set_variable_default "skip" "1";
set_variable_default "min" "n";
set_variable_default "use_tpbcon" "n";

set_variable_multiple_default "Histidine" ""
set_variable_default "mergeC" ""
merge[0]="$mergeC"
set_variable_default "mergeR" ""
merge[1]="$mergeR"
set_variable_default "mergeL" ""
merge[2]="$mergeL"
#echo "Setting variable Histidine to '$Histidine'" | tee -a REPORTFILE0
#echo "Setting variable mergeC to '${merge[0]}'" | tee -a REPORTFILE0
#echo "Setting variable mergeR to '${merge[1]}'" | tee -a REPORTFILE0
#echo "Setting variable mergeL to '${merge[2]}'" | tee -a REPORTFILE0

set_variable_default "multichain" "n";
set_variable "Gpath";

echo -e "\n**Setting the APBS variables**\n"
set_variable_default "precF" "0";
set_variable_default "extraspace" "5";
set_variable_default "coarsefactor" "1.7";
set_variable_default "grid_spacing" "0.5";

set_variable_default "linearized" "y";
set_variable_default "temp" "293";
set_variable_default "bcfl" "mdh";
set_variable_default "pdie" "2";
set_variable_default "sdie" "80";
set_variable_default "chgm" "spl2";
set_variable_default "srfm" "smol";
set_variable_default "srad" "1.4";
set_variable_default "swin" "0.3";
set_variable_default "sdens" "10.0";
set_variable_default "calcforce" "no";
set_variable_default "ion_ch_pos" "1";
set_variable_default "ion_rad_pos" "2.000";
set_variable_default "ion_conc_pos" "0.1500";
set_variable_default "ion_ch_neg" "-1";
set_variable_default "ion_rad_neg" "2.000";
set_variable_default "ion_conc_neg" "0.1500";

set_variable_default "Hsrfm" "sacc";
set_variable_default "Hpress" "0.000";
set_variable_default "Hgamma" "0.0227";
#set_variable_default "Hbconc" "0.000";
set_variable_default "Hdpos" "0.20";
set_variable_default "Hcalcforce" "total";
set_variable_default "Hxgrid" "0.1";
set_variable_default "Hygrid" "0.1";
set_variable_default "Hzgrid" "0.1";

calcenergy="total"
Hbconc="0.00"

# PBS queque system variables
echo -e "\n**Setting the PBS queque variables**\n"
set_variable_default "cluster" "y";
set_variable_default "mnp" "1";
if [ $cluster == "y" ]
then
	set_variable "Q";
	set_variable_default2 "budget_name" "";
	set_variable_default2 "walltime" "";
        #set_variable_default "nodes" "1";
	#set_variable_default "mem" "5GB";
	set_variable_default "option_clu" "select=$mnp:ncpus=1:mem=5GB ";
	set_variable_default2 "option_clu2" "";
fi

# output variables
set_variable_default "pdf" "n";

set_variable_default "coulomb" "gmx";
set_variable_default "Apath" "$apbs_path";


pdb2gmx=pdb2gmx; trjconv=trjconv; mdrun=mdrun; grompp=grompp; editconf=editconf; tpbconv=tpbconv; gmx=$coulomb;
#if [ "$gmx" == "" ]; then echo -e "NO VALUES on gmx ($gmx) "; gmx="gmx"; echo -e " ..setted to -> $gmx"; fi
#gmx=gmx_mpi;

 # is Gromacs installed?
if [ -z $Gpath ]; then
	echo -e "\n"$(date +%H:%M:%S)" \n ERROR: I could not find Gromacs Path. Exiting... \n" >> REPORTFILE0
	echo "Exiting -- please read the REPORTFILE0"
	exit
else
	control0=`find $Gpath -maxdepth  1 -name $gmx 2>/dev/null | rev | cut -d / -f 1`
	#echo -e "\nGpath->$Gpath \t gmx->$gmx \t control0->$control0"
	if [ -z "$control0" ]; then
	       control1=`find $Gpath -maxdepth  1 -name $editconf 2>/dev/null | rev | cut -d / -f 1`
		if [ -z $control1 ]; then
			echo "control1=$control1 - The variable Gpath is not set correctly. Please double-check it. Exiting..."; exit;
		else
			control2=`find $Gpath -maxdepth  1 -name $editconf 2>/dev/null | rev| cut -d / -f 1 | rev | awk '{if ($1~"editconf") {print "ok"} else {print "no"} }'`
			if [ $control2 == "no" ]; then
				echo "control2=$control2 - The variable Gpath is not set correctly. Please double-check it. Exiting..."; exit;
			else
				Gversion="4";
			fi
		fi
	else
		control3=`find $Gpath -maxdepth  1 -name $gmx 2>/dev/null | rev| cut -d / -f 1 | rev | awk '{if ($1~"gmx") {print "ok"} else {print "no"} }'`
		if [ $control3 == "ok" ]; then
			Gversion="5";

		else
			 control4=`find $Gpath -maxdepth  1 -name $gmx 2>/dev/null | rev| cut -d / -f 1 | rev | awk '{if ($1~"gmx") {print "ok"} else {print "no"} }'`
			if [ $control4 == "no" ]; then
				echo "control4=$control4 - The variable Gpath is not set correctly. Please double-check it. Exiting..."; exit;
			else
				Gversion="5 - mpi";
			fi
		fi
	fi

fi

 # what Gromacs version is installed? (GVersion)
if [ $Gversion -eq 4 ]; then
	echo -en "\nUsing GROMACS version 4 "
	$Gpath\/$editconf -h 2> out 1> /dev/null
	GVersion=$(grep VERSION out | awk '{print $3}' | sort -u)
else
	echo -en "\nUsing GROMACS version 5 (${gmx})"
	$Gpath\/$gmx -h 2> out 1> /dev/null
	GVersion=$(grep "GROMACS - gmx" out | awk '{print $5}'| sort -u)
	pdb2gmx="${gmx} pdb2gmx"; trjconv="${gmx} trjconv"; mdrun="${gmx} mdrun"; grompp="${gmx} grompp"; editconf="${gmx} editconf"; tpbconv="${gmx} convert-tpr"; GENBOX="${gmx} solvate"; GENION="${gmx} genion"; MAKE_NDX="${gmx} make_ndx"

fi
echo -e "(GVersion -> $GVersion)"
rm -f out


nf=$(which apbs 2>/dev/null | awk -F / '{print NF-1 }')
if [ $nf ]; then apbs_path=$(which apbs| cut -d / -f -$nf); fi
if [ -z $Apath ]; then
	echo -e "\n"$(date +%H:%M:%S)" \n ERROR: I could not find apbs Path. Exiting... \n" >> REPORTFILE0
	echo "Exiting -- please read the REPORTFILE0"
	exit
else
	control=`find $Apath -maxdepth  1 -name apbs 2>/dev/null | rev | cut -d / -f 1`
	if [ -z $control ]; then
		echo "The variable Apath is not set correctly. Please double-check it. Exiting..."; exit;
	else
		control=`find $Apath -maxdepth  1 -name apbs 2>/dev/null | rev| cut -d / -f 1 | rev | awk '{if ($1=="apbs") {print "ok"} else {print "no"} }'`
		if [ $control == "no" ]; then echo "The variable Apath is not set correctly. Please double-check it. Exiting..."; exit; fi
	fi
fi




#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# (3) initialization of the procedure #
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

RUN=RUN${run}_$root
let run--
while [ 1 -gt 0 ]
do
	let run++
	RUN=RUN${run}_$root
	[ -d "${RUN}" ] && { echo -e "The folder ${RUN} already exist. Incrementing the 'run' number.. "; continue; }
	LaneNum=`grep -n "run" ${INPUT_FILE} | cut -d":" -f 1`
	sed -i -e $LaneNum"c\run 			$run" ${INPUT_FILE}
	break
done
check_run "$RUN"
RUN=${_gmxpbsa_StartFolder}/${RUN}

PRINT_WELCOME >> REPORTFILE0


Folder=$root
#entering in each folder...
cd ${_gmxpbsa_StartFolder}/${Folder}
rm -f \#* *~

# check the existence of the trajectory, topology and index files
check $name_xtc.xtc ../REPORTFILE0; check $name_tpr.tpr ../REPORTFILE0; check index.ndx ../REPORTFILE0;

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# (4) generation of complex, receptor and ligand centered PDB files #
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Here it generates the centered complex PDB files...
echo -e " \n"$(date +%H:%M:%S)" Generating the centered PDB structures in "$Folder"..." | tee -a ../REPORTFILE0
#echo "$complex"| $Gpath\/$trjconv -f $name_xtc.xtc -o ${name_xtc}_out.xtc -s $name_tpr.tpr -pbc whole -n index.ndx  >>STD_ERR0 2>&1
#new_xtc=${name_xtc}_out
new_xtc=${name_xtc}

# generate the _com.pdb files
echo -e "$complex\n$complex\n$complex" | $Gpath\/$trjconv -f ${new_xtc}.xtc -o _comp.pdb -s $name_tpr.tpr \
  -fit rot+trans -n index.ndx -sep -center -skip $skip &> STD_ERR0 \
  || { echo " something wrong with TRJCONV to make _com.pdb!! exiting..."; exit; }

check2 _comp0.pdb ../REPORTFILE0

# ... and here it generates the receptor and ligand PDB files (using the complex PDB files)
fin=$(ls -l _comp*.pdb | wc -l )
let fin=$fin-1
for (( counter=0; counter<=$fin; counter++ )) ; do
	fakeprot=$(echo $receptor$counter)
	fakeliga=$(echo $ligand$counter)
	echo -e "$receptor" | $Gpath\/$editconf -f _comp$counter.pdb -o _$fakeprot.pdb -n index.ndx &> STD_ERR0 \
    || { echo " something wrong with editconf to make _rec.pdb!! exiting..."; exit; }
	echo -e "$ligand" | $Gpath\/$editconf -f _comp$counter.pdb -o _$fakeliga.pdb -n index.ndx &> STD_ERR0 \
    || { echo " something wrong with editconf to make _lig.pdb!! exiting..."; exit; }
	#  Update "$counter"
done

check2 _$receptor\0.pdb ../REPORTFILE0
check2 _$ligand\0.pdb ../REPORTFILE0

rm -f STD_ERR0
cd ${_gmxpbsa_StartFolder}

# NOW MAKES THE RUN FOLDER  and copy the pdbs and stuff in it
mkdir ${RUN}
cp ${INPUT_FILE} ${RUN}/run${run}_parameters.in
mv REPORTFILE0 ${RUN}; REPORTFILE0=${RUN}/REPORTFILE0
mkdir ${RUN}/${Folder}
cd ${_gmxpbsa_StartFolder}/${Folder}
for file in _*.pdb
do
	mv ${file} ${RUN}/${Folder}
done
cp index.ndx ${RUN}/${Folder}
cp ./${new_xtc}.xtc ${RUN}/${Folder}
cp ${name_tpr}.tpr ${RUN}/${Folder}
# cp *mdp ../$RUN/$Folder

cd ${RUN}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# (5) complex, receptor and ligand PDB EM #
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# The file Mm.mdp is generated
#	if the user prefers to perform a thorough minimization, the box sizes of the structures are checked and stored in the b[XYZ] variables

#entering in each folder...
cd ${RUN}/${Folder}
#cp ../../../SETUP_PROGRAM_FILES/Protein_EngComp_ff14sb_custom.mdp ./EngComp.mdp
rm -f \#* *~


let "fin=$(ls _comp*.pdb | wc | awk '{print $1}')"
let "fin=$fin-1"

if [ $multichain == "y" ]; then
	 echo -e "\n"$(date +%H:%M:%S)" Modifying the PDB files in order to use multiple chains in "$Folder"...\n" | tee -a ${REPORTFILE0}
	 for file in _*.pdb; do
		cp $file a$file
		nOC2=`grep "OC2" a${file} | wc -l`;
		#echo -e "*file->$file \t afile->a$file \t nOC2->$nOC2" | tee -a ${REPORTFILE0}
		for idx in `seq 1 $nOC2`; do
			ln=`grep -n "OC2" a$file | head -n $idx | tail -n 1 | cut -d : -f1`
			let lnTER=$ln+1
			#echo -e "\t*ln->$ln \t lnTER->$lnTER" | tee -a ${REPORTFILE0}
			flag=$(head -n $lnTER a$file | tail -n 1 | cut -b 1-3)
			if [ "$flag" != "TER" ]; then
				sed -i $ln'a\TER' $file
			fi
			#echo -e "\t*afile->a$file \t flag->$flag" | tee -a ${REPORTFILE0}
			#more a$file | awk '{if (NR == ln) {printf "TER\n"$0"\n"} else {print $0}  }' ln=$(($ln+1)) > $file
			cp $file a$file
		done
		mv a$file $file
	done
fi

# OLNY IF I RUN MINIMIZATION BEFORE THE ENERGY CALCULATIONS
if [ "$min" = "y" ]; then

	if [ $Gversion -eq 4 ]; then
		echo -e "->using PRINT_MINfile_y.. "
		PRINT_MINfile_y;
	else
		echo -e "->using PRINT_MINfile_y.. "
		PRINT_MINfile_y_verlet;
	fi

	echo -e " \n\n"$(date +%H:%M:%S)" Starting to perform the energy minimization of the PDB files in "$Folder" (min=$min)..." | tee -a ${REPORTFILE0}
	# The EM step is performed for each complex, receptor and ligand structure
	for  (( counter=0; counter<=$fin; counter++ )); do
	# merge[0]="$mergeC"; merge[1]="$mergeR"; merge[2]="$mergeL"
	flag=0
		for molec in comp $receptor $ligand; do
			EnergyMin_y "$molec" "$counter" "$Gpath" "$ffield" "$use_topology" "$editconf" "$pdb2gmx" "$grompp" "$mdrun"  "${merge[$flag]}"
		done
	done
else

	#	echo "$receptor" | $Gpath\/$tpbconv -s ${name_tpr}.tpr -n index.ndx -o ${receptor}.tpr >>STD_ERR0 2>&1
	echo -e " \n\n"$(date +%H:%M:%S)" Starting the recovery of the Coulomb/VdW energy contributions from the PDB files in "$Folder" (min=$min, NO_topol_ff=$NO_topol_ff)..." | tee -a ${REPORTFILE0}

	if [ $use_tpbcon == "n" ]; then
		if [ $Gversion -eq 4 ]; then
			echo -e " \t\t running EnergyMin_n (using function PRINT_MINfile_n, use_tpbcon=$use_tpbcon)..." | tee -a ${REPORTFILE0}
			PRINT_MINfile_n;
		else
			echo -e " \t\t running EnergyMin_n_verlet (using function PRINT_MINfile_n_verlet, use_tpbcon=$use_tpbcon)..." | tee -a ${REPORTFILE0}
			PRINT_MINfile_n_verlet;
		fi
	elif [ $use_tpbcon == "y" ]; then
		if [ $Gversion -eq 4 ]; then
			echo -e " \t\t running EnergyMin_y (using function PRINT_MINfile_y for ligand and receptor and rerun for complex, use_tpbcon=$use_tpbcon)..." | tee -a ${REPORTFILE0}
			PRINT_MINfile_y;
		else
			echo -e " \t\t running EnergyMin_y (using function PRINT_MINfile_y_verlet for ligand and receptor and rerun for complex, use_tpbcon=$use_tpbcon)..." | tee -a ${REPORTFILE0}
			PRINT_MINfile_y_verlet;
		fi

		cp ${name_tpr}.tpr comp.tpr
		#echo "$complex" | $Gpath\/$tpbconv -s ${name_tpr}.tpr -n index.ndx -o comp.tpr >>STD_ERR0 2>&1
		echo "$ligand" | $Gpath\/$tpbconv -s ${name_tpr}.tpr -n index.ndx -o ${ligand}.tpr >>STD_ERR0 2>&1 	|| { echo " something wrong with ligand TPBCONV!! exiting..."; exit; }
		echo "$receptor" | $Gpath\/$tpbconv -s ${name_tpr}.tpr -n index.ndx -o ${receptor}.tpr >>STD_ERR0 2>&1 	|| { echo " something wrong with receptor TPBCONV!! exiting..."; exit; }
	fi

	for  (( counter=0; counter<=$fin; counter++ )); do
	# merge[0]="$mergeC"; merge[1]="$mergeR"; merge[2]="$mergeL"
	flag=0
		for molec in comp $receptor $ligand; do
		# 	EnergyMin_n _name 	_count  _Gpath   _ffield    _topology 	    _usetpbcon    _editconf   _pdb2gmx  _grompp    _mdrun   _mergeSTRING
			EnergyMin_n "$molec" "$counter" "$Gpath" "$ffield" "$use_topology" "$use_tpbcon" "$editconf" "$pdb2gmx" "$grompp" "$mdrun" "${merge[$flag]}"
			let flag++
		done
	done
	if [ $use_tpbcon == "y" ]; then rm -f comp.tpr ${ligand}.tpr ${receptor}.tpr; fi
fi

#rm STD_ERR0




#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# (6) generation of the PQR files #
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo -e $(date +%H:%M:%S)" Started generating the PQR files from the corresponding "$Folder" PDB files (read_vdw_radii=$read_vdw_radii NO_topol_ff=$NO_topol_ff)..." | tee -a  ${REPORTFILE0}

editconf1="$editconf";
for (( counter=0; counter<=$fin; counter++ )); do
	for molec in comp $receptor $ligand; do
		name=${molec}${counter}
		check2 ${name}.tpr ${REPORTFILE0} && $Gpath\/$editconf1 -f ${name}.tpr -mead ${name}.pqr >>STD_ERR0 2>&1 	\
      || { echo " something wrong with editconf1 ($editconf1)!! exiting..."; exit; }
		check2 ${name}.pqr ${REPORTFILE0}
		#PDB2PQR "comp" "$receptor" "$ligand" "$counter" "$Gpath" "$editconf1"
	done
done


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# (7) PDB and GRO files definitive storage #
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
mkdir PDBstructures
if [ -f PDBfiles_comp0.tar.gz ]; then mv PDBfiles_* PDBstructures; fi
if [ -f GROfiles_comp0.tar.gz ]; then mv GROfiles_* PDBstructures; fi
if [ -f PDBfiles1_comp0.tar.gz ]; then mv PDBfiles1_* PDBstructures; fi

tar cfz PDBs.tar.gz PDBstructures && rm -rf PDBstructures
rm -f *comp*.tpr
rm -f *$receptor*.tpr *$ligand*.tpr
rm -f STD_ERR0

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# (8) generation of a REP files #
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
for (( counter=0; counter<=$fin; counter++ )); do
	generate_STRUfiles "$counter" "comp" "$receptor" "$ligand"
done

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# (9) Lennard-Jones contributions #
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo -e $(date +%H:%M:%S)" Started calculating the LJ parameters for $Folder..." | tee -a ${REPORTFILE0}

# The potential energy values of the minimized structures are stored into PotEn.PotEn.
if [ -f PotEn.PotEn ]  ; then rm PotEn.PotEn; fi
touch PotEn.PotEn

#fin is the number of configurations (starting from 0)
for (( counter=0; counter<=$fin; counter++ )); do

	# let's get rid of the unwanted spaces first...
	check2 comp$counter.log ${REPORTFILE0} && sed -e 's/ (/\_(/g' -e 's/ D/\_D/g' -e 's/\. r/.r/g' -e 's/\. c/.c/g' -e 's/ E/_E/g' comp$counter.log > Pcomp$counter.log

	# Complex values are taken,...
	# ReadEnergy _filename _energy _results
	ReadEnergy "Pcomp$counter.log" "Coulomb-14" "C14CC";
	ReadEnergy "Pcomp$counter.log" "LJ-14" "L14CC";
	ReadEnergy "Pcomp$counter.log" "Coulomb_" "CSRCC";
	ReadEnergy "Pcomp$counter.log" "LJ_" "LSRCC";
	ReadEnergy_special "Pcomp$counter.log" "Coul.recip." "CReCC";
	ReadEnergy_special "Pcomp$counter.log" "Disper.corr." "DCeCC";

	check2 $receptor$counter.log ${REPORTFILE0} && sed -e 's/ (/\_(/g' -e 's/ D/\_D/g' -e 's/\. r/.r/g' -e 's/\. c/.c/g' -e 's/ E/_E/g' $receptor$counter.log > P$receptor$counter.log
	check2 $ligand$counter.log ${REPORTFILE0} && sed -e 's/ (/\_(/g' -e 's/ D/\_D/g' -e 's/\. r/.r/g' -e 's/\. c/.c/g' -e 's/ E/_E/g' $ligand$counter.log > P$ligand$counter.log

	#... and so are receptor values...
	ReadEnergy "P$receptor$counter.log" "Coulomb-14" "C14PP";
	ReadEnergy "P$receptor$counter.log" "LJ-14" "L14PP";
	ReadEnergy "P$receptor$counter.log" "Coulomb_" "CSRPP";
	ReadEnergy "P$receptor$counter.log" "LJ_" "LSRPP";
	ReadEnergy_special "P$receptor$counter.log" "Coul.recip." "CRePP";
	ReadEnergy_special "P$receptor$counter.log" "Disper.corr." "DCePP";

	#... and so are ligand.
	ReadEnergy "P$ligand$counter.log" "Coulomb-14" "C14TT";
	ReadEnergy "P$ligand$counter.log" "LJ-14" "L14TT";
	ReadEnergy "P$ligand$counter.log" "Coulomb_" "CSRTT";
	ReadEnergy "P$ligand$counter.log" "LJ_" "LSRTT";
	ReadEnergy_special "P$ligand$counter.log" "Coul.recip." "CReTT";
	ReadEnergy_special "P$ligand$counter.log" "Disper.corr." "DCeTT";

	if [ "$CReCC" == "X" ] || [ "$CRePP" == "X" ] || [ "$CReTT" == "X" ]; then CReCC="X";CRePP="X";CReTT="X";fi
	if [ "$DCeCC" == "X" ] || [ "$DCePP" == "X" ] || [ "$DCeTT" == "X" ]; then DCeCC="X";DCePP="X";DCeTT="X";fi
	echo -e "\t\tCReCC=$CReCC \tCRePP=$CRePP \tCReTT=$CReTT \tDCeCC=$DCeCC \tDCePP=$DCePP \tDCeTT=$DCeTT" | tee -a ${REPORTFILE0}

	# The overall Lennard-Jones values are calculated...
	if [ $DCeTT == "X" ]; then
		echo -n > OF; echo -e "$L14CC \t $L14PP \t $L14TT" >> OF ; L14=$(awk '{print $1-$2-$3}' OF)	# Overall Far
		echo -n > SR; echo -e "$LSRCC \t $LSRPP \t $LSRTT" >> SR ; LSR=$(awk '{print $1-$2-$3}' SR)	# Short range
		echo -n > OA; echo -e "$LSR \t $L14" >> OA; Loa=$(awk '{print $1+$2}' OA)			# Overall All
		echo -n > Co; echo -e "$L14CC \t $LSRCC" >> Co; Com=$(awk '{print $1+$2}' Co)			# Complex
		echo -n > Pr; echo -e "$L14PP \t $LSRPP" >> Pr; Pro=$(awk '{print $1+$2}' Pr)			# Protein
		echo -n > Li; echo -e "$L14TT \t $LSRTT" >> Li; Lig=$(awk '{print $1+$2}' Li)			# Ligand
	else
		echo -n > OF; echo -e "$L14CC \t $L14PP \t $L14TT" >> OF ; L14=$(awk '{print $1-$2-$3}' OF)	# Overall Far
		echo -n > SR; echo -e "$LSRCC \t $LSRPP \t $LSRTT" >> SR ; LSR=$(awk '{print $1-$2-$3}' SR)	# Short range
		echo -n > DC; echo -e "$DCeCC \t $DCePP \t $DCeTT" >> DC ; LDC=$(awk '{print $1-$2-$3}' DC)	# Dispersion Correction
		echo -n > OA; echo -e "$LSR \t $L14" \t "$LDC" >> OA; Loa=$(awk '{print $1+$2+$3}' OA)		# Overall All
		echo -n > Co; echo -e "$L14CC \t $LSRCC \t $DCeCC" >> Co; Com=$(awk '{print $1+$2}' Co)		# Complex
		echo -n > Pr; echo -e "$L14PP \t $LSRPP \t $DCePP" >> Pr; Pro=$(awk '{print $1+$2}' Pr)		# Protein
		echo -n > Li; echo -e "$L14TT \t $LSRTT \t $DCeTT" >> Li; Lig=$(awk '{print $1+$2}' Li)		# Ligand
	fi

	# ... and stored in the REP file.
	printf "%-30s %-3s %-f \n"  "Lenn-Jon overall" "=" $Loa >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "Lenn-Jon complex overall" "=" $Com >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "Lenn-Jon $receptor overall" "=" $Pro >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "Lenn-Jon $ligand overall" "=" $Lig >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "Lenn-Jon 1-4 net" "=" $L14 >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "Lenn-Jon 1-4 $complex" "=" $L14CC >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "Lenn-Jon 1-4 $receptor" "=" $L14PP >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "Lenn-Jon 1-4 $ligand" "=" $L14TT >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "Lenn-Jon ShortRange net" "=" $LSR >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "Lenn-Jon ShortRange $complex" "=" $LSRCC >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "Lenn-Jon ShortRange $receptor" "=" $LSRPP >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "Lenn-Jon ShortRange $ligand" "=" $LSRTT >>stru$counter.rep
	if ! [ $DCeTT == "X" ]; then
		printf "%-30s %-3s %-f \n"  "Lenn-Jon Disp.Correction" "=" $LDC >>stru$counter.rep
		printf "%-30s %-3s %-f \n"  "Lenn-Jon Disp.Correction $complex" "=" $DCeCC >>stru$counter.rep
		printf "%-30s %-3s %-f \n"  "Lenn-Jon Disp.Correction $receptor" "=" $DCePP >>stru$counter.rep
		printf "%-30s %-3s %-f \n"  "Lenn-Jon Disp.Correction $ligand" "=" $DCeTT >>stru$counter.rep
		fi
	# Finally, useless files are deleted.
	rm -f OF SR OA Co Pr Li \#*
	[ -r DC ] && rm -f DC

	# The overall GMX coulombic values are also calculated...
	echo -e "\t\t$(date +%H:%M:%S) calculating the Coulomb parameters for $Folder..." | tee -a ${REPORTFILE0}
	if [ $CReCC == "X" ]; then
		echo -n > co; echo -e "$C14CC \t $CSRCC" >> co; com=$(awk '{print $1+$2}' co)
		echo -n > pr; echo -e "$C14PP \t $CSRPP" >> pr; pro=$(awk '{print $1+$2}' pr)
		echo -n > li; echo -e "$C14TT \t $CSRTT" >> li; lig=$(awk '{print $1+$2}' li)
		echo -n > of; echo -e "$C14CC \t $C14PP \t $C14TT" >> of; c14=$(awk '{print $1-$2-$3}' of)
		echo -n > sr; echo -e "$CSRCC \t $CSRPP \t $CSRTT" >> sr; csr=$(awk '{print $1-$2-$3}' sr)
		echo -n > oa; echo -e "$c14 \t $csr" >> oa; loa=$(awk '{print $1+$2}' oa)
	else
		echo -n > co; echo -e "$C14CC \t $CSRCC \t $CReCC" >> co; com=$(awk '{print $1+$2+$3}' co)
		echo -n > pr; echo -e "$C14PP \t $CSRPP \t $CRePP" >> pr; pro=$(awk '{print $1+$2+$3}' pr)
		echo -n > li; echo -e "$C14TT \t $CSRTT \t $CReTT" >> li; lig=$(awk '{print $1+$2+$3}' li)
		echo -n > of; echo -e "$C14CC \t $C14PP \t $C14TT" >> of; c14=$(awk '{print $1-$2-$3}' of)
		echo -n > sr; echo -e "$CSRCC \t $CSRPP \t $CSRTT" >> sr; csr=$(awk '{print $1-$2-$3}' sr)
		echo -n > rec; echo -e "$CReCC \t $CRePP \t $CReTT" >> rec; crec=$(awk '{print $1-$2-$3}' rec)
		echo -n > oa; echo -e "$c14 \t $csr \t $crec" >> oa; loa=$(awk '{print $1+$2+$3}' oa)
	fi
	# ... and stored in the REP file.
	printf "%-30s %-3s %-f \n"  "GMX-coul overall" "=" $loa >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "GMX-coul complex overall" "=" $com >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "GMX-coul $receptor overall" "=" $pro >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "GMX-coul $ligand overall" "=" $lig >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "GMX-coul 1-4 net" "=" $c14 >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "GMX-coul 1-4 $complex" "=" $C14CC >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "GMX-coul 1-4 $receptor" "=" $C14PP >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "GMX-coul 1-4 $ligand" "=" $C14TT >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "GMX-coul ShortRange net" "=" $csr >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "GMX-coul ShortRange $complex" "=" $CSRCC >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "GMX-coul ShortRange $receptor" "=" $CSRPP >>stru$counter.rep
	printf "%-30s %-3s %-f \n"  "GMX-coul ShortRange $ligand" "=" $CSRTT >>stru$counter.rep
	if ! [ $CReCC == "X" ]; then
		printf "%-30s %-3s %-f \n"  "GMX-coul Recip net" "=" $crec >>stru$counter.rep
		printf "%-30s %-3s %-f \n"  "GMX-coul Recip $complex" "=" $CReCC >>stru$counter.rep
		printf "%-30s %-3s %-f \n"  "GMX-coul Recip $receptor" "=" $CRePP >>stru$counter.rep
		printf "%-30s %-3s %-f \n"  "GMX-coul Recip $ligand" "=" $CReTT >>stru$counter.rep
	fi
	# Finally, useless files are deleted.
	rm -f of sr oa co pr li
	if [ -f rec ]; then rm -f rec; fi

	echo -e "\t\t$(date +%H:%M:%S) storing the Potential energy fo the structures for $Folder..." | tee -a ${REPORTFILE0}
	# Potential energy values of the structures under consideration are stored into the file PotEn.PotEn
	ReadEnergy_Pot "Pcomp$counter.log" "Potential" "potent_energC";
	ReadEnergy_Pot "P$receptor$counter.log" "Potential" "potent_energP";
	ReadEnergy_Pot "P$ligand$counter.log" "Potential" "potent_energT";

	echo -e "\t $potent_energC \t $potent_energP \t $potent_energT \t # kJ/mol\t$counter " >> PotEn.PotEn

	tar cfz LOG_file_comp$counter.tar.gz comp$counter.log  && rm comp$counter.log; rm Pcomp$counter.log
	tar cfz LOGfiles.tar.gz LOG_file_* && rm -f LOG_file_*
	tar cfz LOG_file_$receptor$counter.tar.gz $receptor$counter.log && rm $receptor$counter.log; rm P$receptor$counter.log
	tar cfz LOG_file_$ligand$counter.tar.gz $ligand$counter.log && rm $ligand$counter.log; rm P$ligand$counter.log
done

# Once everything's been calculated, the PotEn.PotEn mean and StDev are calculated for each species
cmpMN=$(awk '{sum+=$1; array[NR]=$1} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}print sum/NR}' PotEn.PotEn)
cmpSD=$(awk '{sum+=$1; array[NR]=$1} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}print sqrt(sumsq)/NR}' PotEn.PotEn)
prtMN=$(awk '{sum+=$2; array[NR]=$2} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}print sum/NR}' PotEn.PotEn)
prtSD=$(awk '{sum+=$2; array[NR]=$2} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}print sqrt(sumsq)/NR}' PotEn.PotEn)
lgnMN=$(awk '{sum+=$3; array[NR]=$3} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}print sum/NR}' PotEn.PotEn)
lgnSD=$(awk '{sum+=$3; array[NR]=$3} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}print sqrt(sumsq)/NR}' PotEn.PotEn)
echo -e "\n \t complex \t \t \t $cmpMN +/- $cmpSD kJ/mol\n \t receptor \t \t \t $prtMN +/- $prtSD kJ/mol\n\t ligand \t \t \t $lgnMN +/- $lgnSD kJ/mol" >> PotEn.PotEn


# cd ..



#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# (11) PQR files data retrieval #
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo -e " \n\n"$(date +%H:%M:%S)" Starting parsing the PQR files' coordinates..." | tee -a ${REPORTFILE0}

# cd $Folder
tot=$(ls comp*.pqr | wc | awk '{print $1}'); let "tot=$tot-1";

# The m[ai][XYZ] files are created
touch maX miX maY miY maZ miZ

#the positions of the [XYZ]cooridnate in the .pqr file are determined
check2 comp0.pqr ${REPORTFILE0}
nCOLUMN=`grep -m 1 "ATOM" comp0.pqr | awk '{ print NF }' `
if [ "$nCOLUMN" -gt 10 ] ; then Xcol=7; Ycol=8; Zcol=9;
else  Xcol=6; Ycol=7; Zcol=8; fi


# NOTE: Commands in pipes are run asynchronously: this means that in a pipe such as command1 | command2 there's no guarantee that command1 will end before command2. When using [...] | grep | head -n 1, head ends as soon as it has read one line; if this happens before grep has finished writing to the pipe, grep receives a SIGPIPE signal and errors out. As explained in the answer below that Super User answer, a workaround is to pipe the output of what's before head in the pipeline to tail -n +1 first, which will ignore the SIGPIPE signal
for (( j=0; j<=$tot; j++ )); do
	if [ -e comp$j.pqr ]; then
		# The values of the coordinates are sorted from the PQR files: highest and lowest values are taken  [ma mi][XYZ] variables...
		#grep -e "ATOM" -e "HETATM" comp$j.pqr | awk -v col=$Xcol '{print $col}' | sort -g | tail -n +1 | head -n 1 >>miX
    grep -e "ATOM" -e "HETATM" comp$j.pqr | awk -v col=$Xcol '{print $col}' | sort -g > temp.temp; head -n 1 temp.temp >>miX
		grep -e "ATOM" -e "HETATM" comp$j.pqr | awk -v col=$Xcol '{print $col}' | sort -g | tail -n 1 >>maX
		grep -e "ATOM" -e "HETATM" comp$j.pqr | awk -v col=$Ycol '{print $col}' | sort -g > temp.temp; head -n 1 temp.temp >>miY
		grep -e "ATOM" -e "HETATM" comp$j.pqr | awk -v col=$Ycol '{print $col}' | sort -g | tail -n 1 >>maY
		grep -e "ATOM" -e "HETATM" comp$j.pqr | awk -v col=$Zcol '{print $col}' | sort -g > temp.temp; head -n 1 temp.temp >>miZ
		grep -e "ATOM" -e "HETATM" comp$j.pqr | awk -v col=$Zcol '{print $col}' | sort -g | tail -n 1 >>maZ
	fi
done
echo -e " result check miX-> $(cat miX)"

sort -g maX | tail -n 1 >> ../maX
sort -g miX | tail -n +1 | head -n 1 >> ../miX
sort -g maY | tail -n 1 >> ../maY
sort -g miY | tail -n +1 | head -n 1 >> ../miY
sort -g maZ | tail -n 1 >> ../maZ
sort -g miZ | tail -n +1 | head -n 1 >> ../miZ

echo -e " result check selected ../miX-> $(cat ../miX)"

rm -f m??
cd ..

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# (12) Grid mesh calculations #
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

# The grid mesh calculations are started
echo -e "\n"$(date +%H:%M:%S)" Started performing the grid mesh calculations...\n" | tee -a ${REPORTFILE0}

XGrid=0; YGrid=0; ZGrid=0;

Calculate_GRID "miX" "maX" "UpX" "LoX" "uPX" "lOX" "XLEn" "XLeN" "XCeN" "upX" "loX" "XGrid" "$precF" "$extraspace" "$coarsefactor" "$grid_spacing"
Calculate_GRID "miY" "maY" "UpY" "LoY" "uPY" "lOY" "YLEn" "YLeN" "YCeN" "upY" "loY" "YGrid" "$precF" "$extraspace" "$coarsefactor" "$grid_spacing"
Calculate_GRID "miZ" "maZ" "UpZ" "LoZ" "uPZ" "lOZ" "ZLEn" "ZLeN" "ZCeN" "upZ" "loZ" "ZGrid" "$precF" "$extraspace" "$coarsefactor" "$grid_spacing"

rm -f m??

touch grid.grid

printf "%s \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n\n" "Maximal and minimal values in each direction" "max X = " "$UpX" "max Y = " "$UpY" "max Z = " "$UpZ" "min X = " "$LoX" "min Y = " "$LoY" "min Z = " "$LoZ" >grid.grid
printf "%s \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n\n" "Fine grid vertices in each direction" "max Xf = " "$uPX" "max Yf = " "$uPY" "max Zf = " "$uPZ" "min Xf = " "$lOX" "min Yf = " "$lOY" "min Zf = " "$lOZ" >>grid.grid
printf "%s \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n\n" "Coarse grid vertices in each direction" "max Xc = " "$upX" "max Yc = " "$upY" "max Zc = " "$upZ" "min Xc = " "$loX" "min Yc = " "$loY" "min Zc = " "$loZ" >>grid.grid
printf "%s \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n%-12s %-2.4f \n\n%-12s %-2.0f \n%-12s %-2.0f \n%-12s %-2.0f \n\n" "Final values" "XCeN = " "$XCeN" "YCeN = " "$YCeN" "ZCeN = " "$ZCeN" "XLeN = " "$XLeN" "YLeN = " "$YLeN" "ZLeN = " "$ZLeN" "XLEn = " "$XLEn" "YLEn = " "$YLEn" "ZLEn = " "$ZLEn" "XGrid = " "$XGrid" "YGrid = " "$YGrid" "ZGrid = " "$ZGrid">>grid.grid


#=======================================================================================================================================#
#=======================================================================================================================================#
# variable	how many					what does it contain?				how is it		#
#		values?												  calculated?		#
#=======================================================================================================================================#
# a[XYZ]	1/PQR		contains the extreme maximum values for X, Y, Z coordinates of each 					#
#						PQR file in each directory	 							#
# i[XYZ]	1/PQR		contains the extreme minimum values for X, Y, Z coordinates of each 					#
#						PQR file in each directory	 							#
# Up[XYZ]	1		contains the extreme overall maximum value for X, Y, Z coordinates					#
# Lo[XYZ]	1		contains the extreme overall minimum value for X, Y, Z coordinates					#
# uP[XYZ]	3		contains the fine grid maximum values for X, Y, Z coordinates			Up[XYZ]+10	 	#
# lO[XYZ]	3		contains the fine grid minimum values for X, Y, Z coordinates			Lo[XYZ]-10	 	#
# up[XYZ]	3		contains the coarse grid maximum values for X, Y, Z coordinates					 	#
# lo[XYZ]	3		contains the coarse grid minimum values for X, Y, Z coordinates					 	#
# [XYZ]LEn	1		X, Y, Z fine grid size lengths							uP[XYZ]-lO[XYZ]	 	#
# [XYZ]LeN	1		X, Y, Z coarse grid size lengths								 	#
# [XYZ]CeN	1		X, Y, Z grid centers								(Up[XYZ]-Lo[XYZ])/2	#
# [XYZ]LeNb	1		X, Y, Z real number of grid points required at least				([XYZ]LEn*2)+1		#
# [xyz]gRID	1		X, Y, Z integer number of grid points required at least				([XYZ]LeNb./*)		#
# [XYZ]Grid	1		actual X, Y, Z number of grid points									#
#=======================================================================================================================================#
#=======================================================================================================================================#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# (13) Generation of input and SH files #
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
cd $Folder
tot=$(ls comp*.pqr | wc | awk '{print $1}'); let "tot=$tot-1";

if [ "$linearized" == "y" ]; then
	pb=$(echo lpbe)
else
	pb=$(echo npbe)
fi

let "C=$(ls comp*.pqr | wc | awk '{print $1-1}')"

#@@@@ INPUT APBS FILE @@@@#
echo -e $(date +%H:%M:%S)" Started generating the input files for solvation energy calculations in "$Folder"..." | tee -a ${REPORTFILE0}

for (( count=0; count<=$C; count++ )); do

	check2 comp$count.pqr ${REPORTFILE0}; check2 $receptor$count.pqr ${REPORTFILE0}; check2 $ligand$count.pqr ${REPORTFILE0};
	# APBS polar and nonpolar solvation calculations
	PRINT_APBS_POLAR_IN "$count" "$complex" "$receptor" "$ligand" "$XGrid" "$YGrid" "$ZGrid" "$XLeN" "$YLeN" "$ZLeN" "$XLEn" "$YLEn" "$ZLEn" "$XCeN" "$YCeN" "$ZCeN" "$pb" "$pdie" "$sdie" "$srad" "$temp" "$bcfl" "$chgm" "$srfm" "$swin" "$sdens" "$calcforce" "$ion_ch_pos" "$ion_rad_pos" "$ion_conc_pos" "$ion_ch_neg" "$ion_rad_neg" "$ion_conc_neg" "$calcenergy" > stru$count.in
	PRINT_APBS_NONPOLAR_IN  "$count" "$complex" "$receptor" "$ligand" "$srad" "$temp" "$swin" "$sdens" "$Hsrfm" "$Hpress" "$Hgamma" "$Hbconc" "$Hdpos" "$Hcalcforce" "$calcenergy" "$Hxgrid" "$Hygrid" "$Hzgrid" > Hstru$count.in

done

#@@@@ SH APBS FILE @@@@#
echo -e $(date +%H:%M:%S)" Started generating the SH files for solvation energy calculations in "$Folder"..." | tee -a ${REPORTFILE0}

# SH files for polar and nonpolar calculations are created
calc=$(ls comp*.pqr | wc | awk '{print $1}')
let "D=$calc/$mnp"
let "R=$calc%$mnp"
if [ $R -eq 0 ]; then let "D=$D-1" ; fi


if [ $calc -lt $mnp ]
then
	let "D=0"
	let "proc=$calc"
else
	let "proc=$mnp"
fi

if [ $cluster == "y" ]
then
	for ((count=0; count<=$D; count++)); do
		PRINT_POLAR_SH_cluster "$count" "$proc" "$Apath" "$Q" "$D" "$C" "$budget_name" "$walltime" "$option_clu" "$option_clu2"> apbs$count.sh
		PRINT_NONPOLAR_SH_cluster "$count" "$proc" "$Apath" "$Q" "$D" "$C" "$budget_name" "$walltime" "$option_clu" "$option_clu2"> Hapbs$count.sh
		chmod 700 apbs$count.sh Hapbs$count.sh
	done
else
	for (( count=0; count<=$C; count++ )); do
		PRINT_POLAR_SH "$count" "$Apath" > apbs$count.sh
		PRINT_NONPOLAR_SH "$count" "$Apath" > Hapbs$count.sh
		chmod 700 apbs$count.sh Hapbs$count.sh
	done
fi


#@@@@@@@@@@@@@@@@@@@@@@@@@#
# (14) Cleaning procedure #
#@@@@@@@@@@@@@@@@@@@@@@@@@#

mkdir STORED_FILES
for file in  LOGfiles.tar.gz PDBs.tar.gz Mm.mdp mdout.mdp; do
	if [ -f $file ]; then
		mv $file STORED_FILES
	fi
done

mkdir APBS_CALCULATIONS
mv Hapbs*.sh apbs*.sh Hstru*.in stru*.in *.pqr APBS_CALCULATIONS

mkdir SUMMARY_FILES
mv PotEn.PotEn stru*.rep SUMMARY_FILES

rm -f io.mc
rm -f \#* *~


#Check in all the stru files that the values for LJ_overall and Coulomb_overall are written. If ok it generates the file DONE0
cd SUMMARY_FILES
if [ $coulomb == "coul" ]; then Coul_keyword="Coulomb overall"; else Coul_keyword="GMX-coul overall"; fi;
N_rep_file=`ls stru*rep | wc -l`;
count=0;
for file in stru*rep; do
	a=`grep "Lenn-Jon overall" $file | cut -d " " -f1`
	b=`grep "$Coul_keyword" $file | cut -d " " -f1`
	if [ ! -z $a ] && [ ! -z $b ]; then count=$(($count+1)); fi
done
if [ $N_rep_file -eq $count ]; then
	touch ../../DONE0_$Folder;
else
	echo -e " WARNING!! NO DONE0 FILE!! <<N_rep_file=$N_rep_file != count=$count>>" | tee -a ${REPORTFILE0}
fi
N_files=`ls stru*.rep | wc -l`
echo -e "\t\tIn the directory $Folder $N_files PQR/PDB files have been generated to perform the APBS calculations.\n" | tee -a ${REPORTFILE0}


cd ../..

echo -e "\n"$(date +%H:%M:%S)" All successfully DONE \nRun gmxpbsa1.sh to perform APBS\n"| tee -a ${REPORTFILE0}
stde=`find ./* -name STD_ERR0`
for s in $stde; do rm -f $s; done

cd ..
