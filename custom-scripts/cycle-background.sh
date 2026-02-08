#!/usr/bin/env bash

# Cycles through the background images available

BACKGROUNDS_DIR="$HOME/Wallpapers/Pictures"
CURRENT_BACKGROUND_LINK="$HOME/.config/current/Wallpapers/Picture.png"

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

   # Remove old file if it exists and is not a symlink (e.g., from cycle-moving-background.sh)
   [[ -e "$CURRENT_BACKGROUND_LINK" && ! -L "$CURRENT_BACKGROUND_LINK" ]] && rm -f "$CURRENT_BACKGROUND_LINK"
   # Set new background symlink
   ln -nsf "$NEW_BACKGROUND" "$CURRENT_BACKGROUND_LINK"
   # Relaunch swaybg
   pkill swaybg
   pkill mpvpaper
   swaybg -i "$CURRENT_BACKGROUND_LINK" -m fill >/dev/null 2>&1 &
   wal -i "$NEW_BACKGROUND" -n --saturate 0.7 -q -o ~/.local/share/custom/bin/wal-color-export.sh -b 010101
   # Gamle: 0.7
fi
