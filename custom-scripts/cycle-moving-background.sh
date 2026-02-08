#!/usr/bin/env bash

# Cycles through the background images available

BACKGROUNDS_DIR="$HOME/Wallpapers/Videos"
CURRENT_BACKGROUND_LINK="$HOME/.config/current/Wallpapers/Video"

mapfile -d '' -t BACKGROUNDS < <(find "$BACKGROUNDS_DIR" -type f -print0 | sort -z)
TOTAL=${#BACKGROUNDS[@]}

if [[ $TOTAL -eq 0 ]]; then
   notify-send "No background was found for theme" -t 2000
   pkill -x swaybg
   pkill -x mpvpaper
   swaybg --color '#000000' >/dev/null 2>&1 &
else
   # Get current background from symlink
   if [[ -L "$CURRENT_BACKGROUND_LINK" ]]; then
      CURRENT_BACKGROUND=$(readlink "$CURRENT_BACKGROUND_LINK")
   else
      # Default to first background if no symlink exists
      CURRENT_BACKGROUND=""
   fi

   # Find current background index
   INDEX=-1
   for i in "${!BACKGROUNDS[@]}"; do
      if [[ "${BACKGROUNDS[$i]}" == "$CURRENT_BACKGROUND" ]]; then
         INDEX=$i
         break
      fi
   done

   # Get next background (wrap around)
   if [[ $INDEX -eq -1 ]]; then
      # Use the first background when no match was found
      NEW_BACKGROUND="${BACKGROUNDS[0]}"
   else
      NEXT_INDEX=$(((INDEX + 1) % TOTAL))
      NEW_BACKGROUND="${BACKGROUNDS[$NEXT_INDEX]}"
   fi

   # Set new background symlink
   ln -nsf "$NEW_BACKGROUND" "$CURRENT_BACKGROUND_LINK"
   # Set wallpaper with optimized mpvpaper
   pkill swaybg
   pkill mpvpaper
   mpvpaper -o 'no-audio loop hwdec=auto vo=gpu gpu-context=wayland' '*' "$NEW_BACKGROUND" >/dev/null 2>&1 &
   # Extract a frame from the video and use it for pywal
   rm ~/.cache/wal/schemes/*Picture_png* 2>/dev/null
   # Remove Picture.png to prevent ffmpeg from following symlinks and overwriting original wallpapers
   rm -f ~/.config/current/Wallpapers/Picture.png
   ffmpeg -i "$NEW_BACKGROUND" -ss 00:00:01 -frames:v 1 ~/.config/current/Wallpapers/Picture.png -y 2>/dev/null
   wal -i ~/.config/current/Wallpapers/Picture.png -n --saturate 0.3 -q -o ~/.local/share/custom/bin/wal-color-export.sh -b 010101
fi
