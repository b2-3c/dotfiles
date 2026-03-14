#!/usr/bin/env bash
#
# Bluetooth Menu - قائمة البلوتوث عبر rofi
# يستخدم bluetoothctl للتحكم بالأجهزة
#

ROFI_CONF="$HOME/.config/rofi"

rofi_menu() {
    rofi -dmenu -theme-str 'textbox-custom { content: "󰂯 Bluetooth"; }' -p "$1" -config "$ROFI_CONF/launcher-menu.rasi"
}

notify() {
    notify-send "$1" "$2" --icon="${3:-bluetooth}"
}

# ───────────────────────────────────────────
# الحالة الحالية
# ───────────────────────────────────────────
get_status() {
    BT_STATE=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
    if [ "$BT_STATE" != "yes" ]; then
        echo "Bluetooth: OFF"
        return
    fi
    CONNECTED=$(bluetoothctl devices Connected 2>/dev/null | awk -F' ' '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}' | head -1 | xargs)
    if [ -n "$CONNECTED" ]; then
        echo "Connected: $CONNECTED"
    else
        echo "Bluetooth: ON — no devices connected"
    fi
}

# ───────────────────────────────────────────
# القائمة الرئيسية
# ───────────────────────────────────────────
show_main() {
    STATUS=$(get_status)
    BT_STATE=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')

    if [ "$BT_STATE" = "yes" ]; then
        BT_TOGGLE="󰂲  Turn Bluetooth Off"
    else
        BT_TOGGLE="󰂯  Turn Bluetooth On"
    fi

    printf '%s\n' \
        "󰂯  My Devices" \
        "󰂴  Scan & Pair New Device" \
        "$BT_TOGGLE" \
        "󰋑  Adapter Info" \
    | rofi -dmenu -theme-str 'textbox-custom { content: "󰂯 Bluetooth"; }' -p "󰂯  Bluetooth" \
           -mesg "$STATUS" \
           -config "$ROFI_CONF/launcher-menu.rasi"
}

# ───────────────────────────────────────────
# تبديل البلوتوث
# ───────────────────────────────────────────
do_bt_toggle() {
    BT_STATE=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
    if [ "$BT_STATE" = "yes" ]; then
        bluetoothctl power off &>/dev/null
        notify "󰂲  Bluetooth" "Bluetooth turned off"
    else
        rfkill unblock bluetooth
        bluetoothctl power on &>/dev/null
        notify "󰂯  Bluetooth" "Bluetooth turned on"
    fi
}

# ───────────────────────────────────────────
# الأجهزة المحفوظة
# ───────────────────────────────────────────
do_my_devices() {
    BT_STATE=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
    if [ "$BT_STATE" != "yes" ]; then
        notify "󰂲  Bluetooth Off" "Turn on Bluetooth first" "dialog-warning"
        return
    fi

    # جلب الأجهزة المحفوظة مع حالة الاتصال
    DEVICES=$(bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
        [ -z "$mac" ] && continue
        IS_CONNECTED=$(bluetoothctl info "$mac" 2>/dev/null | grep "Connected:" | awk '{print $2}')
        IS_PAIRED=$(bluetoothctl info "$mac" 2>/dev/null | grep "Paired:" | awk '{print $2}')
        TYPE=$(bluetoothctl info "$mac" 2>/dev/null | grep "Icon:" | awk '{print $2}')

        # أيقونة حسب النوع
        case "$TYPE" in
            audio-headset|audio-headphones) ICON="󰋌" ;;
            input-keyboard)                 ICON="󰌌" ;;
            input-mouse)                    ICON="󰍽" ;;
            phone)                          ICON="󰄜" ;;
            computer)                       ICON="󰍹" ;;
            audio-card|audio-speakers)      ICON="󰓃" ;;
            *)                              ICON="󰂯" ;;
        esac

        if [ "$IS_CONNECTED" = "yes" ]; then
            printf "● %s %s  [connected]\n" "$ICON" "$name"
        else
            printf "  %s %s\n" "$ICON" "$name"
        fi
    done)

    if [ -z "$DEVICES" ]; then
        notify "󰂯  No Devices" "No paired devices found" "dialog-warning"
        return
    fi

    CHOICE=$(echo "$DEVICES" | rofi -dmenu -theme-str 'textbox-custom { content: "󰂯 Bluetooth"; }' -p "󰂯  My Devices" \
        -config "$ROFI_CONF/launcher-menu.rasi")
    [ -z "$CHOICE" ] && return

    # استخراج اسم الجهاز
    DEV_NAME=$(echo "$CHOICE" | sed 's/^[●[:space:]]*//' | sed 's/^[^ ]* //' | sed 's/  \[connected\]//' | xargs)
    MAC=$(bluetoothctl devices 2>/dev/null | grep "$DEV_NAME" | awk '{print $2}')
    [ -z "$MAC" ] && return

    IS_CONNECTED=$(bluetoothctl info "$MAC" 2>/dev/null | grep "Connected:" | awk '{print $2}')

    if [ "$IS_CONNECTED" = "yes" ]; then
        ACTION=$(printf '%s\n%s\n%s' "Disconnect" "Remove device" "Cancel" \
            | rofi -dmenu -theme-str 'textbox-custom { content: "󰂯 Bluetooth"; }' -p "󰂯  $DEV_NAME" -config "$ROFI_CONF/launcher-menu.rasi")
        case "$ACTION" in
            "Disconnect")
                bluetoothctl disconnect "$MAC" &>/dev/null
                notify "󰂲  Disconnected" "$DEV_NAME"
                ;;
            "Remove device")
                CONFIRM=$(printf '%s\n%s' "Yes, remove $DEV_NAME" "Cancel" \
                    | rofi -dmenu -theme-str 'textbox-custom { content: "󰂯 Bluetooth"; }' -p "󰂯  Remove?" -config "$ROFI_CONF/launcher-menu.rasi")
                if [ "$CONFIRM" = "Yes, remove $DEV_NAME" ]; then
                    bluetoothctl remove "$MAC" &>/dev/null
                    notify "󰂯  Removed" "$DEV_NAME"
                fi
                ;;
        esac
    else
        ACTION=$(printf '%s\n%s\n%s' "Connect" "Remove device" "Cancel" \
            | rofi -dmenu -theme-str 'textbox-custom { content: "󰂯 Bluetooth"; }' -p "󰂯  $DEV_NAME" -config "$ROFI_CONF/launcher-menu.rasi")
        case "$ACTION" in
            "Connect")
                notify "󰂯  Connecting" "$DEV_NAME ..."
                bluetoothctl connect "$MAC" &>/dev/null
                if bluetoothctl info "$MAC" 2>/dev/null | grep -q "Connected: yes"; then
                    notify "✓  Connected" "$DEV_NAME" "dialog-ok"
                else
                    notify "✗  Failed" "Could not connect to $DEV_NAME" "dialog-error"
                fi
                ;;
            "Remove device")
                CONFIRM=$(printf '%s\n%s' "Yes, remove $DEV_NAME" "Cancel" \
                    | rofi -dmenu -theme-str 'textbox-custom { content: "󰂯 Bluetooth"; }' -p "󰂯  Remove?" -config "$ROFI_CONF/launcher-menu.rasi")
                if [ "$CONFIRM" = "Yes, remove $DEV_NAME" ]; then
                    bluetoothctl remove "$MAC" &>/dev/null
                    notify "󰂯  Removed" "$DEV_NAME"
                fi
                ;;
        esac
    fi
}

# ───────────────────────────────────────────
# مسح وإقران جهاز جديد
# ───────────────────────────────────────────
do_scan_pair() {
    BT_STATE=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
    if [ "$BT_STATE" != "yes" ]; then
        notify "󰂲  Bluetooth Off" "Turn on Bluetooth first" "dialog-warning"
        return
    fi

    notify "󰂴  Scanning" "Scanning for nearby devices (10s)..."

    # مسح لمدة 10 ثوانٍ في الخلفية
    bluetoothctl scan on &>/dev/null &
    SCAN_PID=$!
    sleep 10
    kill $SCAN_PID 2>/dev/null
    bluetoothctl scan off &>/dev/null

    # جلب الأجهزة الجديدة (غير المقترنة)
    NEW_DEVICES=$(bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
        [ -z "$mac" ] && continue
        IS_PAIRED=$(bluetoothctl info "$mac" 2>/dev/null | grep "Paired:" | awk '{print $2}')
        [ "$IS_PAIRED" = "yes" ] && continue
        echo "  󰂯 $name  [$mac]"
    done)

    if [ -z "$NEW_DEVICES" ]; then
        notify "󰂴  Not Found" "No new devices found nearby" "dialog-warning"
        return
    fi

    CHOICE=$(echo "$NEW_DEVICES" | rofi -dmenu -theme-str 'textbox-custom { content: "󰂯 Bluetooth"; }' -p "󰂴  Select Device to Pair" \
        -config "$ROFI_CONF/launcher-menu.rasi")
    [ -z "$CHOICE" ] && return

    # استخراج MAC
    MAC=$(echo "$CHOICE" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')
    DEV_NAME=$(echo "$CHOICE" | sed 's/.*󰂯 //' | sed 's/  \[.*//' | xargs)
    [ -z "$MAC" ] && return

    notify "󰂴  Pairing" "$DEV_NAME ..."
    bluetoothctl pair "$MAC" &>/dev/null
    sleep 1
    bluetoothctl trust "$MAC" &>/dev/null
    bluetoothctl connect "$MAC" &>/dev/null

    if bluetoothctl info "$MAC" 2>/dev/null | grep -q "Connected: yes"; then
        notify "✓  Paired & Connected" "$DEV_NAME" "dialog-ok"
    elif bluetoothctl info "$MAC" 2>/dev/null | grep -q "Paired: yes"; then
        notify "✓  Paired" "$DEV_NAME (connect manually)" "dialog-ok"
    else
        notify "✗  Failed" "Could not pair with $DEV_NAME" "dialog-error"
    fi
}

# ───────────────────────────────────────────
# معلومات الـ Adapter
# ───────────────────────────────────────────
do_adapter_info() {
    INFO=$(bluetoothctl show 2>/dev/null | awk '
        /Name:/        { name=$2 }
        /Powered:/     { powered=$2 }
        /Discoverable:/{ disc=$2 }
        /Pairable:/    { pair=$2 }
        /Address:/     { addr=$2 }
        END {
            printf "Address:       %s\nName:          %s\nPowered:       %s\nDiscoverable:  %s\nPairable:      %s",
            addr, name, powered, disc, pair
        }')

    echo "$INFO" | rofi -dmenu -theme-str 'textbox-custom { content: "󰂯 Bluetooth"; }' -p "󰋑  Adapter Info" \
        -no-custom \
        -config "$ROFI_CONF/launcher-menu.rasi"
}

# ───────────────────────────────────────────
# Main
# ───────────────────────────────────────────
CHOICE=$(show_main)
[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    "󰂯  My Devices")             do_my_devices ;;
    "󰂴  Scan & Pair New Device") do_scan_pair  ;;
    "󰂲  Turn Bluetooth Off")     do_bt_toggle  ;;
    "󰂯  Turn Bluetooth On")      do_bt_toggle  ;;
    "󰋑  Adapter Info")           do_adapter_info ;;
esac
