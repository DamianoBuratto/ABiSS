#!/bin/bash

echo -e "\t > buildBoxWaterIons.sh"



function buildBoxWaterIons {
# buildBoxWaterIons _startingSystem _topology (output: system_ions.gro)

# GLOBAL VARIABLES
  # shellcheck disable=SC2086
  [[ -x $(command -v $GENBOX) ]] || { echo "buildBoxWaterIons ERROR: I cannot find the Global Variable GENBOX($GENBOX)"; return 1; }
  [[ -x $(command -v $GROMPP) ]] || { echo "buildBoxWaterIons ERROR: I cannot find the Global Variable GROMPP($GROMPP)"; return 1; }
  [[ -x $(command -v $MAKE_NDX) ]] || { echo "buildBoxWaterIons ERROR: I cannot find the Global Variable MAKE_NDX($MAKE_NDX)"; return 1; }
  [[ -x $(command -v $GENION) ]] || { echo "buildBoxWaterIons ERROR: I cannot find the Global Variable GENION($GENION)"; return 1; }

# LOCAL VARIABLES
	local _startingSystem=
	local _topology=
	local _minim_file="$minim_NAME"

	while [ $# -gt 0 ]
	do
	    case "$1" in
		-s)	  shift; _startingSystem=$1;;   # MANDATORY
		-t)	  shift; _topology=$1;;         # MANDATORY
    -m)	  shift; _minim_file=$1;;       # MANDATORY (could work with default value)
		*)	  fatal 1 "buildBoxWaterIons () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done
  [[ -r $_startingSystem ]] ||  { echo "buildBoxWaterIons ERROR: I cannot read SYSTEM_file($_startingSystem)"; return 1; }
  [[ -r $_topology ]] ||  { echo "buildBoxWaterIons ERROR: I cannot read TOPOLOGY_file($_topology)"; return 1; }
  [[ -r $_minim_file ]] ||  { echo "buildBoxWaterIons ERROR: I cannot read MDP_file($_minim_file)"; return 1; }

	_topology=${_topology%.top}
	$GENBOX -cp "${_startingSystem}" -cs spc216.gro -o system_water.gro -p "${_topology}.top"	\
	  &> genbox.out || { echo " something wrong on GENBOX!! exiting..."; return 2; }

	# COMPUTE THE NUMBER OF IONS NEEDED IN THE BOX AND ADD THEM TO THE SYSTEM
	$GROMPP -f "${_minim_file}" -c system_water.gro -p "${_topology}.top" -o system_ions.tpr -maxwarn 1 \
	  &> grompp.out || { echo " something wrong on GROMPP!! exiting..."; return 3; }
	ChargeValue=$( awk '/System has non-zero total charge/ {  x=$NF; if(x>0){x=x+0.5}else{x=x-0.5}; printf "%2i", x  }' grompp.out )
	if [[ $ChargeValue == "" ]]; then
	  # if the system has 0 total charge, the ChargeValue variable will be empty
	  ((ChargeValue=0))
	fi
	WaterMolecules=$( awk '$1 ~ /SOL/ { print $NF }' "${_topology}.top" )
	IonsNumber=$( echo "scale=0; x=($WaterMolecules*0.00271)/1; print x;" | bc -l );		# 150nM of solt
	KNumber=$( echo "scale=0; x=($IonsNumber-1*$ChargeValue/2)/1; print x;" | bc -l );
	ClNumber=$( echo "scale=0; x=($IonsNumber+1*$ChargeValue/2+1*$ChargeValue%2)/1; print x;" | bc -l );
	netCHARGE=$( echo "scale=0; x=($KNumber-$ClNumber+1*$ChargeValue)/1; print x;" | bc -l );
	NEWnetCHARGE="not computed"
	echo -e "ChargeValue=$ChargeValue WaterMolecules=$WaterMolecules IonsNumber=$IonsNumber \
		\nnetCHARGE=$netCHARGE KNumber=$KNumber ClNumber=$ClNumber NEWnetCHARGE=$NEWnetCHARGE" &> SystemCharge.out
	if [ "$netCHARGE" -ne "0" ]; then
		echo -e "\n\t\t   >>> WORNING!! check the charge of the system!! (SystemCharge.out) <<<  \t"
		ClNumber=$( echo "scale=0; x=($ClNumber+1*$netCHARGE)/1; print x;" | bc -l )
		NEWnetCHARGE=$( echo "scale=0; x=($KNumber-$ClNumber+1*$ChargeValue)/1; print x;" | bc -l )
	fi
	echo -e "After netCHARGE CHECK:  \
	\nnetCHARGE=$netCHARGE KNumber=$KNumber ClNumber=$ClNumber NEWnetCHARGE=$NEWnetCHARGE" &>> SystemCharge.out

	#echo "ChargeValue->$ChargeValue   WaterMolecules->$WaterMolecules   IonsNumber->$IonsNumber   KNumber->$KNumber   ClNumber->$ClNumber"
	echo -e "keep 0\nr SOL\nkeep 1\n\nq\n" | $MAKE_NDX -f system_water.gro -o index_SOL.ndx \
	  &> make_ndx.out || { echo " something wrong!! exiting..."; return 4; }
	echo -e "0\n" | $GENION -s system_ions.tpr -n index_SOL.ndx -o system_ions.gro -p "${_topology}.top" -nn "${ClNumber}" -nname CL \
	  -np "${KNumber}" -pname K	&> genion.temp || { echo " something wrong on GENION!! exiting..."; return 5; }
	rm index_SOL.ndx

}