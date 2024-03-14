#!/bin/bash

if $(ping -qn4c1 one.one.one.one >/dev/null); then
  internet="1"
else
  echo "l'network il est capout"
  exit 1
fi

if [[ ! -z $1 ]] ; then
  station=$1
  case $station in
    nostalgie)
      station_uuid="960bf492-0601-11e8-ae97-52543be04c81"
      ;;
    nrj)
      station_uuid="db97789f-ad2e-11e8-aa67-52543be04c81"
      ;;
    *)
      echo "non supporté"
      exit 2
      ;;
   esac

else
  echo "pas de parametre 1"
  exit 3
fi

out_file="radio_$(date +"%d-%m-%Y").mp3"

start_time="13:16:00"
stop_time="13:17:00"

url=$(curl -fsSL "http://de1.api.radio-browser.info/json/stations/byuuid/${station_uuid}" | tr ',' '\n' | grep "url_resolved" | awk -F'"' '{print $4}')
echo $url
# check si dans le temps
current_time=$(date +"%H:%M:%S")
if [[ "$current_time" > "$start_time" && "$current_time" < "$stop_time" ]]; then
    # ffmpeg en arriere plan
    ffmpeg -i "$url" -c copy "$out_file" &
    # recup le pid du process ffmpeg
    pid=$!

    # toutes les minutes, check si faut tjrs enregistrer
    while [[ $(date +"%H:%M:%S") < "$stop_time" ]]; do
        sleep 1m
    done

    # kill propre du ffmpeg
    kill -SIGINT $pid
else
    echo "hors des temps, ignore"
fi
