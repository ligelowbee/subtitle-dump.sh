#!/bin/bash
# subtitle-dumb.sh dumps all subtitle tracks from a video file
# uses ffmpeg and zenity

vidname="$1"
if [ -z "$vidname" ]; then
    vidname="$(zenity --title="${0##*/}: Select a Video File" \
        --file-selection)"
    ui="yes"
fi

[ -z "$vidname" ] && exit

# get subs in idx,lang space separated list 
# awk 'NF' gets rid of empty lines
subs="$(ffprobe -hide_banner -select_streams s \
    -show_entries "stream=index:tags=language" \
    -of "csv=p=0" "$vidname" | awk 'NF' )"

if [ -z "$subs" ]; then
    msg="Error, no subs found in file:\n $vidname"
    if [ "$ui" = "yes" ]; then
        zenity --title="${0##*/}" --error --text "$msg"
    else
        echo "$msg"
    fi
    exit
fi

echo "Extracting subtitles..."
for stream in $subs; do 
    idx=${stream%%,*}
    lang=${stream##*,}
    subfile="${vidname%%.???}-$idx-$lang.srt"
    ffmpeg -y -hide_banner -v 8 -i "$vidname" -c copy -map 0:$idx "$subfile"
    echo "$subfile"
    subfiles+="\n$subfile"
done

[ "$ui" = "yes" ] && zenity --title "${0##*/}" --info \
    --text "Extracted subtitles:$subfiles"
