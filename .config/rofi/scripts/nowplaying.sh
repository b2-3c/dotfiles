#!/usr/bin/env bash
#
# Now Playing - مشغل الصوت عبر rofi
# مبني على rofi-music-control بواسطة @Harsh-bin
#

# --- مسارات الملفات ---
NOWPLAYING_DIR="$HOME/.config/rofi/nowplaying"
art_file="$NOWPLAYING_DIR/album_art.png"
fallback_art_file="$NOWPLAYING_DIR/fallback_album_art.png"
rofi_theme="$NOWPLAYING_DIR/nowplaying.rasi"
cache_file="$NOWPLAYING_DIR/song_title.cache"

mkdir -p "$NOWPLAYING_DIR"

# --- تحديد المشغل النشط ---
players_list=$(playerctl -l 2>/dev/null)
active_player=""
active_player_priority=0

while IFS= read -r player; do
    [ -z "$player" ] && continue

    status=$(playerctl -p "$player" status 2>/dev/null | tr '[:upper:]' '[:lower:]')
    title=$(playerctl -p "$player" metadata title 2>/dev/null)

    current_priority=0
    if   [ "$status" = "playing" ]; then current_priority=3
    elif [ "$status" = "paused"  ]; then current_priority=2
    elif [ -n "$title"           ]; then current_priority=1
    fi

    if [ "$current_priority" -gt "$active_player_priority" ]; then
        active_player="$player"
        active_player_priority=$current_priority
    fi
done <<< "$players_list"

# تنظيف إذا لا يوجد مشغل
if [ -z "$active_player" ]; then
    rm -f "$art_file" "$cache_file"
fi

# --- دوال مساعدة ---
escape_chars() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

url_decode() {
    local url="${1//+/ }"
    printf '%b' "${url//%/\\x}"
}

# --- جلب البيانات ---
song_title="Nothing Playing"
song_artist=""
player_display_name=""

if [ -n "$active_player" ]; then
    raw_title=$(playerctl -p "$active_player" metadata title  2>/dev/null)
    raw_artist=$(playerctl -p "$active_player" metadata artist 2>/dev/null)

    clean_name="${active_player%%.*}"
    clean_name="$(tr '[:lower:]' '[:upper:]' <<< "${clean_name:0:1}")${clean_name:1}"
    player_display_name=$(escape_chars "$clean_name")
    song_title=$(escape_chars "$raw_title")
    song_artist=$(escape_chars "$raw_artist")

    # تحديث صورة الألبوم عند تغيّر الأغنية
    cached_title=""
    [ -f "$cache_file" ] && cached_title=$(cat "$cache_file")

    if [ "$raw_title" != "$cached_title" ] || [ ! -f "$art_file" ]; then
        echo "$raw_title" > "$cache_file"
        album_art_url=$(playerctl -p "$active_player" metadata mpris:artUrl 2>/dev/null)

        if [ -z "$album_art_url" ]; then
            cp "$fallback_art_file" "$art_file" 2>/dev/null
        elif [[ "$album_art_url" =~ ^data:image ]]; then
            echo "$album_art_url" | cut -d',' -f2 | base64 -d > "$art_file" 2>/dev/null
        elif [[ "$album_art_url" =~ ^file:// ]]; then
            decoded="$(url_decode "${album_art_url#file://}")"
            cp "$decoded" "$art_file" 2>/dev/null || cp "$fallback_art_file" "$art_file"
        elif [[ "$album_art_url" =~ ^https?:// ]]; then
            curl -s "$album_art_url" -o "$art_file" 2>/dev/null || cp "$fallback_art_file" "$art_file"
        else
            cp "$fallback_art_file" "$art_file" 2>/dev/null
        fi
    fi
fi

# --- أزرار التحكم ---
btn_prev="󰒮"
btn_play="󰐊"
btn_next="󰒭"
notify_action="Playing"

status=$(playerctl -p "$active_player" status 2>/dev/null)
if [ "$status" = "Playing" ]; then
    btn_play="󰏤"
    notify_action="Paused"
fi

# --- نص العرض ---
if [ -n "$player_display_name" ]; then
    status_label=$([ "$status" = "Playing" ] && echo "▶" || echo "⏸")
    display_text="<span weight='light' size='small' alpha='60%'>${player_display_name}  ${status_label}</span>\n\n${song_title}\n<span size='small' style='italic' alpha='65%'>${song_artist}</span>"
else
    display_text="<span alpha='60%'>No media player detected</span>\n\n<span size='small'>Open a player to control it</span>"
fi

# --- تشغيل rofi ---
selected=$(printf '%s\n%s\n%s' "$btn_prev" "$btn_play" "$btn_next" | \
    rofi -dmenu \
         -theme "$rofi_theme" \
         -theme-str "textbox-custom { str: \"$display_text\"; }" \
         -select "$btn_play")

[ -z "$selected" ] && exit 0

case "$selected" in
    "$btn_prev")
        playerctl -p "$active_player" previous
        notify-send "$player_display_name" "\n<big>$song_title</big>\n$song_artist" --icon="$art_file"
        ;;
    "$btn_play")
        playerctl -p "$active_player" play-pause
        notify-send "$player_display_name $notify_action" "\n<big>$song_title</big>\n$song_artist" --icon="$art_file"
        ;;
    "$btn_next")
        playerctl -p "$active_player" next
        notify-send "$player_display_name" "\n<big>$song_title</big>\n$song_artist" --icon="$art_file"
        ;;
esac
