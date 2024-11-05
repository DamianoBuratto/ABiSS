#!/bin/bash

echo -e "\t > BuildFoldersAndPrintHeadingFiles.sh"
# function to build the folders inside the Config folder and to write the
# header for results_FOLDER/MoleculesResults.dat

function BuildFoldersAndPrintHeadingFiles {
# BuildFoldersAndPrintHeadingFiles _currentPath

# GLOBAL VARIABLES NEEDED:
# current_conf_PATH

# LOCAL VARIABLES:
  _RunningNum_PerSystem=$1

	for Cycle_Number in $(seq 1 "$_RunningNum_PerSystem"); do
	  mkdir "cycle${Cycle_Number}_MD"
	done
	repository_FOLDER="${current_conf_PATH}/REPOSITORY"
	results_FOLDER="${current_conf_PATH}/RESULTS"
	removed_files_FOLDER="${current_conf_PATH}/REMOVED_FILES"
	[[ $TEMP_FILES_FOLDER == "" ]] && TEMP_FILES_FOLDER="${current_conf_PATH}/tempFILES"
	mkdir -p "$repository_FOLDER" "$results_FOLDER" "$removed_files_FOLDER" "$TEMP_FILES_FOLDER"
  if [[ $VERBOSE == True ]]; then
    echo ""; msg -v "Building folder $repository_FOLDER";
	  msg -v "Building folder $results_FOLDER";
	  msg -v "Building folder $removed_files_FOLDER";
	  msg -v "Building folder $TEMP_FILES_FOLDER"; echo ""
  fi

	printf "%-10s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \t%13s \n" \
	        "#RUNnumber" "DeltaG(kJ/mol)" "Coul(kJ/mol)" "vdW(kJ/mol)" \
		      "PolSol(kJ/mol)" "NpoSol(kJ/mol)" "ScoreFunct" "ScoreFunct2" "Canonica_AVG" "MedianDG" \
		      "DeltaG_2s" "dG_PotEn" > "${results_FOLDER}/MoleculesResults.dat"


}