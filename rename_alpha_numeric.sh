#!/bin/bash

# Chemin vers le répertoire contenant les fichiers
repertoire="/chemin/vers/repertoire"

# Se déplacer dans le répertoire
cd "$repertoire" || exit

# Compteur pour le préfixe numérique
compteur=1

# Boucle à travers les fichiers triés alphabétiquement (avec prise en charge des espaces)
find . -maxdepth 1 -type f | sort | while IFS= read -r fichier; do
    # Obtenir le nom de fichier sans chemin
    nom_fichier=$(basename "$fichier")
    
    # Obtenir l'extension du fichier
    extension="${nom_fichier##*.}"
    
    # Générer un nouveau nom de fichier avec préfixe numérique
    nouveau_nom="$(printf "%03d" "$compteur").$extension"
    
    # Renommer le fichier (en gérant les espaces)
    mv "$nom_fichier" "$nouveau_nom"
    
    # Incrémenter le compteur
    compteur=$((compteur + 1))
done

echo "Renommage terminé."
