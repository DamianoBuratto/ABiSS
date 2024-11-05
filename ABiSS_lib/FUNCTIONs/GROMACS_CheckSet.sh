#!/bin/bash

echo -e "\t > GROMACS_CheckSet.sh"

# This function will find GROMCS in the computer and will set the right keywords for the gromacs tools.
# These Keywords will be exported to be used by the whole program
function GROMACS_CheckSet {
# GROMACS_CheckSet
  local _cluster="$1"
# GLOBAL VARIABLES (I need them to be environmental variables in order to set them)
# it uses msg_fatal
#if printenv | grep -q "GROMPP"; then echo "GROMACS_CheckSet ERROR: cannot find GROMPP on printenv"; return 1; fi
if [[ "${source_GMX}" != "" ]]; then
  source "${source_GMX}"
fi

  _gromacs="$(command -v mdrun)"
  if [[ "$_gromacs" == "" ]]; then
    _gromacs="$(command -v gmx_mpi)"
    if [[ "$_gromacs" == "" ]]; then
      _gromacs="$(command -v gmx)"
      if [[ "$_gromacs" == "" ]]; then
        fatal 1 "GROMACS_CheckSet ERROR: Cannot find any Gromacs."
      fi
    fi
  fi
  _gromacs_path="${_gromacs%/*}"
  _GROMACSver="$( $_gromacs -version 2>&1 | grep -i "GROMACS version" | cut -d":" -f 2 | xargs )"

  if [[ "$_cluster" == "no" ]]; then
    if [[ "${_GROMACSver}" == "VERSION 4.6.7" ]]; then
      msg "\t GROMACS_CheckSet -> ${_GROMACSver}" | tee -a "${LOGFILENAME}"
      # Gromacs 4.6.7 is too old and doesn't support gpu on FEP
  #		if [ "${GPATH}" == "" ]; then
  #			command -v mdrun >/dev/null 2>&1 || { fatal 14 "Cannot find executable mdrun!! Please install it."; }
  #			GPATH=$(command -v mdrun);
  #			GPATH="${GPATH%/*}"
  #		fi
      GROMPP="${_gromacs_path}/grompp"
      MDRUN="${_gromacs_path}/mdrun"
      PDB2GMX="${_gromacs_path}/pdb2gmx"
      EDITCONF="${_gromacs_path}/editconf"
      GENBOX="${_gromacs_path}/genbox"
      GENION="${_gromacs_path}/genion"
      MAKE_NDX="${_gromacs_path}/make_ndx"
      TRJCONV="${_gromacs_path}/trjconv"
      GENRESTR="${_gromacs_path}/genrestr"
      CHECK="${_gromacs_path}/check"
  	  ENERGY="${_gromacs_path}/energy"
  	  RMS="${_gromacs_path}/rms"
      MDRUN_md="${MDRUN}"

      export KEY_compressed="nstxout-compressed"		# this "command" changed name
      #_GROMACSver=$( $GROMPP -h 2>&1 | grep "VERSION" )
    else
      # Gromacs 2018.4 / 2020.2 or higher
      msg "\t- GROMACS_CheckSet -> Gromacs version ${_GROMACSver}" | tee -a "${LOGFILENAME}"

      GMX="${_gromacs_path}/gmx"
      GROMPP="${GMX} grompp"
      PDB2GMX="${GMX} pdb2gmx"
      EDITCONF="${GMX} editconf"
      GENBOX="${GMX} solvate"
      GENION="${GMX} genion"
      MAKE_NDX="${GMX} make_ndx"
      TRJCONV="${GMX} trjconv"
      GENRESTR="${GMX} genrestr"
      CHECK="${GMX} check"
  	  ENERGY="${GMX} energy"
  	  RMS="${GMX} rms"

#      MPI_RUN="mpirun -np $NP_value -hostfile $PBS_NODEFILE --mca orte_rsh_agent ssh --mca btl self,openib,sm "
      ((NP_used_md=NP_value/4))
      MDRUN="${GMX} mdrun -ntmpi 1 -ntomp ${NP_used_md}"
#      MDRUN_md="${MDRUN} -ntmpi 1 -ntomp ${NP_value}"
      MDRUN_md="$GMX mdrun -ntmpi 1 -ntomp ${NP_used_md} -nb gpu -pme gpu -bonded gpu -update gpu "


      export KEY_compressed="nstxout-compressed"		# this "command" changed name
      #_GROMACSver=$( $GROMPP -h 2>&1 | head -n1 )

    fi

    GROMACSver="$( $MDRUN -version 2>&1 | grep -i "GROMACS version" | cut -d":" -f 2 | xargs )"
    msg "\t- production mdrun->$MDRUN_md (v$_GROMACSver | v$GROMACSver)"
    # GPATH will be used by GMXMMPBSA and I want to use Gromacs 4.6.7 with it
    if [[ "${GPATH}" == "" ]]; then
      fatal 12 "GROMACS_CheckSet ERROR: You must set GPATH on Gromacs 4.6.7"
    else
      msg "Gromacs 4.6.7 at ${GPATH}"
    fi
  fi

}
