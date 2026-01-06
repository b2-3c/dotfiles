#!/usr/bin/env bash

# Stop Waybar when the script exits
trap "pkill waybar; exit" SIGINT SIGTERM

# Kill any running Waybar instance
pkill waybar 2>/dev/null

# Start Waybar once and keep it always visible
waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css &

while true; do
    sleep 1
done
