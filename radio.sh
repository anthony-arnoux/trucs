#!/bin/bash
TZ="Europe/Paris"

# Parcours et check des dépendance
deps=("ffmpeg" "curl")
for dep in "${deps[@]}"; do
  if ! command -v "$dep" &> /dev/null; then
    echo "Dependence insatisfaite: $dep"
    exit 2
  fi
done

# si la station est l'heure de fin est renseignée
if [[ ! -z $1 && ! -z $2 ]]; then
  station=$1
  # si l'heure est au bon format -> on traite
  if [[ $2 =~ ^[0-9]{2}:[0-9]{2}$ ]]; then # format 12:34 H:M
    # si 'demain" en troisième argument -> date d arrêt à demain J+1
    if [[ $3 = "demain" ]]; then
      curr_date=$(date -d "tomorrow" "+%Y-%m-%d") #DEMAIN
    else
      # sinon c'est le jour même donc ok
      curr_date=$(date +"%Y-%m-%d")
    fi

    # dans tous les l'heure est la bonne
    stop_time=$2

    # concatene date heure pour pouvoir être comparé efficacement
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
    fun|funradio)
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

# template nom de sortie
out_file="${station}_$(date +"%Y-%m-%d_%H_%M")"

api=$(curl -fsSL "http://all.api.radio-browser.info/json/servers" | tr ',' '\n' | grep "name" | awk -F'"' ' {print $4} ' | head -n 1)
# appel API avec l uuid de la station pour recuperer l url de stream
url=$(curl -fsSL "http://${api}/json/stations/byuuid/${station_uuid}" | tr ',' '\n' | grep "url_resolved" | awk -F'"' '{print $4}')
# ffmpeg en arriere plan en copie codec

#ffmpeg -hide_banner -loglevel error -i "${url}" -c copy "${out_file}.mp3" &

# ffmpeg en arriere plan transcodage vers opus 96kbs
ffmpeg -hide_banner -loglevel error -i "${url}" -c:a libopus -b:a 96k "${out_file}.opus" &

# recupération du pid du process ffmpeg
pid=$!

# tant qu'on est pas à la date souhaité -> petite pause pour re check dans une minute
while [[ $(date +"%Y-%m-%d %H:%M") < "$stop_time" ]]; do
  sleep 1m
done

# condition rempli donc plus aucune raison d'enregistrer -> soft kill du process ffmpeg
kill -SIGINT $pid
