#!/bin/bash
# script needs zenity, ffmpeg
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

# Pango clean vidname for zenity, just in case
vidname="${vidpath//&/&amp;}"
vidname="${vidname//</&lt;}"
vidname="${vidname//>/&gt;}"
if [ -z "$subs" ]; then
    zenity $zenityopts --error --text "No subtitles found in:\n$vidname"
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
sel=$(zenity $zenityopts --height 450 --list \
    --text "${vidname##*/}\nSelect a subtitle to extract:" \
    --multiple --print-column=ALL --separator=" " --hide-column 1 \
    --column "idx" --column "Language" \
    $items) 
[ -z "$sel" ] && exit

zenity $zenityopts --timeout 3 --info \
   --text "One moment, extracting...\n$sel" &

set -- $sel
while (( $# )); do
    idx=$1
    lang=$2
    shift 2
    subfile="${vidpath%.???}_${idx}_${lang}.srt"
    ffmpeg -v 8 -y -hide_banner -i "$vidpath" -map 0:$idx "$subfile"
    # Pango safe subnames for zenity
    extracted+="\n${vidname%.???}_${idx}_${lang}.srt"
done

zenity $zenityopts --info --text "Extracted file:$extracted"

