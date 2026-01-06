#!/usr/bin/env bash

# Volume control with mako OSD notifications

case "$1" in
up)
   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
   ;;
down)
   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
   ;;
mute)
   wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
   ;;
*)
   echo "Usage: $0 {up|down|mute}"
   exit 1
   ;;
esac

# Get current volume and mute status
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
muted=$(echo "$volume" | grep -o "MUTED")
volume_percent=$(echo "$volume" | awk '{print int($2 * 100)}')

# Send notification
if [ -n "$muted" ]; then
   notify-send -h string:x-canonical-private-synchronous:volume \
      -h int:value:0 \
      -t 2000 \
      "🔇"
else
   notify-send -h string:x-canonical-private-synchronous:volume \
      -h int:value:"$volume_percent" \
      -t 2000 \
      "Volume"
fi
