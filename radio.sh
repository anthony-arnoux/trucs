#!/bin/bash
export TZ="Europe/Paris"
set -euo pipefail

# Vérification des dépendances
deps=("ffmpeg" "curl")
for dep in "${deps[@]}"; do
  if ! command -v "$dep" &> /dev/null; then
    echo "Dépendance manquante: $dep" >&2
    exit 2
  fi
done

# Validation des arguments
if [[ -z "${1:-}" || -z "${2:-}" ]]; then
  echo "Usage: $0 <station> <hh:mm> [demain]" >&2
  exit 3
fi

station="$1"

# Validation du format de l'heure
if [[ ! "$2" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
  echo "Format heure invalide, attendu hh:mm" >&2
  exit 4
fi

# Calcul de la date d'arrêt
if [[ "${3:-}" == "demain" ]]; then
  curr_date=$(date -d "tomorrow" "+%Y-%m-%d")
else
  curr_date=$(date +"%Y-%m-%d")
fi
stop_time="$curr_date $2"

# Résolution de l'UUID de la station
case "$station" in
  nostalgie)    station_uuid="960bf492-0601-11e8-ae97-52543be04c81" ;;
  nrj)          station_uuid="db97789f-ad2e-11e8-aa67-52543be04c81" ;;
  fun|funradio) station_uuid="9f756e2d-8e9b-45f5-8fc1-61573e23036b" ;;
  *)
    echo "Station \"$station\" non supportée" >&2
    exit 2
    ;;
esac

# Nom du fichier de sortie
out_file="${station}_$(date +"%Y-%m-%d_%H_%M")"

# Récupération d'un serveur API actif
api=$(curl -fsSL "http://all.api.radio-browser.info/json/servers" \
  | grep -o '"name":"[^"]*"' | head -n 1 | awk -F'"' '{print $4}')

if [[ -z "$api" ]]; then
  echo "Impossible de joindre l'API radio-browser" >&2
  exit 5
fi

# Récupération de l'URL de stream
url=$(curl -fsSL "http://${api}/json/stations/byuuid/${station_uuid}" \
  | grep -o '"url_resolved":"[^"]*"' | awk -F'"' '{print $4}')

if [[ -z "$url" ]]; then
  echo "URL de stream introuvable pour la station \"$station\"" >&2
  exit 5
fi

# Lancement de l'enregistrement en arrière-plan (opus 96 kbps)
ffmpeg -hide_banner -loglevel warning -i "$url" -c:a libopus -b:a 96k "${out_file}.opus" &
pid=$!

# Attente jusqu'à l'heure d'arrêt
while [[ "$(date +"%Y-%m-%d %H:%M")" < "$stop_time" ]]; do
  sleep 60
done

# Arrêt de l'enregistrement
kill -SIGINT "$pid"
