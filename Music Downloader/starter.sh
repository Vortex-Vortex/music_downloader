#!/bin/bash

: '
    This script job is to start background instances of music_downloader, in
a way that ensures all files were processed.
    Since the music_downloader.sh needs to run in a temporary empty directory,
this script creates the temporary directories to be used then discards them
after full completion.
    music_downloader.sh defaults to directories inside $HOME/Music folder, if
you want to change that to another folder, use "/path/to/folder" as argument
    this script should be run on same folder as the .txt files and
music_downloader.sh
'

# maximum number of instances allowed (2 * threads @ 3.00Ghz)
max_jobs=32

# directories to cd into, must be on current folder
dirs=({1..$max_jobs})
for directory in "${dirs[@]}"; do
    mkdir "$directory"
done
# number of list-files(.txt only) on pwd
num_files=$(ls -1 *.txt | wc -l)

current_file=1
# ensures all files are processed, as the script may not run all files in one go
while [[ $current_file -le $num_files ]]; do
    echo "running main while loop"
    for file_list in ./*.txt; do

        # original=../list-file.txt, file=list-file.txt
        file=$(basename "$file_list")

        # original=list-file.txt, filename=list-file
        filename=$(echo "$file" | sed 's/\..*//')

        # if not found(= previously ran), run on it
        if [ ! -d ${1:-$HOME/Music}/"$filename" ]; then
            for dir in "${dirs[@]}"; do
                if [[ ! -f "$dir/.running" ]]; then
                    touch "$dir/.running"

                    cd "$dir"
                    echo "running file $current_file ::: $file_list"
                    sh ../music_downloader.sh -m "../$file_list" "${1:-$HOME/Music}" && echo "finished file $current_file" && rm "./.running" &
                    cd ..
                    (( current_file++ ))

                    break
                fi
            done
            sleep 1
            # If all jobs are running, wait for them to finish before continuing
            if [[ $(jobs -r -p | wc -l) -ge $max_jobs ]]; then
                wait -n
            fi
        fi
    done
done

# Wait for any remaining jobs to finish
wait

# clear temporary directories
for directory in "${dirs[@]}"; do
    rm -rd "$directory"
done
