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

out_file='${station}_$(date +"%Y-%d-%m_%H-%M")'

url=$(curl -fsSL "http://de1.api.radio-browser.info/json/stations/byuuid/${station_uuid}" | tr ',' '\n' | grep "url_resolved" | awk -F'"' '{print $4}')

# check si dans le temps
curr_time=$(date +"%R")

# ffmpeg en arriere plan
ffmpeg -i "$url" -c copy "$out_file.mp3" &
#ffmpeg -i "$url" -b:a 96k "$out_file.opus" &
pid=$!

if [[ "$curr_time" < "$stop_time" ]]; then
    # recup le pid du process ffmpeg
    #pid=$!

    # si le meme jour, toutes les minutes, check si faut tjrs enregistrer
    while [[ $(date +"%R") < "$stop_time" ]]; do
        sleep 1m
    done
else
    # si la fin est le jour d apres -> super
    while [[ $(date +"%R") < "23:59" ]]; do
        sleep 1m
    done

    while [[ $(date +"%R") < "$stop_time" ]]; do
        sleep 1m
    done
    # kill propre du ffmpeg
    #kill -SIGINT $pid
fi
kill -SIGINT $pid
