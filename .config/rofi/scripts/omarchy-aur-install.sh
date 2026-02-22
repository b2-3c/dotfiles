#!/usr/bin/env bash
#
# Omarchy AUR Installer - داخل rofi بالكامل
#

ROFI_CONF="$HOME/.config/rofi"
LOG="/tmp/omarchy-aur-install.log"
CACHE="/tmp/omarchy-aur-cache.txt"
ASKPASS="$HOME/.config/rofi/scripts/rofi-askpass.sh"

rofi_menu() {
    rofi -dmenu -p "$1" -config "$ROFI_CONF/launcher-menu.rasi"
}

notify() {
    notify-send "$1" "$2" --icon="${3:-dialog-information}"
}

# التحقق من أن sudo صالح، وإلا طلب الباسورد عبر rofi مرة واحدة
auth_sudo() {
    if ! sudo -n true 2>/dev/null; then
        SUDO_ASKPASS="$ASKPASS" sudo -A true 2>/dev/null
        if [ $? -ne 0 ]; then
            notify "󰌆  Auth Failed" "Wrong password or cancelled" "dialog-error"
            return 1
        fi
    fi
    return 0
}

check_aur_helper() {
    if command -v yay &>/dev/null; then
        echo "yay"
    elif command -v paru &>/dev/null; then
        echo "paru"
    else
        notify "󰅙  Error" "No AUR helper found (yay or paru)" "dialog-error"
        exit 1
    fi
}

pkg_info() {
    local helper="$1"
    "$helper" -Si "$2" 2>/dev/null | awk -F': ' '
        /^Name/           { name=$2 }
        /^Version/        { ver=$2 }
        /^Description/    { desc=$2 }
        /^Installed Size/ { size=$2 }
        END { printf "Name:     %s\nVersion:  %s\nSize:     %s\nDesc:     %s",
              name, ver, size, desc }'
}

build_cache() {
    local helper="$1"
    if [ ! -f "$CACHE" ] || [ $(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) )) -gt 600 ]; then
        "$helper" -Slqa 2>/dev/null > "$CACHE"
    fi
}

_install() {
    local helper="$1"
    local pkg="$2"
    # yay/paru يتعاملان مع sudo داخلياً، لكن نوفر ASKPASS لهم
    auth_sudo || return
    notify "󰄠  Installing" "$pkg (AUR)..."
    (
        SUDO_ASKPASS="$ASKPASS" "$helper" -S --noconfirm "$pkg" > "$LOG" 2>&1
        if [ $? -eq 0 ]; then
            notify "✓  Installed" "$pkg installed successfully" "dialog-ok"
        else
            notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
        fi
    ) &
}

do_search() {
    local helper="$1"

    QUERY=$(rofi -dmenu -p "󰍉 AUR Search" -config "$ROFI_CONF/launcher-menu.rasi" < /dev/null)
    [ -z "$QUERY" ] && return

    notify "󰄠  Searching AUR" "$QUERY ..."
    RESULTS=$("$helper" -Ssa "$QUERY" 2>/dev/null | grep -E "^aur/" | awk '{print $1}' | sed 's|aur/||')

    if [ -z "$RESULTS" ]; then
        notify "󰅙  Not Found" "No AUR packages for: $QUERY" "dialog-warning"
        return
    fi

    PKG=$(echo "$RESULTS" | rofi_menu "󰄠  AUR Results")
    [ -z "$PKG" ] && return

    INFO=$(pkg_info "$helper" "$PKG")
    CONFIRM=$(printf '%s\n%s' "Install $PKG" "Cancel" \
        | rofi -dmenu -p "󰄠  $PKG" -mesg "$INFO" -config "$ROFI_CONF/launcher-menu.rasi")

    [ "$CONFIRM" = "Install $PKG" ] && _install "$helper" "$PKG"
}

do_browse() {
    local helper="$1"
    build_cache "$helper"

    if [ ! -f "$CACHE" ] || [ ! -s "$CACHE" ]; then
        notify "󰔟  Loading" "Building AUR package list, please wait..."
        "$helper" -Slqa 2>/dev/null > "$CACHE"
    fi

    PKG=$(cat "$CACHE" | rofi_menu "󰄠  Browse AUR")
    [ -z "$PKG" ] && return

    INFO=$(pkg_info "$helper" "$PKG")
    CONFIRM=$(printf '%s\n%s' "Install $PKG" "Cancel" \
        | rofi -dmenu -p "󰄠  $PKG" -mesg "$INFO" -config "$ROFI_CONF/launcher-menu.rasi")

    [ "$CONFIRM" = "Install $PKG" ] && _install "$helper" "$PKG"
}

do_multi() {
    local helper="$1"
    build_cache "$helper"

    if [ ! -f "$CACHE" ] || [ ! -s "$CACHE" ]; then
        notify "󰔟  Loading" "Building AUR package list, please wait..."
        "$helper" -Slqa 2>/dev/null > "$CACHE"
    fi

    SELECTED=""
    while true; do
        HEADER="Selected: ${SELECTED:-none}   |   Type 'DONE' to install · 'CLEAR' to reset"

        CHOICE=$(cat "$CACHE" | rofi -dmenu -p "󰄠  AUR Multi-Install" \
            -mesg "$HEADER" \
            -config "$ROFI_CONF/launcher-menu.rasi")

        [ -z "$CHOICE" ] && break
        [ "$CHOICE" = "DONE" ]  && break
        [ "$CHOICE" = "CLEAR" ] && SELECTED="" && continue

        if echo "$SELECTED" | grep -qw "$CHOICE"; then
            SELECTED=$(echo "$SELECTED" | tr ' ' '\n' | grep -v "^$CHOICE$" | tr '\n' ' ' | xargs)
        else
            SELECTED=$(echo "$SELECTED $CHOICE" | xargs)
        fi
    done

    [ -z "$SELECTED" ] && return

    COUNT=$(echo "$SELECTED" | wc -w)
    CONFIRM=$(printf '%s\n%s' "Install $COUNT packages" "Cancel" \
        | rofi -dmenu -p "󰄠  Confirm" \
               -mesg "$(echo "$SELECTED" | tr ' ' '\n')" \
               -config "$ROFI_CONF/launcher-menu.rasi")

    if [ "$CONFIRM" = "Install $COUNT packages" ]; then
        auth_sudo || return
        notify "󰄠  Installing" "$COUNT AUR packages in background..."
        (
            SUDO_ASKPASS="$ASKPASS" "$helper" -S --noconfirm $SELECTED > "$LOG" 2>&1
            if [ $? -eq 0 ]; then
                notify "✓  Done" "$COUNT packages installed" "dialog-ok"
            else
                notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
            fi
        ) &
    fi
}

do_view_log() {
    [ ! -f "$LOG" ] && notify "󰋽  Log" "No AUR install log found" && return
    tail -30 "$LOG" | rofi -dmenu -p "󰋽  AUR Log" -no-custom -config "$ROFI_CONF/launcher-menu.rasi"
}

# --- Main ---
AUR_HELPER=$(check_aur_helper)
build_cache "$AUR_HELPER" &

CHOICE=$(printf '%s\n' "󰍉  Search & Install" "󰒿  Browse & Install" "󰏗  Multi Install" "󰋽  View Log" \
    | rofi_menu "󰄠  AUR Install ($AUR_HELPER)")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    "󰍉  Search & Install") do_search "$AUR_HELPER" ;;
    "󰒿  Browse & Install") do_browse "$AUR_HELPER" ;;
    "󰏗  Multi Install")    do_multi  "$AUR_HELPER" ;;
    "󰋽  View Log")         do_view_log              ;;
esac
