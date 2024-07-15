#!/bin/bash
# script needs zenity, ffmpeg, xdg-open
# extract a selected subtitle from file

zenityopts="--title=${0##*/} "

vidpath="$1"
if [ -z "$vidpath" ]; then
    vidpath="$(zenity $zenityopts --title="${0##*/}: Select a Video File" \
        --file-selection)"
fi

[ -z "$vidpath" ] && exit

subs=$(ffprobe -v 8 -hide_banner -select_streams s \
    -show_entries "stream=index:stream_tags=language" \
    -of "csv=p=0" "$vidpath")

if [ -z "$subs" ]; then
    zenity $zenityopts --error --text "No subtitles found in:\n$vidpath"
    exit
fi

# convert list of idx[,lang] entries to one long string for zenity
items=""
for s in $subs; do
    I=${s%%,*} 
    L=${s##*,} 
    [[ $L == $I ]] && L="und"
    items+="$I $L "
done
read -r idx lang < <(zenity $zenityopts --height 450 --list \
    --text "${vidpath##*/}\nSelect a subtitle to extract:" \
    --print-column=ALL --separator=" " --hide-column 1 \
    --column "idx" --column "Language" \
    $items)
[ -z "$idx" ] && exit

subfile="${vidpath%.???}_$lang.srt"

ffmpeg -y -hide_banner -v 8 -i "$vidpath" -c copy -map 0:$idx "$subfile"

zenity $zenityopts --info --text "Extracted file:\n$subfile"

xdg-open $(dirname "$subfile")

