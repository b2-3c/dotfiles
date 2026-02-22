#!/usr/bin/env bash
set +e

# كليك يمين → فتح قائمة rofi
if [[ $SWAYNC_TOGGLE_STATE == "menu" ]]; then
    swaync-client -t  # أغلق swaync أولاً
    sleep 0.15
    bash "$HOME/.config/rofi/scripts/network-menu.sh" &
    exit 0
fi

# كليك يسار → toggle عادي
if [[ $SWAYNC_TOGGLE_STATE == true ]]; then
    rfkill unblock wifi
    nmcli radio wifi on
else
    nmcli radio wifi off
fi

exit 0
