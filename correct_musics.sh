#!/bin/bash

: '
    This script was made to manually correct failed musics when using the music_downloader.sh
with -m flag passed a.k.a. music lists.
    It creates a universal log file which will take all folders which were created by the
downloader and join all its logs, then it will run through that file and prompt a youtube
search data for each FAILURE line.
    The prompt gives you four options:
        1-7: Download the Nth file presented in the screen and correct the FAILURE
         0 : Stop the script entirely, this will trigger update_all_log() too
         r : Prompts you for a new filename, so next time the script is run, it will have
    a new music name to search for, use this incase the music name has a typo or is incorrect.
         * : Press enter or anything different than the other options to skip the current
    prompt. You can also press any key at the start of each prompt to skip faster previously
    failed musics, those which even the search did not work (it happens).
This script should be run inside the folder that has all the downloaded lists you want to
    correct. Otherwise, you should use as first and only argument the folder which has the
    desired downloaded lists to change.
'

correct_music() { # should be run on same folder as universal log, and same folder as all collections are in
    update_all_log "$1" "$2"
    while read line; do
        if echo "$line" | grep -vEq "Title|FAILURE|done|failure"; then
            current_collection=${line/.\//}
        elif [[ "$line" == "FAILURE:"* ]]; then
            echo "Found $line     ...Process?..."
            echo "          Press any key in 1 second to skip          "
            read -t 1 -n 1 < /dev/tty
            if [ $? = 0 ]; then
                echo -e "\nSkipping..."
                sleep 0.1
                clear
                continue
            fi
            echo "          ...Processing..."
            music=$(sed 's/FAILURE:\(.*\):/\1/' <<< "$line")
            data=$(yt-dlp \
            --no-warnings \
            --print "Title:::%(title)s" \
            --print "Channel:::%(channel)s" \
            --print "Duration:::%(duration_string)s" \
            --print "URL:::%(webpage_url)s" \
            "ytsearch7:$music")
            titles=()
            channels=()
            durations=()
            urls=()
            for (( i=1; i<8; i++ )); do
                title=$(echo "$data" | sed -n '1p' | sed 's/Title:::\(.*\)/\1/')
                data=$(sed '1d' <<< "$data")
                channel=$(echo "$data" | sed -n '1p' | sed 's/Channel:::\(.*\)/\1/')
                data=$(sed '1d' <<< "$data")
                duration=$(echo "$data" | sed -n '1p' | sed 's/Duration:::\(.*\)/\1/')
                data=$(sed '1d' <<< "$data")
                url=$(echo "$data" | sed -n '1p' | sed 's/URL:::\(.*\)/\1/')
                data=$(sed '1d' <<< "$data")
                if (( i % 2 == 0 )); then
                    echo -e "\033[30;46m     Option $i     \033[37;40m\n$title\n$channel\n$duration\n$url\033[0m"
                else
                    echo -e "\033[30;46m     Option $i     \033[30;47m\n$title\n$channel\n$duration\n$url\033[0m"
                fi
                titles+=( "$title" )
                channels+=( "$channel" )
                durations+=( "$duration" )
                urls+=( "$url" )
            done
            echo "Prompting user"
            read -n 1 -p "Select a Music to download (1-7)(0:cancel all)(r:rename music)(any other:skip): " num < /dev/tty
            sleep 0.1
            if  [[ "$num" != "" ]] && echo "$(seq 7)" | grep "$num" > /dev/null; then
                download_url=${urls[$num - 1]}
                echo -e "\ndownloading ${titles[$num - 1]}"
                run_yt_dlp "$download_url" "$current_collection" "$music" "${titles[$num - 1]}" "${urls[$num - 1]}" "${durations[$num - 1]}" "$2" &
                clear
            elif [[ $num == 0 ]]; then
                echo -e "\nClosing script..."
                sleep 1
                clear
                update_all_log "$1" "$2"
                exit 0
            elif [[ $num == "r" ]]; then
                echo -e "\nname to rename"
                read -p "Type new music name: " new_name < /dev/tty
                sed -i "s/FAILURE:$music:/FAILURE:$new_name:/" "${2}/$current_collection/$current_collection.log"
                if [ $? = 0 ]; then
                    echo -e "Success! try the script again to work with updated name\nnext..."
                    update_all_log "$1" "$2"
                    sleep 1
                    clear
                fi
                continue
            else
                echo -e "\nSkipping..."
                sleep 1
                clear
                continue
            fi
        fi
    done < "${2}${1}"
}

run_yt_dlp (){
    yt-dlp "$1" \
            -x \
            -P "$7/$2" \
            -o "$3.%(ext)s" &> /dev/null
    sed -i "s|FAILURE:$3:|Title: $4, Search: $3, URL: $5, Duration: $6|" "$7/$2/$2.log"
}

update_all_log (){
    for folder in "$2"*; do
        folder=$(basename "$folder")
        if [[ ! -e "${2}/$folder/$folder.log" ]]; then
            continue
        else
        echo "$folder"
        cat "${2}/$folder"/"$folder".log
        fi
    done > "$2/$1"
}

correct_music "downloaded.log" "${1:-./}"
