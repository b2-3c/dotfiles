#!/usr/bin/env bash
#
# Network Menu - قائمة الشبكة عبر rofi
# يستخدم nmcli للتحكم بالاتصالات
#

ROFI_CONF="$HOME/.config/rofi"
ASKPASS="$HOME/.config/rofi/scripts/rofi-askpass.sh"

rofi_menu() {
    rofi -dmenu -theme-str 'textbox-custom { content: "󰤨 Networks"; }' -p "$1" -config "$ROFI_CONF/launcher-menu.rasi"
}

notify() {
    notify-send "$1" "$2" --icon="${3:-network-wireless}"
}

# ───────────────────────────────────────────
# الحالة الحالية
# ───────────────────────────────────────────
get_status() {
    WIFI_STATE=$(nmcli radio wifi)
    CONNECTED=$(nmcli -t -f NAME,TYPE,STATE connection show --active 2>/dev/null \
        | grep -v "lo" | head -1)
    CONN_NAME=$(echo "$CONNECTED" | cut -d: -f1)
    CONN_TYPE=$(echo "$CONNECTED" | cut -d: -f2)

    if [ "$WIFI_STATE" = "disabled" ]; then
        echo "WiFi: OFF"
    elif echo "$CONN_TYPE" | grep -q "wireless"; then
        SIGNAL=$(nmcli -t -f IN-USE,SIGNAL,SSID device wifi list 2>/dev/null \
            | grep "^\*" | cut -d: -f2)
        echo "WiFi: $CONN_NAME ($SIGNAL%)"
    elif echo "$CONN_TYPE" | grep -q "ethernet"; then
        echo "Ethernet: $CONN_NAME"
    elif [ -n "$CONN_NAME" ]; then
        echo "Connected: $CONN_NAME"
    else
        echo "Disconnected"
    fi
}

# ───────────────────────────────────────────
# القائمة الرئيسية
# ───────────────────────────────────────────
show_main() {
    STATUS=$(get_status)
    WIFI_STATE=$(nmcli radio wifi)

    if [ "$WIFI_STATE" = "enabled" ]; then
        WIFI_TOGGLE="󰤮  Turn WiFi Off"
    else
        WIFI_TOGGLE="󰤨  Turn WiFi On"
    fi

    printf '%s\n' \
        "󰤨  Connect to WiFi" \
        "$WIFI_TOGGLE" \
        "󰁆  Active Connections" \
        "󰌆  Saved Networks" \
        "󰒢  VPN" \
        "󰛳  Network Info" \
        "󰀂  Open Network Settings" \
    | rofi -dmenu -theme-str 'textbox-custom { content: "󰤨 Networks"; }' -p "󰤨  Network" \
           -mesg "$STATUS" \
           -config "$ROFI_CONF/launcher-menu.rasi"
}

# ───────────────────────────────────────────
# اتصال WiFi
# ───────────────────────────────────────────
do_wifi_connect() {
    notify "󰤨  Scanning" "Looking for WiFi networks..."

    # مسح الشبكات مع الإشارة
    NETWORKS=$(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list 2>/dev/null \
        | awk -F: '
            {
                inuse=$1; signal=$2; sec=$3; ssid=$4
                if (ssid == "") next
                icon = (signal+0 >= 75) ? "󰤨" : (signal+0 >= 50) ? "󰤥" : (signal+0 >= 25) ? "󰤢" : "󰤟"
                lock = (sec != "--" && sec != "") ? "󰌆" : " "
                active = (inuse == "*") ? " ●" : "  "
                printf "%s%s %s %s  %s%%\n", active, icon, lock, ssid, signal
            }' \
        | sort -r)

    if [ -z "$NETWORKS" ]; then
        notify "󰤮  No Networks" "No WiFi networks found" "dialog-warning"
        return
    fi

    CHOICE=$(echo "$NETWORKS" | rofi_menu "󰤨  Select Network")
    [ -z "$CHOICE" ] && return

    # استخراج SSID من الاختيار
    SSID=$(echo "$CHOICE" | sed 's/^[[:space:]●]*//' | awk '{for(i=3;i<=NF-1;i++) printf "%s ", $i}' | xargs)

    # تحقق إذا كانت الشبكة محفوظة مسبقاً
    SAVED=$(nmcli -t -f NAME connection show 2>/dev/null | grep -Fx "$SSID")

    if [ -n "$SAVED" ]; then
        # اتصال مباشر
        notify "󰤨  Connecting" "$SSID ..."
        nmcli connection up "$SSID" &>/dev/null
        if [ $? -eq 0 ]; then
            notify "✓  Connected" "$SSID" "dialog-ok"
        else
            notify "✗  Failed" "Could not connect to $SSID" "dialog-error"
        fi
    else
        # شبكة جديدة - تحقق من الأمان
        SECURITY=$(nmcli -t -f SECURITY,SSID device wifi list 2>/dev/null \
            | grep ":${SSID}$" | cut -d: -f1 | head -1)

        if [ -n "$SECURITY" ] && [ "$SECURITY" != "--" ]; then
            # مطلوب باسورد
            PASS=$(rofi -dmenu -password \
                -p "󰌆  Password" \
                -mesg "Enter password for: $SSID" \
                -lines 0 \
                -config "$ROFI_CONF/launcher-menu.rasi")
            [ -z "$PASS" ] && return
            notify "󰤨  Connecting" "$SSID ..."
            nmcli device wifi connect "$SSID" password "$PASS" &>/dev/null
        else
            notify "󰤨  Connecting" "$SSID ..."
            nmcli device wifi connect "$SSID" &>/dev/null
        fi

        if [ $? -eq 0 ]; then
            notify "✓  Connected" "$SSID" "dialog-ok"
        else
            notify "✗  Failed" "Could not connect to $SSID" "dialog-error"
        fi
    fi
}

# ───────────────────────────────────────────
# تبديل WiFi
# ───────────────────────────────────────────
do_wifi_toggle() {
    if [ "$(nmcli radio wifi)" = "enabled" ]; then
        nmcli radio wifi off
        notify "󰤮  WiFi" "WiFi turned off"
    else
        nmcli radio wifi on
        notify "󰤨  WiFi" "WiFi turned on"
    fi
}

# ───────────────────────────────────────────
# الاتصالات النشطة
# ───────────────────────────────────────────
do_active_connections() {
    ACTIVE=$(nmcli -t -f NAME,TYPE,DEVICE,STATE connection show --active 2>/dev/null \
        | grep -v "^lo" \
        | awk -F: '{printf "%-25s  %-12s  %s\n", $1, $2, $3}')

    if [ -z "$ACTIVE" ]; then
        notify "󰁆  No Connections" "No active connections" "dialog-warning"
        return
    fi

    CHOICE=$(echo "$ACTIVE" | rofi -dmenu -theme-str 'textbox-custom { content: "󰤨 Networks"; }' -p "󰁆  Active — select to disconnect" \
        -config "$ROFI_CONF/launcher-menu.rasi")
    [ -z "$CHOICE" ] && return

    CONN_NAME=$(echo "$CHOICE" | awk '{print $1}')
    CONFIRM=$(printf '%s\n%s' "Disconnect $CONN_NAME" "Cancel" \
        | rofi -dmenu -theme-str 'textbox-custom { content: "󰤨 Networks"; }' -p "󰁆  $CONN_NAME" -config "$ROFI_CONF/launcher-menu.rasi")

    if [ "$CONFIRM" = "Disconnect $CONN_NAME" ]; then
        nmcli connection down "$CONN_NAME" &>/dev/null
        notify "󰁆  Disconnected" "$CONN_NAME"
    fi
}

# ───────────────────────────────────────────
# الشبكات المحفوظة
# ───────────────────────────────────────────
do_saved_networks() {
    SAVED=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null \
        | grep -v "lo\|bridge\|docker" \
        | awk -F: '{printf "%-30s  %s\n", $1, $2}')

    if [ -z "$SAVED" ]; then
        notify "󰌆  No Saved" "No saved networks found" "dialog-warning"
        return
    fi

    CHOICE=$(echo "$SAVED" | rofi -dmenu -theme-str 'textbox-custom { content: "󰤨 Networks"; }' -p "󰌆  Saved Networks" \
        -config "$ROFI_CONF/launcher-menu.rasi")
    [ -z "$CHOICE" ] && return

    CONN_NAME=$(echo "$CHOICE" | awk '{print $1}')

    ACTION=$(printf '%s\n%s\n%s' "Connect" "Forget (delete)" "Cancel" \
        | rofi -dmenu -theme-str 'textbox-custom { content: "󰤨 Networks"; }' -p "󰌆  $CONN_NAME" -config "$ROFI_CONF/launcher-menu.rasi")

    case "$ACTION" in
        "Connect")
            notify "󰤨  Connecting" "$CONN_NAME ..."
            nmcli connection up "$CONN_NAME" &>/dev/null
            if [ $? -eq 0 ]; then
                notify "✓  Connected" "$CONN_NAME" "dialog-ok"
            else
                notify "✗  Failed" "Could not connect to $CONN_NAME" "dialog-error"
            fi
            ;;
        "Forget (delete)")
            CONFIRM=$(printf '%s\n%s' "Yes, forget $CONN_NAME" "Cancel" \
                | rofi -dmenu -theme-str 'textbox-custom { content: "󰤨 Networks"; }' -p "󰌆  Forget?" -config "$ROFI_CONF/launcher-menu.rasi")
            if [ "$CONFIRM" = "Yes, forget $CONN_NAME" ]; then
                nmcli connection delete "$CONN_NAME" &>/dev/null
                notify "󰌆  Forgotten" "$CONN_NAME removed"
            fi
            ;;
    esac
}

# ───────────────────────────────────────────
# VPN
# ───────────────────────────────────────────
do_vpn() {
    VPNS=$(nmcli -t -f NAME,TYPE,STATE connection show 2>/dev/null \
        | grep "vpn\|wireguard\|openvpn" \
        | awk -F: '{
            state = ($3 == "activated") ? "● " : "  "
            printf "%s%s\n", state, $1
        }')

    if [ -z "$VPNS" ]; then
        notify "󰒢  No VPN" "No VPN connections configured" "dialog-warning"
        return
    fi

    CHOICE=$(echo "$VPNS" | rofi -dmenu -theme-str 'textbox-custom { content: "󰤨 Networks"; }' -p "󰒢  VPN" \
        -config "$ROFI_CONF/launcher-menu.rasi")
    [ -z "$CHOICE" ] && return

    VPN_NAME=$(echo "$CHOICE" | sed 's/^[●[:space:]]*//')
    VPN_STATE=$(nmcli -t -f STATE connection show "$VPN_NAME" 2>/dev/null | tail -1)

    if echo "$VPN_STATE" | grep -q "activated"; then
        ACTION=$(printf '%s\n%s' "Disconnect VPN" "Cancel" \
            | rofi -dmenu -theme-str 'textbox-custom { content: "󰤨 Networks"; }' -p "󰒢  $VPN_NAME (connected)" -config "$ROFI_CONF/launcher-menu.rasi")
        [ "$ACTION" = "Disconnect VPN" ] && nmcli connection down "$VPN_NAME" && notify "󰒢  VPN" "Disconnected from $VPN_NAME"
    else
        ACTION=$(printf '%s\n%s' "Connect VPN" "Cancel" \
            | rofi -dmenu -theme-str 'textbox-custom { content: "󰤨 Networks"; }' -p "󰒢  $VPN_NAME" -config "$ROFI_CONF/launcher-menu.rasi")
        if [ "$ACTION" = "Connect VPN" ]; then
            notify "󰒢  VPN" "Connecting to $VPN_NAME ..."
            nmcli connection up "$VPN_NAME" &>/dev/null
            if [ $? -eq 0 ]; then
                notify "✓  VPN Connected" "$VPN_NAME" "dialog-ok"
            else
                notify "✗  VPN Failed" "Could not connect to $VPN_NAME" "dialog-error"
            fi
        fi
    fi
}

# ───────────────────────────────────────────
# معلومات الشبكة
# ───────────────────────────────────────────
do_network_info() {
    # IP المحلي
    LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1)
    # Gateway
    GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
    # الواجهة
    IFACE=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5}' | head -1)
    # الشبكة المتصلة
    CONN=$(nmcli -t -f NAME connection show --active 2>/dev/null | grep -v lo | head -1)
    # سرعة التحميل/الرفع
    RX=$(cat /sys/class/net/${IFACE}/statistics/rx_bytes 2>/dev/null | numfmt --to=iec 2>/dev/null || echo "N/A")
    TX=$(cat /sys/class/net/${IFACE}/statistics/tx_bytes 2>/dev/null | numfmt --to=iec 2>/dev/null || echo "N/A")
    # DNS
    DNS=$(nmcli dev show "$IFACE" 2>/dev/null | grep "IP4.DNS" | awk '{print $2}' | tr '\n' ' ')

    INFO="Connection:  $CONN
Interface:   $IFACE
Local IP:    ${LOCAL_IP:-N/A}
Gateway:     ${GATEWAY:-N/A}
DNS:         ${DNS:-N/A}
Downloaded:  $RX
Uploaded:    $TX"

    echo "$INFO" | rofi -dmenu -theme-str 'textbox-custom { content: "󰤨 Networks"; }' -p "󰛳  Network Info" \
        -no-custom \
        -config "$ROFI_CONF/launcher-menu.rasi"
}

# ───────────────────────────────────────────
# Main
# ───────────────────────────────────────────
CHOICE=$(show_main)
[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    "󰤨  Connect to WiFi")       do_wifi_connect      ;;
    "󰤮  Turn WiFi Off")         do_wifi_toggle       ;;
    "󰤨  Turn WiFi On")          do_wifi_toggle       ;;
    "󰁆  Active Connections")    do_active_connections ;;
    "󰌆  Saved Networks")        do_saved_networks    ;;
    "󰒢  VPN")                   do_vpn               ;;
    "󰛳  Network Info")          do_network_info      ;;
    "󰀂  Open Network Settings") nm-connection-editor & ;;
esac
