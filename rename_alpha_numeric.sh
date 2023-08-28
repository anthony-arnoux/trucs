#!/bin/bash

# Chemmin
repertoire="./"

# Bon endroit
cd "$repertoire" || exit

# Compteur pour numérotation
compteur=1

# boucle tout les fichiers en tri alphabetique sans les .sh
find . -maxdepth 1 -type f ! -name "*.sh" | sort -V | while IFS= read -r fichier; do
    # filename
    nom_fichier=$(basename "$fichier")
    
    # extension
    extension="${nom_fichier##*.}"
    
    # newname
    nouveau_nom="$(printf "%03d" "$compteur").$extension"
    
    ##DEBUG##
    echo "ancien : $fichier"
    echo "nouveau : $nouveau_nom"
    ##!DEBUG##
    
    # Renommer
    #mv "$nom_fichier" "$nouveau_nom"
    # Incr compteur
    compteur=$((compteur + 1))
done

echo "OK"
