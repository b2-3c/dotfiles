#!/usr/bin/env bash

ROFI_CONF="$HOME/.config/rofi"
LOG="/tmp/rofi-remove.log"
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

pkg_info() {
    pacman -Qi "$1" 2>/dev/null | awk -F': ' '
        /^Name/           { name=$2 }
        /^Version/        { ver=$2 }
        /^Installed Size/ { size=$2 }
        /^Required By/    { req=$2 }
        /^Install Date/   { date=$2 }
        END { printf "Version:  %s\nSize:     %s\nRequired: %s\nDate:     %s", ver, size, req, date }'
}

main_menu() {
    printf '%s\n' "Remove package" "Remove with deps" "Remove multiple" "Remove orphans" "Remove by group" "View remove log" \
    | rofi_menu "󰗼  Remove"
}

do_remove() {
    PKG=$(pacman -Qq | rofi_menu "󰗼  Select package")
    [ -z "$PKG" ] && return
    INFO=$(pkg_info "$PKG")
    DEPS=$(pacman -Qi "$PKG" 2>/dev/null | grep "^Required By" | cut -d: -f2 | xargs)
    [ -n "$DEPS" ] && [ "$DEPS" != "None" ] && WARN="⚠ Required by: $DEPS" || WARN="Safe to remove"
    CONFIRM=$(printf '%s\n%s' "Remove $PKG" "Cancel" \
        | rofi -dmenu -p "󰗼  $PKG" -mesg "$INFO\n$WARN" -config "$ROFI_CONF/launcher-menu.rasi")
    [ "$CONFIRM" != "Remove $PKG" ] && return
    _remove "-R" "$PKG"
}

do_remove_deps() {
    PKG=$(pacman -Qq | rofi_menu "󰗼  Remove + deps")
    [ -z "$PKG" ] && return
    WILL_REMOVE=$(sudo_rofi pacman -Rns --print "$PKG" 2>/dev/null | tr '\n' ' ')
    CONFIRM=$(printf '%s\n%s' "Remove $PKG + deps" "Cancel" \
        | rofi -dmenu -p "󰗼  $PKG + deps" -mesg "Will remove:\n$WILL_REMOVE" -config "$ROFI_CONF/launcher-menu.rasi")
    [ "$CONFIRM" != "Remove $PKG + deps" ] && return
    _remove "-Rns" "$PKG"
}

do_remove_multi() {
    SELECTED=""
    while true; do
        HEADER="Selected: ${SELECTED:-none}   |   Type 'DONE' to remove · 'CLEAR' to reset"
        CHOICE=$(pacman -Qq | rofi -dmenu -p "󰗼  Multi-Remove" \
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
    CONFIRM=$(printf '%s\n%s' "Remove $COUNT packages" "Cancel" \
        | rofi -dmenu -p "󰗼  Confirm" \
               -mesg "$(echo "$SELECTED" | tr ' ' '\n')" \
               -config "$ROFI_CONF/launcher-menu.rasi")
    if [ "$CONFIRM" = "Remove $COUNT packages" ]; then
        auth_sudo || return
        notify "󰗼  Removing" "$COUNT packages ..."
        (
            sudo_rofi pacman -Rns --noconfirm $SELECTED > "$LOG" 2>&1
            if [ $? -eq 0 ]; then
                notify "✓  Removed" "$COUNT packages removed" "dialog-ok"
            else
                notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
            fi
        ) &
    fi
}

do_remove_orphans() {
    ORPHANS=$(pacman -Qdtq 2>/dev/null)
    if [ -z "$ORPHANS" ]; then
        notify "✓  Clean" "No orphan packages found" "dialog-ok"
        return
    fi
    COUNT=$(echo "$ORPHANS" | wc -l)
    PREVIEW=$(echo "$ORPHANS" | head -10)
    CONFIRM=$(printf '%s\n%s\n%s' "Yes, remove $COUNT orphans" "View all" "Cancel" \
        | rofi -dmenu -p "󰗼  Orphans found" -mesg "$PREVIEW" -config "$ROFI_CONF/launcher-menu.rasi")
    case "$CONFIRM" in
        "Yes, remove $COUNT orphans")
            auth_sudo || return
            notify "󰗼  Removing" "$COUNT orphan packages ..."
            (
                sudo_rofi pacman -Rns --noconfirm $ORPHANS > "$LOG" 2>&1
                if [ $? -eq 0 ]; then
                    notify "✓  Cleaned" "$COUNT orphans removed" "dialog-ok"
                else
                    notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
                fi
            ) &
            ;;
        "View all")
            PKG=$(echo "$ORPHANS" | rofi_menu "󰗼  Orphans — select to remove")
            [ -n "$PKG" ] && _remove "-Rns" "$PKG"
            ;;
    esac
}

do_remove_group() {
    GROUPS=$(pacman -Qq | xargs pacman -Qi 2>/dev/null | grep "^Groups" | awk -F': ' '{print $2}' | sort -u | grep -v "None")
    if [ -z "$GROUPS" ]; then
        notify "󰋽  Groups" "No package groups found"
        return
    fi
    GROUP=$(echo "$GROUPS" | rofi_menu "󰗼  Remove group")
    [ -z "$GROUP" ] && return
    PKGS=$(pacman -Qg "$GROUP" 2>/dev/null | awk '{print $2}')
    COUNT=$(echo "$PKGS" | wc -l)
    CONFIRM=$(printf '%s\n%s' "Yes, remove group" "Cancel" \
        | rofi -dmenu -p "󰗼  Group: $GROUP" -mesg "Packages ($COUNT):\n$PKGS" -config "$ROFI_CONF/launcher-menu.rasi")
    [ "$CONFIRM" != "Yes, remove group" ] && return
    auth_sudo || return
    notify "󰗼  Removing group" "$GROUP ($COUNT packages) ..."
    (
        sudo_rofi pacman -Rns --noconfirm $PKGS > "$LOG" 2>&1
        if [ $? -eq 0 ]; then
            notify "✓  Removed" "Group $GROUP removed" "dialog-ok"
        else
            notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
        fi
    ) &
}

do_view_log() {
    [ ! -f "$LOG" ] && notify "󰋽  Log" "No remove log found" && return
    tail -30 "$LOG" | rofi -dmenu -p "󰋽  Remove Log" -no-custom -config "$ROFI_CONF/launcher-menu.rasi"
}

_remove() {
    auth_sudo || return
    notify "󰗼  Removing" "$2 ..."
    (
        sudo_rofi pacman "$1" --noconfirm "$2" > "$LOG" 2>&1
        if [ $? -eq 0 ]; then
            notify "✓  Removed" "$2 removed" "dialog-ok"
        else
            notify "✗  Failed" "$(tail -3 "$LOG")" "dialog-error"
        fi
    ) &
}

CHOICE=$(main_menu)
[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    "Remove package")    do_remove         ;;
    "Remove with deps")  do_remove_deps    ;;
    "Remove multiple")   do_remove_multi   ;;
    "Remove orphans")    do_remove_orphans ;;
    "Remove by group")   do_remove_group   ;;
    "View remove log")   do_view_log       ;;
esac
