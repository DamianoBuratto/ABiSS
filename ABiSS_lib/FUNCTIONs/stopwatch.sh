#!/bin/bash

echo -e "\t > stopwatch.sh"

function stopwatch() {
  # 'stopwatch -s' gives the seconds passed since the start of the program
  # 'stopwatch -f event_start_time[seconds]' gives how long it took for the event to complete in human-readable notation
  starting_time=
  if [[ $1 == "-s" ]]; then
    echo $SECONDS
  elif [[ $1 == "-f" ]]; then
    shift; starting_time=$1
    if [[ $starting_time == "" ]]; then
      echo "starting time is \"$starting_time\".. set it to 0"
      starting_time=0
    fi
    duration=$(( SECONDS - starting_time ))
    if (( duration > 86400 )); then
      D=$((duration/86400))
      H=$(( (duration%86400)/3600 ))
      M=$(( ((duration%86400)%3600)/60 ))
      S=$(( ((duration%86400)%3600)%60 ))
      echo "-Completed in ${D}D ${H}H ${M}M ${S}S-"
    elif (( duration > 3600 )); then
      H=$(( duration/3600 ))
      M=$(( (duration%3600)/60 ))
      S=$(( (duration%3600)%60 ))
      echo "-Completed in ${H}H ${M}M ${S}S-"
    elif (( duration > 60 )); then
      M=$(( duration/60 ))
      S=$(( duration%60 ))
      echo "-Completed in ${M}M ${S}S-"
    else
      echo "-Completed in ${duration}S-"
    fi
  else
    echo "WRONG INPUT!"
  fi
}
