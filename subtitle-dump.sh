#!/bin/bash
# subtitle-dumb.sh dumps all subtitle tracks from a video file
# uses ffmpeg and zenity

vidname="$1"
if [ -z "$vidname" ]; then
    vidname="$(zenity --title="Select video file to extract subtitles from:" --file-selection)"
    ui="yes"
fi

[ -z "$vidname" ] && exit

# get subs in idx,lang space separated list 
subs=$(ffprobe -select_streams s -show_entries "stream=index:tags=language" -of "csv=nokey=1:print_section=0" "$vidname" 2>/dev/null);
if [ -z "$subs" ]; then
    msg="Error, no subs found in file:\n $vidname"
    if [ "$ui" = "yes" ]; then
        zenity --title="${0##*/}" --error --text "$msg"
    else
        echo "$msg"
    fi
    exit
fi
for stream in $subs; do 
    idx=${stream%%,*}
    lang=${stream##*,}
    subfile="${vidname%%.???}-$idx-$lang.srt"
    ffmpeg -y -hide_banner -v 8 -i "$vidname" -c copy -map 0:$idx "$subfile"
    echo "$subfile"
    subfiles+="\n$subfile"
done

[ "$ui" = "yes" ] && zenity --title "${0##*/}" --info --text "Created:$subfiles"
