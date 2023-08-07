#!/bin/bash

directory="./"  #  ou faire des bricoles
position=23  # position insert le "0"

cd "$directory" || exit 1  # quitter si merdouille

echo "Prévisualisation :"
for file in *; do
    if [ -f "$file" ]; then
        filename="${file%.*}"
        extension="${file##*.}"

        if [ ${#filename} -ge $position ]; then
            new_filename="${filename:0:$((position - 1))}0${filename:$((position - 1))}.${extension}"
            echo "Rename : $file -> $new_filename"
        fi
    fi
done

read -p "Appliquer ? (o/n) " choice
if [ "$choice" == "o" ]; then
    echo "Ok go..."
    for file in *; do
        if [ -f "$file" ]; then
            filename="${file%.*}"
            extension="${file##*.}"

            if [ ${#filename} -ge $position ]; then
                new_filename="${filename:0:$((position - 1))}0${filename:$((position - 1))}.${extension}"
                mv "$file" "$new_filename"
                echo "Rename : $file -> $new_filename"
            fi
        fi
    done
    echo "Fin."
else
    echo "Ok slt."
fi
