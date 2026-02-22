#!/usr/bin/env bash

DARK_THEME="TokyoNight-Dark"
LIGHT_THEME="TokyoNight-Light"

STATE=${SWAYNC_TOGGLE_STATE:-true}

swaync-client -cp >/dev/null 2>&1

if [[ $STATE == true ]]; then
    echo "Switching to DARK Mode..."
    
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme "$DARK_THEME"
    
    if [ -f "$HOME/.config/waypaper/config.ini" ]; then
        sed -i 's/-m "light"/-m "dark"/' "$HOME/.config/waypaper/config.ini"
        setsid -f waypaper --restore >/dev/null 2>&1
    fi

    notify-send -a "System" "󰖔 Dark mode is enabled"

else
    echo "Switching to LIGHT Mode..."
    
    gsettings set org.gnome.desktop.interface color-scheme 'default'
    gsettings set org.gnome.desktop.interface gtk-theme "$LIGHT_THEME"
    
    if [ -f "$HOME/.config/waypaper/config.ini" ]; then
        sed -i 's/-m "dark"/-m "light"/' "$HOME/.config/waypaper/config.ini"
        setsid -f waypaper --restore >/dev/null 2>&1
    fi

    notify-send -a "System" "󰖙 Light mode is enabled"
fi
