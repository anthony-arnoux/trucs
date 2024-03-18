#!/bin/bash
TZ="Europe/Paris"
# Dépendances
if ! eval "which ffmpeg &> /dev/null"; then
  echo "all my homiz lovz ffmpeg but it is capout je trouve pas"
  exit 5
elif ! eval "which curl &> /dev/null"; then
  echo "all my true homiz lovz le cul but it is capout je trouve pas"
  exit 5
fi

if eval "ping -qn4c1 one.one.one.one >/dev/null"; then
  true
else
  echo "l'network il est capout"
  exit 1
fi

if [[ ! -z $1 && ! -z $2 ]]; then
  station=$1
  if [[ $2 =~ ^[0-9]{2}:[0-9]{2}$ ]]; then # format 12:34 H:M
    if [[ $3 = "demain" ]]; then
      curr_date=$(date -d "tomorrow" "+%Y-%m-%d") #DEMAIN
    fi
    curr_date=$(date +"%Y-%m-%d")
    stop_time=$2
    stop_time="$curr_date $stop_time"
  else
    echo "format hh:mm"
    exit 4
  fi
  case $station in
    nostalgie)
      station_uuid="960bf492-0601-11e8-ae97-52543be04c81"
      ;;
    nrj)
      station_uuid="db97789f-ad2e-11e8-aa67-52543be04c81"
      ;;
    funradio)
      station_uuid="9f756e2d-8e9b-45f5-8fc1-61573e23036b"
      ;;
    *)
      echo "station \"$1\" non supporté"
      exit 2
      ;;
   esac
else
  echo "pas de parametre 1 et/ou 2"
  exit 3
fi
curr_datetime=$(date +"%Y-%m-%d_%H_%M")
out_file="${station}_${curr_datetime}"

url=$(curl -fsSL "http://de1.api.radio-browser.info/json/stations/byuuid/${station_uuid}" | tr ',' '\n' | grep "url_resolved" | awk -F'"' '{print $4}')

# ffmpeg en arriere plan
ffmpeg -i "${url}" -c copy "${out_file}.mp3" &
#ffmpeg -i "${url}" -b:a 96k "${out_file}.opus" &
pid=$!

while [[ $(date +"%Y-%m-%d %H:%M") < "$stop_time" ]]; do
  sleep 1m
done
kill -SIGINT $pid
