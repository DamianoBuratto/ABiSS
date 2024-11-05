#!/bin/bash

echo -e "\t > analysis.sh (DataAnalysis and allResultsFromRUN)"


# I am expecting in input a file with different columns:
# column 1	frame number
# column 2	DeltaG
# column 3	Coul
# column 4	vdW
# column 5	PolSol
# column 6	NpoSol
# column 7

# _dataFILE:
# frame       DeltaG(kJ/mol)    Coul(kJ/mol)    vdW(kJ/mol)    PolSol(kJ/mol)    NpoSol(kJ/mol)
#0                20.392          -1385.040       -783.080        2293.160        -104.647
#1                -80.832         -1441.480       -695.440        2157.003        -100.915
#2                -70.802         -1367.090       -766.970        2165.158        -101.900

# _PotEnFILE:
# 	 complex 	 	 	 162807 +/- 11647.3 kJ/mol
# 	 receptor 	 	 	 157736 +/- 11714 kJ/mol
#	 ligand 	 	 	 5791.54 +/- 105.196 kJ/mol
# 	 complex 	 	 	 152774 +/- 7980.75 kJ/mol
# 	 receptor 	 	 	 147668 +/- 7991.13 kJ/mol
#	 ligand 	 	 	 5936.29 +/- 76.96 kJ/mol


DataAnalysis () {
# DataAnalysis -f _dataFILE -o _outputFILE

# GLOBAL VARIABLES NEEDED:
  # true if the string is zero
  [[ -z "$ABiSS_LIB" ]] && { echo "ERROR in DataAnalysis: cannot find the GlobalVariable ABiSS_LIB($ABiSS_LIB)"; return 1; }

# LOCAL VARIABLES:
	local _dataFILE="energy_plot.temp"
	local _outputFILE="../RESULTS/cicle1_results.dat"
	local _NLines=
	local _floor_NLine=
	local _ceiling_NLine=
	local _PotEnFILE="none"

	while [ $# -gt 0 ]
	do
		case "$1" in
			-f)	shift; _dataFILE=$1;;
			-o)	shift; _outputFILE=$1;;
			-p)	shift; _PotEnFILE=$1;;
			*)	break;;
		esac
		shift
	done

	_NLines=$(grep -v -c "^#" "${_dataFILE}")
	(( _floor_NLine=(_NLines+1)/2 ))
	(( _ceiling_NLine=(_NLines+2)/2 ))
	#echo "floor=${_floor_NLine} ceiling=${_ceiling_NLine}" | tee -a $LOGFILENAME
	grep -v "^#" "${_dataFILE}" > inputfile.temp

  # INPUT REQUIRED
  # "#frame", "dG(kJ/mol)", "Coul(kJ/mol)", "VdW(kJ/mol)", "PolSol(kJ/mol)", "NpoSol(kJ/mol)",
  # AVERAGE and STD OUTPUT
  # #frame", "dG(kJ/mol)", "Coul(kJ/mol)", "VdW(kJ/mol)", "PolSol(kJ/mol)", "NpoSol(kJ/mol)", "SF1", "SF2", \
      #	"C_AVG", "Median DeltaG", "dG_2sigma(Kj/mol)", "dG_PotEn(Kj/mol)"
	awk -v _floor_NLine="${_floor_NLine}" -v _ceiling_NLine="${_ceiling_NLine}" -v inFILE="inputfile.temp" -v PotEnFILE="${_PotEnFILE}"\
	-f "${ABiSS_LIB}/FUNCTIONs/analysis.awk" inputfile.temp &> "${_outputFILE}" || fatal 44 "DataAnalysis - awk: failed!!"

	rm inputfile.temp

}



allResultsFromRUN () {
# this function will just assemble all the data from the different cycles (and every from of the cycle)
# allResultsFromRUN -rl _resultsList -o _outFile
	#msg -n "Running allResultsFromRUN..."
	local _resultsList=
	local _outFile="AllData.out"
	local _counter="0"
	local _lineNUM=
	local _flag="FirstTime"

	while [ $# -gt 0 ]
	do
	    case "$1" in
		-rl)	shift; _resultsList=$1;;
		-o)	  shift; _outFile=$1;;
		*)	  fatal 1 "allResultsFromRUN () ERROR: $1 is not a valid OPTION!\n";;
	    esac
	    shift
	done

	[ "$_resultsList" == "" ] && fatal 1 "allResultsFromRUN () ERROR: You must set the -rl option!\n"

  # Remove temporary and old files
	mv ./*temp "${removed_files_FOLDER}" &> /dev/null
	[ -r "${_outFile}" ] && rm "${_outFile}"

	#frame   dG(kJ/mol)      Coul(kJ/mol)      vdW(kJ/mol)    PolSol(kJ/mol)    NpoSol(kJ/mol)     SF=C/10-PS/10+NpS*10     SF2=3*C+PS      C_AVG=norm(SUM Gi*e^BGi)      Median DeltaG
	for config in $_resultsList; do
		[ -r "column0.temp" ] && rm column0.temp
		[ -r "column1.temp" ] && rm column1.temp

		# only for the first file flag=FirstTime and I make the header of the file
		if [ "${_flag}" == "FirstTime" ]; then
			_flag=$( grep "#frame" "$config" | head -n 1 | cut -b 1 )
			if [ "${_flag}" == "#" ]; then
				# paste will automatically add a /t
				printf "%-10s \n" "#configNum" > column0.temp
				grep "#frame" "$config" | head -n 1  > column1.temp
			else
				# paste will automatically add a /t
				# This header may be outdated.. check the original files before their assemble
				print "# This header may be outdated.. check the original files before their assemble"
				print "" > column1.temp
				print "" > column2.temp
				printf "%-10s \n" "#configNum" > column0.temp
				printf "%-10s \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f \t%13.1f\n" \
					"frame" "DeltaG(kJ/mol)" "Coul(kJ/mol)" "vdW(kJ/mol)" "PolSol(kJ/mol)" "NpoSol(kJ/mol)" "ScoreFuncts.." > column1.temp
			fi
		fi

		# I make columns with the number of cycle and I add it to the final outfile to recognise the different cycles
		_lineNUM=$(grep -c -v "^#" "$config")
		for line in $(seq 1 "$_lineNUM"); do printf "%-10s \n" "$_counter" >> column0.temp; done
		grep -v "^#" "$config" >> column1.temp
		paste column0.temp column1.temp >> "${_outFile}"		# the column will be pasted at a TAB distance
		(( _counter=_counter+1 ))
	done
	#grep -v "^#" AllData.temp > ${_outFile}
	mv column?.temp "${removed_files_FOLDER}" &> /dev/null
	#msg -s "\tAll results in $PWD copied in ${_outFile}"
}
