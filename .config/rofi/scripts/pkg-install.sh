#!/usr/bin/env bash

ROFI_CONF="$HOME/.config/rofi"
LOG="/tmp/rofi-install.log"
CACHE="/tmp/rofi-pkg-cache.txt"

rofi_menu() {
    rofi -dmenu -p "$1" -config "$ROFI_CONF/launcher-menu.rasi"
}

notify() {
    notify-send "$1" "$2" --icon="${3:-dialog-information}"
}

build_cache() {
    if [ ! -f "$CACHE" ] || [ $(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) )) -gt 600 ]; then
        paru -Sl 2>/dev/null | awk '{print $2}' > "$CACHE" &
    fi
}

pkg_info() {
    paru -Si "$1" 2>/dev/null | awk -F': ' '
        /^Name/        { name=$2 }
        /^Version/     { ver=$2 }
        /^Description/ { desc=$2 }
        /^Installed Size/ { size=$2 }
        END { printf "%-12s %s\n%-12s %s\n%-12s %s\n%-12s %s",
              "Name:", name, "Version:", ver, "Size:", size, "Info:", desc }'
}

main_menu() {
    printf '%s\n' "Search & Install" "Install from list" "Install multiple" "Reinstall package" "Install from AUR only" "View install log" \
    | rofi_menu "󰄠  Install"
}

do_search_install() {
    QUERY=$(rofi -dmenu -p "Search package" -config "$ROFI_CONF/launcher-menu.rasi" < /dev/null)
    [ -z "$QUERY" ] && return
    notify "󰄠  Searching" "$QUERY ..."
    RESULTS=$(paru -Ss "$QUERY" 2>/dev/null | grep -E "^[a-z]" | awk '{print $1}' | sed 's|.*/||')
    [ -z "$RESULTS" ] && notify "󰅙 Not found" "No packages found for: $QUERY" "dialog-warning" && return
    PKG=$(echo "$RESULTS" | rofi_menu "Select package")
    [ -z "$PKG" ] && return
    INFO=$(pkg_info "$PKG")
    CONFIRM=$(printf '%s\n' "Install $PKG" "--- Info ---" "$INFO" "Cancel" | rofi_menu "󰄠  $PKG")
    [ "$CONFIRM" != "Install $PKG" ] && return
    _install "$PKG"
}

do_list_install() {
    build_cache
    if [ ! -f "$CACHE" ] || [ ! -s "$CACHE" ]; then
        notify "󰔟  Loading" "Building package list, try again in a moment..."
        paru -Sl 2>/dev/null | awk '{print $2}' > "$CACHE"
    fi
    PKG=$(cat "$CACHE" | rofi_menu "󰄠  Choose package")
    [ -z "$PKG" ] && return
    INFO=$(pkg_info "$PKG")
    CONFIRM=$(printf '%s\n' "Install $PKG" "Cancel" | rofi -dmenu -p "󰄠  $PKG" -mesg "$INFO" -config "$ROFI_CONF/launcher-menu.rasi")
    [ "$CONFIRM" != "Install $PKG" ] && return
    _install "$PKG"
}

do_multi_install() {
    PKGS=$(rofi -dmenu -p "Packages (space separated)" -config "$ROFI_CONF/launcher-menu.rasi" < /dev/null)
    [ -z "$PKGS" ] && return
    COUNT=$(echo "$PKGS" | wc -w)
    CONFIRM=$(printf 'Yes, install %s packages\nNo, cancel' "$COUNT" | rofi_menu "󰄠  Install: $PKGS")
    [[ "$CONFIRM" != Yes* ]] && return
    notify "󰄠  Installing" "$COUNT packages in background..."
    (
        paru -S --noconfirm $PKGS >"$LOG" 2>&1
        [ $? -eq 0 ] && notify "✓  Done" "$COUNT packages installed" "dialog-ok" \
                      || notify "✗  Failed" "$(tail -3 $LOG)" "dialog-error"
    ) &
}

do_reinstall() {
    PKG=$(paru -Qq | rofi_menu "󰑓  Reinstall")
    [ -z "$PKG" ] && return
    notify "󰑓  Reinstalling" "$PKG ..."
    ( paru -S --noconfirm "$PKG" >"$LOG" 2>&1
      [ $? -eq 0 ] && notify "✓  Reinstalled" "$PKG" "dialog-ok" \
                    || notify "✗  Failed" "$(tail -3 $LOG)" "dialog-error" ) &
}

do_aur_install() {
    QUERY=$(rofi -dmenu -p "AUR search" -config "$ROFI_CONF/launcher-menu.rasi" < /dev/null)
    [ -z "$QUERY" ] && return
    notify "󰄠  Searching AUR" "$QUERY ..."
    RESULTS=$(paru -Ssa "$QUERY" 2>/dev/null | grep "^aur/" | awk '{print $1}' | sed 's|aur/||')
    [ -z "$RESULTS" ] && notify "󰅙 Not found" "No AUR packages for: $QUERY" "dialog-warning" && return
    PKG=$(echo "$RESULTS" | rofi_menu "AUR packages")
    [ -z "$PKG" ] && return
    _install "$PKG"
}

do_view_log() {
    [ ! -f "$LOG" ] && notify "󰋽  Log" "No install log found" && return
    tail -30 "$LOG" | rofi -dmenu -p "󰋽  Install Log" -no-custom -config "$ROFI_CONF/launcher-menu.rasi"
}

_install() {
    notify "󰄠  Installing" "$1 ..."
    ( paru -S --noconfirm "$1" >"$LOG" 2>&1
      [ $? -eq 0 ] && notify "✓  Installed" "$1 installed successfully" "dialog-ok" \
                    || notify "✗  Failed" "$(tail -3 $LOG)" "dialog-error" ) &
}

build_cache

CHOICE=$(main_menu)
[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    "Search & Install")      do_search_install ;;
    "Install from list")     do_list_install   ;;
    "Install multiple")      do_multi_install  ;;
    "Reinstall package")     do_reinstall      ;;
    "Install from AUR only") do_aur_install    ;;
    "View install log")      do_view_log       ;;
esac
