#!/usr/bin/env bash
#
# Wallpaper Menu
#

ROFI_CONF="$HOME/.config/rofi"
WALLPAPER_DIR="$HOME/Wallpapers/Pictures"
WALLPAPER_STATE="$HOME/.config/swww/current_wallpaper"
AVATAR_DIR="$HOME/Wallpapers/Users"
USER_FACE="$HOME/.local/share/user.jpeg"
THUMB_DIR="/tmp/rofi-wallpaper-thumbs"
TITLE_STR='textbox-custom { content: "󰸉 Wallpapers"; }'

mkdir -p "$THUMB_DIR"
mkdir -p "$(dirname "$WALLPAPER_STATE")"

notify() {
    notify-send "$1" "$2" --icon="${3:-preferences-desktop-wallpaper}"
}

get_monitors() {
    hyprctl monitors -j 2>/dev/null | python3 -c "
import json, sys
monitors = json.load(sys.stdin)
for m in monitors:
    print(m['name'])
" 2>/dev/null || echo "eDP-1"
}

generate_thumb() {
    local IMG="$1"
    local NAME
    NAME=$(basename "$IMG")
    local THUMB="$THUMB_DIR/${NAME%.*}.png"
    if [ ! -f "$THUMB" ]; then
        convert "$IMG" -thumbnail 84x84^ -gravity center -extent 84x84 "$THUMB" 2>/dev/null
    fi
    echo "$THUMB"
}

# تطبيق على الشاشة (سطح المكتب)
apply_desktop() {
    local IMG="$1"
    local MONITOR="${2:-}"
    [ ! -f "$IMG" ] && notify "✗ Error" "File not found: $IMG" "dialog-error" && return 1

    if [ -n "$MONITOR" ]; then
        swww img "$IMG" --outputs "$MONITOR" \
            --transition-type fade --transition-duration 0.8 --transition-fps 60 2>/dev/null
    else
        while IFS= read -r MON; do
            swww img "$IMG" --outputs "$MON" \
                --transition-type fade --transition-duration 0.8 --transition-fps 60 2>/dev/null
        done < <(get_monitors)
    fi

    echo "$IMG" > "$WALLPAPER_STATE"
    cp "$IMG" "$LOCK_WALL" 2>/dev/null
}

# تطبيق على شاشة القفل فقط
apply_lockscreen() {
    local IMG="$1"
    [ ! -f "$IMG" ] && notify "✗ Error" "File not found: $IMG" "dialog-error" && return 1
    cp "$IMG" "$LOCK_WALL"
    notify "󰷛  Lock Screen" "$(basename "$IMG")"
}

# تطبيق على صورة الحساب (user avatar)
apply_avatar() {
    local IMG="$1"
    [ ! -f "$IMG" ] && notify "✗ Error" "File not found: $IMG" "dialog-error" && return 1
    mkdir -p "$(dirname "$USER_FACE")"
    convert "$IMG" -thumbnail 300x300^ -gravity center -extent 300x300 "$USER_FACE" 2>/dev/null \
        || cp "$IMG" "$USER_FACE"
    notify "󰀄  Avatar" "$(basename "$IMG")"
}

get_current_path() { cat "$WALLPAPER_STATE" 2>/dev/null || echo ""; }
get_current()      { basename "$(get_current_path)" 2>/dev/null || echo "Unknown"; }
get_current_lock() { [ -f "$LOCK_WALL" ] && echo "$(stat -c '%y' "$LOCK_WALL" | cut -d. -f1)" || echo "Not set"; }

list_wallpapers() {
    find "$WALLPAPER_DIR" -type f \( \
        -iname "*.jpg" -o -iname "*.jpeg" -o \
        -iname "*.png" -o -iname "*.webp" -o \
        -iname "*.gif" \
    \) 2>/dev/null | sort
}

# ── بناء قائمة الصور مع thumbnails ──────────────
build_rofi_list() {
    local CURRENT_PATH="$1"
    local ROFI_INPUT=""
    while IFS= read -r IMG; do
        NAME=$(basename "$IMG")
        THUMB=$(generate_thumb "$IMG")
        if [ "$IMG" = "$CURRENT_PATH" ]; then
            ROFI_INPUT+="● ${NAME}\x00icon\x1f${THUMB}\n"
        else
            ROFI_INPUT+="  ${NAME}\x00icon\x1f${THUMB}\n"
        fi
    done < <(list_wallpapers)
    echo "$ROFI_INPUT"
}

pick_wallpaper() {
    local PROMPT="$1"
    local CURRENT_PATH="$2"
    local ROFI_INPUT
    ROFI_INPUT=$(build_rofi_list "$CURRENT_PATH")

    [ -z "$ROFI_INPUT" ] && notify "󰸉  Empty" "No wallpapers found in $WALLPAPER_DIR" "dialog-warning" && return 1

    local CHOICE
    CHOICE=$(printf "%b" "$ROFI_INPUT" | rofi -dmenu \
        -p "$PROMPT" \
        -config "$ROFI_CONF/wallpaper-menu.rasi")

    [ -z "$CHOICE" ] && return 1

    local NAME
    NAME=$(echo "$CHOICE" | sed 's/^[● ]*//' | xargs)
    echo "$WALLPAPER_DIR/$NAME"
}

# ── القائمة الرئيسية ─────────────────────────────
show_main() {
    CURRENT=$(get_current)
    COUNT=$(list_wallpapers | wc -l)
    printf '%s\n' \
        "󰸉  Desktop Wallpaper" \
        "󰷛  Lock Screen Wallpaper" \
        "󰀄  Account Avatar" \
        "󰑓  Random Wallpaper" \
        "󰹑  Set per Monitor" \
        "󰋩  Open Wallpaper Folder" \
    | rofi -dmenu -p "󰸉  Wallpapers" \
           -mesg "Desktop: $CURRENT  ($COUNT available)" \
           -theme-str "$TITLE_STR" \
           -config "$ROFI_CONF/launcher-menu.rasi"
}

do_desktop() {
    IMG=$(pick_wallpaper "󰸉" "$(get_current_path)") || return
    apply_desktop "$IMG"
    notify "󰸉  Wallpaper Applied" "$(basename "$IMG")"
}

do_lockscreen() {
    IMG=$(pick_wallpaper "󰷛  Lock Screen" "$LOCK_WALL") || return
    apply_lockscreen "$IMG"
}

do_avatar() {
    # تصفح من مجلد الصور الشخصية
    if [ ! -d "$AVATAR_DIR" ]; then
        notify "󰀄  Avatar" "Folder not found: $AVATAR_DIR" "dialog-warning"
        return
    fi

    ROFI_INPUT=""
    while IFS= read -r IMG; do
        NAME=$(basename "$IMG")
        THUMB=$(generate_thumb "$IMG")
        ROFI_INPUT+="  ${NAME}\x00icon\x1f${THUMB}\n"
    done < <(find "$AVATAR_DIR" -type f \( \
        -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \
    \) 2>/dev/null | sort)

    [ -z "$ROFI_INPUT" ] && notify "󰀄  Avatar" "No images found in $AVATAR_DIR" "dialog-warning" && return

    CHOICE=$(printf "%b" "$ROFI_INPUT" | rofi -dmenu \
        -p "󰀄  Avatar" \
        -config "$ROFI_CONF/wallpaper-menu.rasi")

    [ -z "$CHOICE" ] && return

    NAME=$(echo "$CHOICE" | sed 's/^[● ]*//' | xargs)
    IMG="$AVATAR_DIR/$NAME"
    apply_avatar "$IMG"
}

do_random() {
    WALLPAPERS=()
    while IFS= read -r f; do WALLPAPERS+=("$f"); done < <(list_wallpapers)
    [ ${#WALLPAPERS[@]} -eq 0 ] && notify "󰸉  Empty" "No wallpapers found" "dialog-warning" && return

    CURRENT_PATH=$(get_current_path)
    OTHERS=()
    for f in "${WALLPAPERS[@]}"; do [ "$f" != "$CURRENT_PATH" ] && OTHERS+=("$f"); done
    [ ${#OTHERS[@]} -eq 0 ] && OTHERS=("${WALLPAPERS[@]}")

    RAND_IDX=$((RANDOM % ${#OTHERS[@]}))
    IMG="${OTHERS[$RAND_IDX]}"
    apply_desktop "$IMG"
    notify "󰑓  Random Wallpaper" "$(basename "$IMG")"
}

do_per_monitor() {
    MONITORS=$(get_monitors)
    MON_COUNT=$(echo "$MONITORS" | wc -l)

    if [ "$MON_COUNT" -le 1 ]; then
        notify "󰹑  One Monitor" "Only one monitor, using Desktop"
        do_desktop; return
    fi

    MON=$(echo "$MONITORS" | rofi -dmenu -p "󰹑  Select Monitor" \
        -theme-str "$TITLE_STR" \
        -config "$ROFI_CONF/launcher-menu.rasi")
    [ -z "$MON" ] && return

    IMG=$(pick_wallpaper "󰸉  $MON" "") || return
    apply_desktop "$IMG" "$MON"
    notify "󰹑  Wallpaper Set" "$(basename "$IMG") on $MON"
}

# ── Main ─────────────────────────────────────────

if ! pgrep -x swww-daemon > /dev/null; then
    swww-daemon &
    sleep 0.5
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    WALLPAPER_DIR=$(rofi -dmenu -p "󰸉  Wallpaper folder path" \
        -theme-str "$TITLE_STR" \
        -config "$ROFI_CONF/launcher-menu.rasi" < /dev/null)
    [ -z "$WALLPAPER_DIR" ] && exit 0
fi

CHOICE=$(show_main)
[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    "󰸉  Desktop Wallpaper")     do_desktop     ;;
    "󰷛  Lock Screen Wallpaper") do_lockscreen  ;;
    "󰀄  Account Avatar")        do_avatar      ;;
    "󰑓  Random Wallpaper")      do_random      ;;
    "󰹑  Set per Monitor")       do_per_monitor ;;
    "󰋩  Open Wallpaper Folder")  xdg-open "$WALLPAPER_DIR" & ;;
esac
