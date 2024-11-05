#!/bin/bash
# e.g. 
# make_global_self_avoiding_file $(ls -d RUN1[1-9]) Cx43_global_self_avoiding_file.out

folder_list=$1
global_file=$2
if [[ "$folder_list" == "" ]] || [[ "$global_file" == "" ]]; then
    echo "you must insert two inputs: folder_list & global_file"
fi
# echo "folder_list: $folder_list"
# echo "global_file: $global_file"

if ! [[ -r $global_file ]]; then
    echo "global_self_avoiding_file does not exist.. creating a new one"
    touch $global_file
fi

for fold in $folder_list; do
    [[ -r ${fold}/RUN1/SETUP_PROGRAM_FILES/self_avoiding_file.out ]] || { echo "cannot read ${fold}/RUN1/SETUP_PROGRAM_FILES/self_avoiding_file.out.. continue"; }
    echo "${fold}/RUN1/SETUP_PROGRAM_FILES/self_avoiding_file.out"
    cat $global_file ${fold}/RUN1/SETUP_PROGRAM_FILES/self_avoiding_file.out | sort | uniq > flag.out
    # cat $global_file ${fold}/SETUP_PROGRAM_FILES/self_avoiding_file.out | sort | uniq > flag.out
    mv flag.out $global_file
done



