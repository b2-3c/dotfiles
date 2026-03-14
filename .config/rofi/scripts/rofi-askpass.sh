#!/usr/bin/env bash
# rofi-askpass: يُستخدم كـ SUDO_ASKPASS لطلب الباسورد عبر rofi
rofi -dmenu \
     -password \
     -p "󰌆  Password" \
     -mesg "${1:-sudo requires your password}" \
     -lines 0 \
     -config "$HOME/.config/rofi/launcher-menu.rasi"
