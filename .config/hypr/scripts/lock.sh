#!/usr/bin/env bash

WALL_CACHE="$HOME/.cache/hyprlock_wall.png"

# إذا ما في خلفية محفوظة، خذ لقطة من الشاشة
if [ ! -f "$WALL_CACHE" ]; then
    grim "$WALL_CACHE" 2>/dev/null || {
        SWWW_WALL=$(cat "$HOME/.config/swww/current_wallpaper" 2>/dev/null)
        [ -f "$SWWW_WALL" ] && cp "$SWWW_WALL" "$WALL_CACHE"
    }
fi

# جهّز غلاف الألبوم
bash "$HOME/.config/hypr/nowplaying/nowplaying.sh" &>/dev/null

# شغّل hyprlock
hyprlock --config "$HOME/.config/hypr/hyprlock.conf"
