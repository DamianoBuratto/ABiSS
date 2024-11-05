
# I NEED THE FOLLOWING VARIABLE TO BE SET:
#   if "ChainName" has been set:
#       variable _pathPDB path
#       variable _FileNamePDB name
#       variable _ResID_Chain 100:H 101:H 102:L
#

mol new ${_pathPDB}/${_FileNamePDB}.pdb
# set selRES [atomselect top "resid ${_ResID} and chain ${_ChainName}"]

set List_ResID_Chain [split "${_ResID_Chain}" " "]
set List_ResID {}
set List_Chain {}
foreach Residue_and_Chain $List_ResID_Chain {
    lappend List_ResID [ lindex [split "${Residue_and_Chain}" ":"] 0 ]
    lappend List_Chain [ lindex [split "${Residue_and_Chain}" ":"] 1 ]
}
puts "List_ResID->$List_ResID"
puts "List_Chain->$List_Chain"

set nameRES {}
set index 0
foreach Selection $List_ResID {
    puts "*** selRES \[atomselect top \"resid $Selection and chain \[lindex \$List_Chain $index\]\"] "
    set selRES [atomselect top "resid $Selection and chain [lindex $List_Chain $index]"]
    lappend nameRES [lsort -unique [$selRES get resname]]
    $selRES delete
    set index [expr $index+1]
}

puts -nonewline "NAME_RESIDUE_SEARCHED: "
foreach residue $nameRES {
    puts -nonewline " $residue  "
}
puts ""

exit
