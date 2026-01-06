#!/usr/bin/env bash

# Brightness control with mako OSD notifications

case "$1" in
up)
   brightnessctl set +5%
   ;;
down)
   brightnessctl set 5%-
   ;;
*)
   echo "Usage: $0 {up|down}"
   exit 1
   ;;
esac

# Get current brightness percentage
brightness=$(brightnessctl info | grep -oP '\d+%' | head -1 | tr -d '%')

# Send notification
notify-send -h string:x-canonical-private-synchronous:brightness \
   -h int:value:"$brightness" \
   -t 2000 \
   "Brightness"
