#!/bin/bash

echo -ne "
-------------------------------------------------------------------------
  ██╗  ██╗ ██████╗ ██████╗ ████████╗██████╗██╗  ██╗     ██████╗ ███████╗
  ██║  ██║██╔═══██╗██╔══██╗╚══██╔══╝██╔═══ ╚██╗██╔╝    ██╔═══██╗██╔════╝
  ██║  ██║██║   ██║██████╔╝   ██║   ████╗   ╚███╔╝ ███╗██║   ██║███████╗
  ╚██╗██╔╝██║   ██║██╔══██╗   ██║   ██╔═╝   ██╔██╗ ╚══╝██║   ██║╚════██║
   ╚███╔╝ ╚██████╔╝██║  ██║   ██║   ██████╗██╔╝╚██╗    ╚██████╔╝███████║
    ╚══╝   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝
-------------------------------------------------------------------------
                    Automated Youtube video to mp3
-------------------------------------------------------------------------
"

: '
    single_file() do a yt-dlp search on YouTube with the first argument passed after -s,
it prioritizes videos where title is the same as the argument, from start to end, otherwise,
it searches topic/auto-generated videos which contain the name passed as argument.
    It is recommended to search for a music with the format:
        "Artist Name - Music Name"
    only, as most musics have that name format.
    You can pass a second argument after the -s flag, to serve for a path to store the
downloaded music, if it is not passed, it defaults to current directory ./
    The most common audio format outputted is .opus format, this script does not convert it
to mp3 automatically, use ffmpeg to do that job if needed.
'

single_file() {
    yt-dlp "ytsearch:$1"
    yt-dlp \
            ytsearch5:"$1" \
            --match-filter 'title~="(?i)^'"$1"'$" & description!~="\d{1,2}:\d{2}?" & duration < 1200 & duration > 70' \
            --match-filter 'title~="(?i)'"$1"'" & description~="(?i)Auto-generated" & description!~="(?i)live" & title!~="(?i)video" & title!~="(?i)album" & title!~="(?i)live" & title!~="(?i)trailer" & original_url!*=/shorts/ & duration < 1200 & duration > 70' \
            --match-filter 'title~="(?i)'"$1"'" & description!~="(?i)live" & description!~="\d{1,2}:\d{2}?" & title!~="(?i)video" & title!~="(?i)album" & original_url!*=/shorts/ & duration < 1200 & description!~="(?i)tracklist" & description!~="(?i)\d\d?\..*\n^\d\d?\..*" & duration < 1200 & duration > 70' \
            -x \
            -P "${2}" \
            -o "$1.%(ext)s" \
            --max-downloads 1 \
            --exec 'echo "Title: %(title)s, Search: '"$1"', URL: %(webpage_url)s, Duration: %(duration_string)s"'
}

: '
    list_file() receives a .txt(only) file as srgument after -m flag, then processes it to grab
artist and music name to do a yt-dlp search on YouTube.
    It prioritizes videos where title is the same as the argument, from start to end, otherwise,
it searches topic/auto-generated videos, filters out lives, albums and shorts, or gather only
title == title, filtering other aspects based on description.
    It is recommended to use a list with a music in each line with the format:
        "Artist Name - Music Name"
        Also:
        "[[01][.][ - ][ ]]Artist Name - Music Name [ [hh:]mm:ss]"
    where [] means optional.
        e.g.
            Sonata Arctica - Blank File
            Sonata Arctica - In Black And White 0:00
            02. Sonata Arctica - Paid In Full 5:04
            03 Sonata Arctica - Aint your Fairytale
            04 - Sonata Arctica - Wolf and Raven 12:51
            06 Sonata Arctica - 8th Commandment 1:24:04
    It is imperative to have at least "Artist - Title" name, with the correct order and with the " - ",
as the code uses sed to grab the Title and Artist separately.
    You can pass a second argument after the -m flag, to serve for a path to store the
downloaded list, if it is not passed, it defaults to ~/Music, so if it is passed:
            sh music_downloader.sh -m "My Music list 1"
        then:
            $HOME/Music/My Music list 1/{music_1, music_2, music_n...}
            is created. (Do not use ~/ for home, use instead $HOME or /home/[user])
    This script creates two log files at the downloaded list location, the first, which is "list name.log"
has data about each entry in the list, as for music Title, duration, url(if downloaded), string used in search, and
if the download failed, it appears as "FAILURE: :". At the end of the log, it outputs "done" or
"failed" status for troubleshooting purposes.
    The second log is "run_list name.log" has the output of the overall script for troubleshooting
purposes, as when downloading many list with starter.sh, stdout surely will be chaotic.
    The most common audio format outputted is .opus format, this script does not convert it
to mp3 automatically, use ffmpeg to do that job if needed.
'

list_file() {
    while read line
    do
        music=$(echo $line | sed 's/^[0-9]*//; s/^\s\-\s//; s/^\.//; s/\s\+[0-9]\+:.*//; s/\s\+$//; s/^\s\+//')
        title=$(echo $music | sed 's/[^\-]*\-//;s/^\s\+//;s/\s\+$//')
        artist=$(echo $music | sed 's/\-[^\-]*[\-]*.*//;s/^\s\+//;s/\s\+$//')
        echo "music=$music"
        echo "artist:$artist: -- title:$title:"
        echo "yt-dlp..."
        yt-dlp \
            ytsearch10:"$music" \
            --match-filter 'title~="(?i)^'"$music"'$" & description!~="\d{1,2}:\d{2}?" & duration < 1200 & duration > 70' \
            --match-filter 'title~="(?i)^'"$title"'$" & description!~="\d{1,2}:\d{2}?" & duration < 1200 & duration > 70' \
            --match-filter 'title~="(?i)'"$title"'" & description~="(?i)Auto-generated" & description!~="(?i)live" & title!~="(?i)video" & title!~="(?i)album" & title!~="(?i)live" & title!~="(?i)trailer" & original_url!*=/shorts/ & duration < 1200 & duration > 70' \
            --match-filter 'title~="(?i)'"$title"'" & description~="(?i)'"$artist"'" & description!~="(?i)live" & description!~="\d{1,2}:\d{2}?" & title!~="(?i)video" & title!~="(?i)album" & original_url!*=/shorts/ & duration < 1200 & description!~="(?i)tracklist" & description!~="(?i)\d\d?\..*\n^\d\d?\..*" & duration < 1200 & duration > 70' \
            --match-filter 'title~="(?i)'"$title"'" & description~="(?i)'"$artist"'" & description!~="(?i)live" & description!~="\d{1,2}:\d{2}?" & title!~="(?i)video" & title!~="(?i)album" & original_url!*=/shorts/ & duration < 1200 & description!~="(?i)tracklist" & description!~="(?i)\d\d?\..*\n^\d\d?\..*" & duration < 1200 & duration > 70' \
            -x \
            -P "${2}/$path" \
            -o "$music.%(ext)s" \
            --max-downloads 1 \
            --exec 'echo "Title: %(title)s, Search: '"$music"', URL: %(webpage_url)s, Duration: %(duration_string)s" >> "'"${2}"'/'"$path"'/'"$path"'.log"' \
            > /dev/null 2>&1
        if [ $? -eq 101 ]; then
            echo -e "Success:\n                \033[42;37m+++$music\033[0m"
        else
            echo -e "Failure:\n                \033[41;37m---$music\033[0m"
            echo "FAILURE:$music:" >> "${2}/$path/$path.log"
        fi
    done < "$1"
    if [[ $(sed -n '$=' < "$1") -eq $(($(ls -1 "${2}/$path/"| wc -l) - 2)) ]]; then
        echo "done" >> "${2}"/"$path"/"$path".log
    else
        echo "failure" >> "${2}"/"$path"/"$path".log
    fi
}

while getopts ":sm:" option; do
   case $option in
      s) single_file "$2" "${3:-./}"
         exit;;
      m) file=$(basename "$2")
         path=$(echo $file | sed 's/\..*//')
         mkdir "${3:-$HOME/Music}"/"$path" &> /dev/null
         list_file "$2" "${3:-$HOME/Music}" |& tee "${3:-$HOME/Music}"/"$path"/run_"$path".log
         exit;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done
