#!/bin/bash

: '
    This script is made to present status of current running music_downloader.sh scripts
by starter.sh, it displays if the lists are still downloading or have finished, showing
if it succeded or failed.
    This should be run inside the same directory that has the directories of each list,
otherwise, pass the first argument to that path.
    Also if you passed the 1st argument, most likely you will need to pass the second,
that is the path to the .txt lists directory, so it can debug it.
    e.g. tree:
    ├── Musics
    |   ├── Music Downloader
    |   │   ├── List 1.txt
    |   │   ├── List 2.txt
    |   │   ├── List 3.txt
    |   |   |── music_downloader.sh
    |   |   └── starter.sh
    |   ├── List 1
    |   |   ├── Music 1
    |   |   ├── Music 2
    |   |   ├── Music 3
    |   ├── List 2
    |   |   ├── Music 1
    |   |   ├── Music 2
    |   |   ├── Music 3
    |   ├── List 3
    |   |   ├── Music 1
    |   |   ├── Music 2
    |   |   ├── Music 3
    └   └──check_music_dirs.sh

    In this case, you could run: [User@Hostname Musics]sh check_music_dirs.sh
    or : [User@Hostname Musics]sh check_music_dirs.sh "$HOME/Musics" "$HOME/Musics/Music Downloader"
                                                        ^              ^
                                                       has "List 1"   has "List 1.txt"
'

while true; do
    clear
    for folder in "${1:-./}"/*; do
        folder=$(basename "$folder")
        if [[ ! -e "${1:-./}/$folder/$folder.log" ]]; then
            continue
        else
            status=$(sed -n '$p' "${1:-./}/$folder/$folder.log")
            total=$(sed -n '$=' "${2:-./Music Downloader}/$folder.txt")
            log_lines=$(grep -vc "FAILURE:" "$1/$folder/$folder.log")
            (( success = $log_lines > $total ? $log_lines - 1 : $log_lines ))
            if [[ $status == "done" ]]; then
                echo -e "$success of $total   :::   $folder   :::   \033[42;37m+++Success\033[0m"
            elif [[ $status == "failure" ]]; then
                echo -e "$success of $total   :::   $folder   :::   \033[41;37m+++Failure\033[0m"
            else
                echo -e "$success of $total   :::   $folder   :::   \033[30;46mRunning...\033[0m"
            fi
        fi
    done
    sleep 5
done
