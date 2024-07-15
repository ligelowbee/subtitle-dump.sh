#!/bin/bash
# subtitle-dump.sh dumps all subtitle tracks from a video file
# uses ffmpeg and zenity

vidpath="$1"
if [ -z "$vidpath" ]; then
    vidpath="$(zenity --title="${0##*/}: Select a Video File" \
        --file-selection)"
    ui="yes"
fi

[ -z "$vidpath" ] && exit

# get subs in idx,lang space separated list 
subs=$(ffprobe -v 8 -hide_banner -select_streams s \
    -show_entries "stream=index:stream_tags=language" \
    -of "csv=p=0" "$vidpath")

if [ -z "$subs" ]; then
    msg="Error, no subs found in file:\n $vidpath"
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
    subfile="${vidpath%%.???}-$idx-$lang.srt"
    ffmpeg -y -hide_banner -v 8 -i "$vidpath" -c copy -map 0:$idx "$subfile"
    echo "$subfile"
    subfiles+="\n$subfile"
done

if [ "$ui" = "yes" ]; then
    zenity --title "${0##*/}" --info \
    --text "Extracted subtitles:$subfiles"
    xdg-open "$(dirname "$vidpath")"
fi
