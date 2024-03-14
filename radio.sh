#!/bin/bash

if eval "ping -qn4c1 one.one.one.one >/dev/null"; then
  true
else
  echo "l'network il est capout"
  exit 1
fi

if [[ ! -z $1 && ! -z $2 ]]; then
  station=$1
  if [[ $2 =~ ^[0-9]{2}:[0-9]{2}$ ]]; then # format 12:34 H:M
    stop_time=$2
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
    *)
      echo "station \"$1\" non supporté"
      exit 2
      ;;
   esac
else
  echo "pas de parametre 1 et/ou 2"
  exit 3
fi

out_file="radio_$(date +"%d-%m-%Y-%S").mp3"

url=$(curl -fsSL "http://de1.api.radio-browser.info/json/stations/byuuid/${station_uuid}" | tr ',' '\n' | grep "url_resolved" | awk -F'"' '{print $4}')

# check si dans le temps
curr_time=$(date +"%H:%M")

ffmpeg -i "$url" -c copy "$out_file" &
pid=$!

if [[ "$curr_time" < "$stop_time" ]]; then
    # ffmpeg en arriere plan
    #ffmpeg -i "$url" -c copy "$out_file" &
    # recup le pid du process ffmpeg
    #pid=$!

    # si le meme jour, toutes les minutes, check si faut tjrs enregistrer
    while [[ $(date +"%H:%M") < "$stop_time" ]]; do
        sleep 1m
    done
else
    # si la fin est le jour d apres -> super
    while [[ $(date +"%H:%M") < "23:59" ]]; do
        sleep 1m
    done

    while [[ $(date +"%H:%M") < "$stop_time" ]]; do
        sleep 1m
    done
    # kill propre du ffmpeg
    #kill -SIGINT $pid
fi
kill -SIGINT $pid
