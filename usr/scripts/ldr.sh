#!/bin/sh

. /usr/scripts/common_functions.sh

while true; do
  if [ -f /etc/ldr-average.conf ]; then
    . /etc/ldr-average.conf 2>/dev/null
    #read config in every iteration, so we can change the average online
  fi

  if [ -z "$AVG" ]; then AVG=1; fi
  # if no config availabe, use 1 as average

  dd if=/dev/jz_adc_aux_0 count=20  |  sed -e 's/[^\.]//g' | wc -m >> /run/ldr
  # Add new line to file with measurements

  tail -n $AVG /run/ldr > /run/ldr-temp
  mv /run/ldr-temp  /run/ldr
  # cut /run/ldr to desired number of lines

  LINES=$(wc -l < /run/ldr)
  if [ "$LINES" -lt "$AVG" ]; then AVG=$LINES; fi
  # to avoid slow switching when starting up, use the number of lines when there are less than the average
  # this may cause some flickering when starting up

  SUM=$(awk '{s+=$1} END {printf "%.0f", s}' /run/ldr)
  [[ ! $SUM -eq 0 || ! $AVG -eq 0 ]] && AVGMEASUREMENT=$(($SUM/$AVG)) || AVGMEASUREMENT=0 # calculate the average


  if [ "$AVGMEASUREMENT" -lt 50 ]; then  # Light detected
    night_mode off
  else # nothing in Buffer -> no light
    night_mode on
  fi
  sleep 10
done
