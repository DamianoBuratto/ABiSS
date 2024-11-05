
# I NEED THE FOLLOWING VARIABLE TO BE SET:
#   if "ChainName" has been set:
#       variable _pathPDB path
#       variable _FileNamePDB name
#       variable _ResID 100 101 102
#       variable _ChainName H

mol new ${_pathPDB}/${_FileNamePDB}.pdb
# set selRES [atomselect top "resid ${_ResID} and chain ${_ChainName}"]
set List_ResID [split "${_ResID}" " "]
set nameRES {}
foreach Selection $List_ResID {
    puts "*** selRES [atomselect top "resid $Selection and chain ${_ChainName}"]"
    set selRES [atomselect top "resid $Selection and chain ${_ChainName}"]
    lappend nameRES [lsort -unique [$selRES get resname]]
    $selRES delete
}

puts "NAME_RESIDUE_SEARCHED: $nameRES" 
exit
