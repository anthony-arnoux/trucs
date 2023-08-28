#!/bin/bash
character_pos=22
character_added=0

for fichier in *.mkv; do
    nouv_nom=$(echo "$fichier" | sed "s/\(.\{${character_pos}\}\)/\1${character_added}/")
    ##DEBUG##
    echo  "$fichier" "$nouv_nom"
    ##!DEBUG##
    #mv "$fichier" "$nouv_nom"
done
