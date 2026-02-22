#!/usr/bin/env bash

ROFI_CONF="$HOME/.config/rofi"
LOG="/tmp/rofi-update.log"
ASKPASS="$HOME/.config/rofi/scripts/rofi-askpass.sh"

rofi_menu() {
    rofi -dmenu -p "$1" -config "$ROFI_CONF/launcher-menu.rasi"
}

notify() {
    notify-send "$1" "$2" --icon="${3:-dialog-information}"
}

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

sudo_rofi() {
    SUDO_ASKPASS="$ASKPASS" sudo -A "$@"
}

# كشف AUR helper المتاح
aur_helper() {
    if command -v paru &>/dev/null; then echo "paru"
    elif command -v yay &>/dev/null; then echo "yay"
    else echo ""
    fi
}

main_menu() {
    AUR=$(aur_helper)
    if [ -n "$AUR" ]; then
        UPDATES=$("$AUR" -Qu 2>/dev/null | wc -l)
    else
        UPDATES=$(checkupdates 2>/dev/null | wc -l)
    fi
    printf '%s\n' "Update all ($UPDATES available)" "Update system only" "Update AUR only" "Select packages to update" "Check updates" "View update log" \
    | rofi_menu "󰑓  Update"
}

do_update_all() {
    AUR=$(aur_helper)
    if [ -n "$AUR" ]; then
        UPDATES=$("$AUR" -Qu 2>/dev/null)
    else
        UPDATES=$(checkupdates 2>/dev/null)
    fi
    COUNT=$(echo "$UPDATES" | grep -c "." 2>/dev/null || echo 0)
    if [ "$COUNT" -eq 0 ] || [ -z "$UPDATES" ]; then
        notify "✓  Up to date" "System is already up to date" "dialog-ok"
        return
    fi
    PREVIEW=$(echo "$UPDATES" | head -8 | awk '{printf "%-25s %s → %s\n", $1, $2, $4}')
    CONFIRM=$(printf '%s\n%s' "Yes, update all" "No, cancel" \
        | rofi -dmenu -p "󰑓  Update $COUNT packages?" -mesg "$PREVIEW" -config "$ROFI_CONF/launcher-menu.rasi")
    [ "$CONFIRM" != "Yes, update all" ] && return
    auth_sudo || return
    notify "󰑓  Updating" "$COUNT packages in background..."
    (
        if [ -n "$AUR" ]; then
            SUDO_ASKPASS="$ASKPASS" "$AUR" -Syu --noconfirm > "$LOG" 2>&1
        else
            sudo_rofi pacman -Syu --noconfirm > "$LOG" 2>&1
        fi
        if [ $? -eq 0 ]; then
            notify "✓  Updated" "$COUNT packages updated" "dialog-ok"
        else
            notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
        fi
    ) &
}

do_update_system() {
    UPDATES=$(checkupdates 2>/dev/null | wc -l)
    CONFIRM=$(printf '%s\n%s' "Yes, update system" "No, cancel" \
        | rofi_menu "󰑓  Update system ($UPDATES packages)")
    [ "$CONFIRM" != "Yes, update system" ] && return
    auth_sudo || return
    notify "󰑓  Updating system" "Running pacman -Syu ..."
    (
        sudo_rofi pacman -Syu --noconfirm > "$LOG" 2>&1
        if [ $? -eq 0 ]; then
            notify "✓  System updated" "$UPDATES packages" "dialog-ok"
        else
            notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
        fi
    ) &
}

do_update_aur() {
    AUR=$(aur_helper)
    if [ -z "$AUR" ]; then
        notify "󰅙  No AUR helper" "Install yay or paru first" "dialog-warning"
        return
    fi
    AUR_UPDATES=$("$AUR" -Qu 2>/dev/null | grep "\[AUR\]")
    [ -z "$AUR_UPDATES" ] && notify "✓  AUR up to date" "All AUR packages are current" "dialog-ok" && return
    COUNT=$(echo "$AUR_UPDATES" | wc -l)
    PREVIEW=$(echo "$AUR_UPDATES" | head -8 | awk '{printf "%-25s %s → %s\n", $1, $2, $4}')
    CONFIRM=$(printf '%s\n%s' "Yes, update AUR" "No, cancel" \
        | rofi -dmenu -p "󰑓  Update AUR ($COUNT packages)" -mesg "$PREVIEW" -config "$ROFI_CONF/launcher-menu.rasi")
    [ "$CONFIRM" != "Yes, update AUR" ] && return
    auth_sudo || return
    notify "󰑓  Updating AUR" "$COUNT packages ..."
    (
        SUDO_ASKPASS="$ASKPASS" "$AUR" -Sua --noconfirm > "$LOG" 2>&1
        if [ $? -eq 0 ]; then
            notify "✓  AUR updated" "$COUNT packages" "dialog-ok"
        else
            notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
        fi
    ) &
}

do_select_update() {
    AUR=$(aur_helper)
    if [ -n "$AUR" ]; then
        ALL_UPDATES=$("$AUR" -Qu 2>/dev/null | awk '{print $1}')
    else
        ALL_UPDATES=$(checkupdates 2>/dev/null | awk '{print $1}')
    fi
    [ -z "$ALL_UPDATES" ] && notify "✓  Up to date" "No updates available" "dialog-ok" && return

    SELECTED=""
    while true; do
        HEADER="Selected: ${SELECTED:-none}   |   Type 'DONE' to update · 'CLEAR' to reset"
        CHOICE=$(echo "$ALL_UPDATES" | rofi -dmenu -p "󰑓  Select updates" \
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
    auth_sudo || return
    notify "󰑓  Updating" "$COUNT packages ..."
    (
        if [ -n "$AUR" ]; then
            SUDO_ASKPASS="$ASKPASS" "$AUR" -S --noconfirm $SELECTED > "$LOG" 2>&1
        else
            sudo_rofi pacman -S --noconfirm $SELECTED > "$LOG" 2>&1
        fi
        if [ $? -eq 0 ]; then
            notify "✓  Updated" "$COUNT packages updated" "dialog-ok"
        else
            notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
        fi
    ) &
}

do_check_updates() {
    notify "󰑓  Checking" "Looking for updates..."
    AUR=$(aur_helper)
    if [ -n "$AUR" ]; then
        UPDATES=$("$AUR" -Qu 2>/dev/null)
    else
        UPDATES=$(checkupdates 2>/dev/null)
    fi
    if [ -z "$UPDATES" ]; then
        notify "✓  Up to date" "No updates available" "dialog-ok"
        return
    fi
    COUNT=$(echo "$UPDATES" | wc -l)
    SYS_COUNT=$(echo "$UPDATES" | grep -v "\[AUR\]" | wc -l)
    AUR_COUNT=$(echo "$UPDATES" | grep -c "\[AUR\]" || echo 0)
    HEADER="Total: $COUNT  |  System: $SYS_COUNT  |  AUR: $AUR_COUNT"
    echo "$UPDATES" | awk '{printf "%-22s  %s  →  %s\n", $1, $2, $4}' \
        | rofi -dmenu -p "󰑓  Available updates" -no-custom -mesg "$HEADER" -config "$ROFI_CONF/launcher-menu.rasi"
}

do_view_log() {
    [ ! -f "$LOG" ] && notify "󰋽  Log" "No update log found" && return
    tail -40 "$LOG" | rofi -dmenu -p "󰋽  Update Log" -no-custom -config "$ROFI_CONF/launcher-menu.rasi"
}

CHOICE=$(main_menu)
[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    Update\ all*)                do_update_all    ;;
    "Update system only")        do_update_system ;;
    "Update AUR only")           do_update_aur    ;;
    "Select packages to update") do_select_update ;;
    "Check updates")             do_check_updates ;;
    "View update log")           do_view_log      ;;
esac
