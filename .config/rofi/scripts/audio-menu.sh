#!/usr/bin/env bash
#
# Audio Menu - قائمة الصوت عبر rofi
#

ROFI_CONF="$HOME/.config/rofi"
TITLE_STR='textbox-custom { content: "󰕾 Audio"; }'

rofi_menu() {
    rofi -dmenu -p "$1" \
         -theme-str "$TITLE_STR" \
         -config "$ROFI_CONF/launcher-menu.rasi"
}

notify() {
    notify-send "$1" "$2" --icon="${3:-audio-volume-high}"
}

get_status() {
    VOL=$(pamixer --get-volume 2>/dev/null || echo "0")
    MUTED=$(pamixer --get-mute 2>/dev/null || echo "true")
    SINK=$(pactl get-default-sink 2>/dev/null | sed 's/.*\.//' | head -c 30)
    if [ "$MUTED" = "true" ]; then
        echo "󰖁  Muted | $SINK"
    else
        echo "󰕾  $VOL% | $SINK"
    fi
}

show_main() {
    STATUS=$(get_status)
    MUTED=$(pamixer --get-mute 2>/dev/null || echo "true")
    if [ "$MUTED" = "true" ]; then
        MUTE_TOGGLE="󰕾  Unmute"
    else
        MUTE_TOGGLE="󰖁  Mute"
    fi
    printf '%s\n' \
        "󰕾  Volume Control" \
        "$MUTE_TOGGLE" \
        "󰋌  Output Device" \
        "󰍽  Input Device" \
        "󰁄  App Volumes" \
        "󰓃  Audio Info" \
    | rofi -dmenu -p "󰕾  Audio" \
           -mesg "$STATUS" \
           -theme-str "$TITLE_STR" \
           -config "$ROFI_CONF/launcher-menu.rasi"
}

do_volume_control() {
    VOL=$(pamixer --get-volume 2>/dev/null || echo "50")
    CHOICE=$(printf '%s\n' \
        "󰝝  Set 100%" \
        "󰝝  Set 75%" \
        "󰝝  Set 50%" \
        "󰝝  Set 25%" \
        "󰝞  Up +10%" \
        "󰝞  Down -10%" \
        "󰝝  Custom..." \
    | rofi_menu "󰕾  Volume ($VOL%)")
    [ -z "$CHOICE" ] && return
    case "$CHOICE" in
        *"100%"*) pamixer --set-volume 100 ;;
        *"75%"*)  pamixer --set-volume 75  ;;
        *"50%"*)  pamixer --set-volume 50  ;;
        *"25%"*)  pamixer --set-volume 25  ;;
        *"Up"*)   pamixer -i 10 --allow-boost ;;
        *"Down"*) pamixer -d 10 ;;
        *"Custom"*)
            VAL=$(rofi -dmenu -p "󰕾  Volume (0-150)" \
                -theme-str "$TITLE_STR" \
                -config "$ROFI_CONF/launcher-menu.rasi" < /dev/null)
            [ -z "$VAL" ] && return
            [[ "$VAL" =~ ^[0-9]+$ ]] && pamixer --set-volume "$VAL" --allow-boost
            ;;
    esac
    notify "󰕾  Volume" "$(pamixer --get-volume)%"
}

do_mute_toggle() {
    pamixer -t
    MUTED=$(pamixer --get-mute)
    if [ "$MUTED" = "true" ]; then
        notify "󰖁  Muted" "Audio muted"
    else
        notify "󰕾  Unmuted" "$(pamixer --get-volume)%"
    fi
}

do_output_device() {
    DEFAULT=$(pactl get-default-sink 2>/dev/null)
    SINKS=$(pactl list sinks 2>/dev/null | awk '
        /^Sink #/     { name="" ; desc="" }
        /^\s+Name:/   { name=$2 }
        /Description:/ { desc=substr($0, index($0,$2)) }
        /^\s+State:/  {
            if (name != "") printf "%s|%s\n", name, desc
        }')
    if [ -z "$SINKS" ]; then
        notify "󰋌  No Devices" "No output devices found" "dialog-warning"
        return
    fi
    DISPLAY_LIST=$(echo "$SINKS" | while IFS='|' read -r name desc; do
        [ "$name" = "$DEFAULT" ] && MARK="●" || MARK=" "
        printf "%s %s\n" "$MARK" "$desc"
    done)
    CHOICE=$(echo "$DISPLAY_LIST" | rofi_menu "󰋌  Output Device")
    [ -z "$CHOICE" ] && return
    DESC=$(echo "$CHOICE" | sed 's/^[● ]*//' | xargs)
    SINK_NAME=$(echo "$SINKS" | while IFS='|' read -r name desc; do
        [ "$desc" = "$DESC" ] && echo "$name" && break
    done)
    [ -z "$SINK_NAME" ] && return
    pactl set-default-sink "$SINK_NAME" &>/dev/null
    notify "󰋌  Output" "$DESC"
}

do_input_device() {
    DEFAULT=$(pactl get-default-source 2>/dev/null)
    SOURCES=$(pactl list sources 2>/dev/null | awk '
        /^Source #/   { name="" ; desc="" }
        /^\s+Name:/   { name=$2 }
        /Description:/ { desc=substr($0, index($0,$2)) }
        /^\s+State:/  {
            if (name != "" && name !~ /\.monitor$/)
                printf "%s|%s\n", name, desc
        }')
    if [ -z "$SOURCES" ]; then
        notify "󰍽  No Devices" "No input devices found" "dialog-warning"
        return
    fi
    MIC_MUTED=$(pamixer --default-source --get-mute 2>/dev/null || echo "false")
    if [ "$MIC_MUTED" = "true" ]; then
        MIC_TOGGLE="󰍭  Unmute Microphone"
    else
        MIC_TOGGLE="󰍬  Mute Microphone"
    fi
    DISPLAY_LIST=$(echo "$SOURCES" | while IFS='|' read -r name desc; do
        [ "$name" = "$DEFAULT" ] && MARK="●" || MARK=" "
        printf "%s %s\n" "$MARK" "$desc"
    done)
    CHOICE=$(printf '%s\n%s\n' "$MIC_TOGGLE" "---" && echo "$DISPLAY_LIST" \
        | rofi_menu "󰍽  Input Device")
    [ -z "$CHOICE" ] && return
    case "$CHOICE" in
        *"Mute Microphone"|*"Unmute Microphone")
            pamixer --default-source -t
            MIC_MUTED=$(pamixer --default-source --get-mute)
            if [ "$MIC_MUTED" = "true" ]; then
                notify "󰍬  Mic Muted" "Microphone muted"
            else
                notify "󰍭  Mic Active" "Microphone unmuted"
            fi
            ;;
        "---") return ;;
        *)
            DESC=$(echo "$CHOICE" | sed 's/^[● ]*//' | xargs)
            SOURCE_NAME=$(echo "$SOURCES" | while IFS='|' read -r name desc; do
                [ "$desc" = "$DESC" ] && echo "$name" && break
            done)
            [ -z "$SOURCE_NAME" ] && return
            pactl set-default-source "$SOURCE_NAME" &>/dev/null
            notify "󰍽  Input" "$DESC"
            ;;
    esac
}

do_app_volumes() {
    APPS=$(pactl list sink-inputs 2>/dev/null | awk '
        /^Sink Input #/ { id=substr($3,2) }
        /application.name/ { name=substr($0, index($0,$3)); gsub(/"/,"",name) }
        /^\s+Volume:/ {
            match($0, /[0-9]+%/, vol)
            if (id != "" && name != "")
                printf "%s|%s|%s\n", id, name, vol[0]
        }')
    if [ -z "$APPS" ]; then
        notify "󰁄  No Apps" "No apps playing audio" "dialog-warning"
        return
    fi
    DISPLAY=$(echo "$APPS" | while IFS='|' read -r id name vol; do
        printf "%-25s  %s\n" "$name" "$vol"
    done)
    CHOICE=$(echo "$DISPLAY" | rofi_menu "󰁄  App Volumes")
    [ -z "$CHOICE" ] && return
    APP_NAME=$(echo "$CHOICE" | awk '{print $1}')
    APP_ID=$(echo "$APPS" | while IFS='|' read -r id name vol; do
        echo "$name" | grep -q "$APP_NAME" && echo "$id" && break
    done)
    [ -z "$APP_ID" ] && return
    ACTION=$(printf '%s\n%s\n%s\n%s' \
        "Set 100%" "Set 75%" "Set 50%" "Mute App" \
        | rofi_menu "󰁄  $APP_NAME")
    [ -z "$ACTION" ] && return
    case "$ACTION" in
        "Set 100%") pactl set-sink-input-volume "$APP_ID" 100% ;;
        "Set 75%")  pactl set-sink-input-volume "$APP_ID" 75%  ;;
        "Set 50%")  pactl set-sink-input-volume "$APP_ID" 50%  ;;
        "Mute App") pactl set-sink-input-mute   "$APP_ID" toggle ;;
    esac
}

do_audio_info() {
    VOL=$(pamixer --get-volume 2>/dev/null || echo "N/A")
    MUTED=$(pamixer --get-mute 2>/dev/null || echo "N/A")
    SINK=$(pactl get-default-sink 2>/dev/null)
    SOURCE=$(pactl get-default-source 2>/dev/null)
    SINK_DESC=$(pactl list sinks 2>/dev/null | grep -A5 "Name: $SINK" | grep "Description" | cut -d: -f2- | xargs)
    SOURCE_DESC=$(pactl list sources 2>/dev/null | grep -A5 "Name: $SOURCE" | grep "Description" | cut -d: -f2- | xargs)
    SERVER=$(pactl info 2>/dev/null | grep "Server Name" | cut -d: -f2- | xargs)
    INFO="Volume:   $VOL%
Muted:    $MUTED
Output:   $SINK_DESC
Input:    $SOURCE_DESC
Server:   $SERVER"
    echo "$INFO" | rofi -dmenu -p "󰓃  Audio Info" \
        -no-custom \
        -theme-str "$TITLE_STR" \
        -config "$ROFI_CONF/launcher-menu.rasi"
}

# ───────────────────────────────────────────
# Main
# ───────────────────────────────────────────
CHOICE=$(show_main)
[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    "󰕾  Volume Control") do_volume_control ;;
    "󰖁  Mute")           do_mute_toggle    ;;
    "󰕾  Unmute")         do_mute_toggle    ;;
    "󰋌  Output Device")  do_output_device  ;;
    "󰍽  Input Device")   do_input_device   ;;
    "󰁄  App Volumes")    do_app_volumes    ;;
    "󰓃  Audio Info")     do_audio_info     ;;
esac
