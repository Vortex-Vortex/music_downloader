#!/bin/bash

: '
    This script was made to compare artists names in musics downloaded from the list,
as some could be misstyped.
    It uses levenshtein distance to gather similarities between all artists in a folder
with musics.
    This script was made to run on a single folder which has all the files, but you
could use a simple "for" loop to run across many folders.
    When running with no options and arguments, the levenshtein is defaulted to
$HOME/Scripts/leven.sh, you could use as first argument the path to the lev.sh dependecy
file. (you can find one in my GitHub:https://github.com/Vortex-Vortex/levenshtein_distance_sh)
    When running with -m option, it is imperative to pass as first argument the -m, then
2nd should be the path to the folder which has the musics to process, and then the 3rd
should be the path to levenshtein distance dependency.
    -m option should be run on the first time the script runs, as it creates a music.tmp
file at /tmp, it logs there all the artists without duplicates.
    The main function list_file processes the musics.tmp file and compare each entry/artist
with all others, so this process can be quite long depending on the number of entries. To
shorten the processing, you can increase the background processes limit at the line 62, at
a 16 thread processor of 3.2Ghz each, 32 processes uses up to 100% of power, have caution.
    The final log is present at /tmp/music_log.tmp.
'

mktmp() {
    for music in "$1"/*; do
        if echo $music | grep -qi '.log'; then
            continue
        fi
        music=$(basename "$music")
        echo $music | sed 's/\s\-\s.*$//'
    done | sort | uniq > /tmp/music.tmp
}

list_file() {
    names=()
    while read line; do
        names+=("$line")
    done < /tmp/music.tmp

    rm -f /tmp/music_log.tmp &> /dev/null
    echo $1
    if [[ ! -e "$1" ]]; then
        echo "${1} Doesn't exist"
        exit 1
    fi
    for ((i=0; i<${#names[@]}; i++)); do
        current_name=${names[i]}
        echo "\# \# \# processing $current_name..."
        for ((j=$i + 1; j<${#names[@]}; j++)); do
            printf -v new_i '%04d' "$i"
            printf -v new_j '%04d' "$j"
            echo "$new_i ||| $new_j :::::: $current_name ||| ${names[j]}" |& tee -a /tmp/music_log.tmp
            if echo ${names[j]} | grep -qi "$current_name"; then
                echo "$current_name is similar to ${names[j]}" |& tee -a /tmp/music_log.tmp
                continue
            fi
            distance=$(sh ${1} "$current_name" "${names[j]}")
            (( $distance > 0 && $distance < 3 )) && echo "$current_name is similar to ${names[j]}" |& tee -a /tmp/music_log.tmp
        done &

        while [[ $(jobs -r -p | wc -l) -ge 4 ]]; do
        wait
        done
    done
}

while getopts ":m:" option; do
    case $option in
        m)  mktmp "${2}"
            exit;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

list_file "${1:-$HOME/Scripts/leven.sh}"

