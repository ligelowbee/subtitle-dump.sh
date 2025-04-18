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
    -show_entries "stream=index:stream=codec_name:stream_tags=language" \
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
    I=$(cut -d ',' -f 1 <<< "$s")
    C=$(cut -d ',' -f 2 <<< "$s")
    if [[ "$C" =~ (dvd_subtitle|hdmv_pgs_subtitle) ]]; then
        C="${C}(image)"
    fi
    L=$(cut -d ',' -f 3 <<< "$s")
    [ -z "$L" ] && L="UND"
    items+="$I $C $L "
done
sel=$(zenity $zenityopts --height 450 --list \
    --text "${vidname##*/}\nSelect a subtitle to extract to srt\nNote: image codecs will create empty srt files" \
    --multiple --print-column=ALL --separator=" " --hide-column 1 \
    --column "idx" --column "Codec" --column "Language" \
    $items) 
[ -z "$sel" ] && exit

zenity $zenityopts --timeout 5 --info \
   --text "One moment, extracting to srt...\n$subs" &

set -- $sel
while (( $# )); do
    idx=$1
    codec=$2
    lang=$3
    shift 3
    subfile="${vidpath%.???}_${idx}_${lang}.srt"
    ffmpeg -v 8 -y -hide_banner -i "$vidpath" -map 0:$idx "$subfile"
    # use Pango safe vidname for zenity
    extracted+="\n${vidname%.???}_${idx}_${lang}.srt"
done

zenity $zenityopts --info --text "Attempted extractions to srt (subrip):$extracted"

