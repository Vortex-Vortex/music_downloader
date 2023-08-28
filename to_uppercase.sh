#!/bin/bash

: '
    This script was made to Capitalize the musics downloaded from the lists which had
full uppercase or full lowercase titles.
    It will default to currecnt directory as working directory, you can pass the first
argument to be the folder which has each list downloaded.
    In addition, it will also delete duplicate items on same directory, as a manual
downloading might generate files with same name but different formats, this script
prioritizes .opus files over m4a.
    First argument should be the folder which has the folders of the downloaded lists
to process.
'

for folder in "${1:-./}"*; do
    if [[ ! -e "${1:-./}/$folder/$folder.log" ]]; then
        continue
    fi
    cd "$folder"
    current_collection=$(basename "$PWD")
    echo "$current_collection"

    for file in *; do
        if [[ $file = *[![:ascii:]]* ]]; then
            continue
        fi
        if [[ $file == *.log ]] || [[ $file == *.tmp ]]; then
            continue
        fi
        capitalized=$(echo $file | tr "[A-Z]" "[a-z]" | sed -e "s/\b\(.\)/\u\1/g")
        mv "$file" "$capitalized" &> /dev/null
        echo "$file" | sed 's/\..\{3,4\}$//'
    done > musics.tmp
    cat musics.tmp
    sed -i 's/.*/\U&/g' musics.tmp
    current_duplicate=$(sort musics.tmp | uniq -d)
    while read line; do
        if [[ -n "$line" ]]; then
            echo "FOUND DUPLICATE:$line:"
            if [[ $line == *.m4a ]]; then
                rm -rf "${line}.m4a" -v
            else
                rm -rf "${line}.opus" -v
            fi
            echo "finished line..."
        fi
    done <<< "$current_duplicate"
    rm -f musics.tmp
    cd ..
done
