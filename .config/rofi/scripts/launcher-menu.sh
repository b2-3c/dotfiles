#!/usr/bin/env bash

ROFI_CONF="$HOME/.config/rofi"
SET_THEME="$HOME/.config/hypr/scripts/set-theme"

rofi_cmd() {
    rofi -dmenu -p "$1" -config "$ROFI_CONF/launcher-menu.rasi"
}

show_main() {
    printf '%s\n' "󰕰   Apps" "󰒓   Style" "󰸉   Wallpaper" "󰄠   Install" "󰗼   Remove" "󰑓   Update" "󰌌   Keybinds" "󰋑   About" "⏻   System" \
    | rofi_cmd ""
}

menu_style() {
    THEME=$(printf '%s\n' "catppuccin-frappe" "catppuccin-latte" "catppuccin-macchiato" "catppuccin-mocha" \
        | rofi_cmd "󰒓  Theme")
    [ -z "$THEME" ] && return
    setsid -f bash "$SET_THEME" "$THEME" &>/dev/null &
}

menu_keybinds() {
    BINDS="$HOME/.config/hypr/custom/binds.conf"
    [ ! -f "$BINDS" ] && notify-send "󰌌" "binds.conf not found" && return
    grep -E "^bind" "$BINDS" | sed 's/bind[^=]*= //' | sed 's/, /  →  /g' | rofi_cmd "󰌌  Keybinds"
}

menu_about() {
    OS=$(grep "^PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"')
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p | sed 's/up //')
    CPU=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    MEM_USED=$(free -h | awk '/^Mem:/{print $3}')
    MEM_TOTAL=$(free -h | awk '/^Mem:/{print $2}')
    DISK=$(df -h / | awk 'NR==2{print $3"/"$2}')
    printf '%s\n' \
        "OS         →  $OS" "Kernel     →  $KERNEL" "DE         →  Hyprland" \
        "Shell      →  $(basename $SHELL)" "Uptime     →  $UPTIME" \
        "CPU        →  $CPU" "Memory     →  $MEM_USED / $MEM_TOTAL" "Disk       →  $DISK" \
    | rofi -dmenu -p "󰋑  About" -no-custom -config "$ROFI_CONF/launcher-menu.rasi"
}

menu_install() {
    kitty --title "Install Package" bash "$HOME/.config/rofi/scripts/install-menu-tui.sh" &
}

menu_system() {
    ACTION=$(printf '%s\n' "Lock" "Logout" "Suspend" "Reboot" "Shutdown" | rofi_cmd "⏻  System")
    case "$ACTION" in
        "Lock")     loginctl lock-session ;;
        "Logout")   hyprctl dispatch exit ;;
        "Suspend")  systemctl suspend ;;
        "Reboot")   systemctl reboot ;;
        "Shutdown") systemctl poweroff ;;
    esac
}

chosen=$(show_main)
[ -z "$chosen" ] && exit 0

case "$chosen" in
    "󰕰   Apps")     pkill rofi; rofi -show drun -show-icons -disable-history -config "$ROFI_CONF/app-launcher.rasi" ;;
    "󰒓   Style")    menu_style ;;
    "󰸉   Wallpaper") bash "$HOME/.config/rofi/scripts/wallpaper-menu.sh" ;;
    "󰄠   Install")  menu_install ;;
    "󰗼   Remove")   kitty --title "Package Removal" bash "$HOME/.config/rofi/scripts/pkg-remove-tui.sh" & ;;
    "󰑓   Update")   kitty --title "System Update"   bash "$HOME/.config/rofi/scripts/pkg-update-tui.sh" & ;;
    "󰌌   Keybinds") menu_keybinds ;;
    "󰋑   About")    kitty --title "About"            bash "$HOME/.config/rofi/scripts/about-tui.sh" & ;;
    "⏻   System")   menu_system ;;
esac
