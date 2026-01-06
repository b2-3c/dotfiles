#!/usr/bin/env bash

bar_visible=true
trap "pkill waybar; exit" SIGINT SIGTERM

waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css >/dev/null 2>&1 &

while true; do
    Y=$(hyprctl cursorpos -j | jq '.y' 2>/dev/null)

    [[ -z "$Y" ]] && sleep 0.1 && continue

    if (( Y <= 5 )) && $bar_visible; then
        pkill waybar
        bar_visible=false
    elif (( Y > 40 )) && ! $bar_visible; then
        waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css >/dev/null 2>&1 &
        bar_visible=true
    fi

    sleep 0.1
done
