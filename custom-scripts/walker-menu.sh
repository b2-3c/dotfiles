#!/usr/bin/env bash
set -euo pipefail

# THEMES — edit these
APP_THEME="--theme transparent-apps"
SYSTEM_THEME="--theme transparent-system"
POWER_THEME="--theme transparent-power"

menu() {
   local prompt="$1"
   local options="$2"
   local theme="${3:-}"

   echo -e "$options" | walker --dmenu $theme -p "$prompt…"
}

launch_apps() {
   walker $APP_THEME -p "Launch…"
}

power_menu() {
   case $(menu "Power Profile" "󰾅  Power Saver
󰾅  Balanced
󰾅  Performance" "$POWER_THEME") in
   *Power\ Saver*) powerprofilesctl set power-saver ;;
   *Balanced*) powerprofilesctl set balanced ;;
   *Performance*) powerprofilesctl set performance ;;
   *) return 0 ;;
   esac
}

system_menu() {
   case $(menu "System" "  Lock
󰤄  Suspend
󰾅  Power 
󰜉  Reboot
󰐥  Shutdown
  Logout" "$SYSTEM_THEME") in
   *Lock*) hyprlock ;;
   *Suspend*)
      hyprlock &
      systemctl suspend
      ;;
   *Power*) power_menu ;;
   *Reboot*) systemctl reboot ;;
   *Shutdown*) systemctl poweroff ;;
   *Logout*) uwsm stop ;;
   *) return 0 ;;
   esac
}

main_menu() {
   # main menu uses SYSTEM_THEME by default, can change if desired
   case $(menu "Menu" "󰀻  Apps
  System" "$SYSTEM_THEME") in
   *Apps*) launch_apps ;;
   *System*) system_menu ;;
   *) return 0 ;;
   esac
}

case "${1:-main}" in
power) power_menu ;;
system) system_menu ;;
apps) launch_apps ;;
*) main_menu ;;
esac
