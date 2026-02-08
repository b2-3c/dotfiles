#!/usr/bin/env bash

if ! command -v gum &>/dev/null; then
    exit 1
fi

if [ ! -f /etc/arch-release ]; then
  exit 0
fi

display_logo() {
    cat << "EOF"
   ____         __              __  __        __     __     
  / __/_ _____ / /____ __ _    / / / /__  ___/ /__ _/ /____ 
 _\ \/ // (_-</ __/ -_)  ' \  / /_/ / _ \/ _  / _ `/ __/ -_)
/___/\_, /___/\__/\__/_/_/_/  \____/ .__/\_,_/\_,_/\__/\__/ 
    /___/                         /_/                       
EOF
}

pkg_installed() {
  local pkg=$1
  if pacman -Qi "${pkg}" &>/dev/null; then
    return 0
  elif pacman -Qi "flatpak" &>/dev/null && flatpak info "${pkg}" &>/dev/null; then
    return 0
  elif command -v "${pkg}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

get_aur_helper() {
  if pkg_installed yay; then
    aur_helper="yay"
  elif pkg_installed paru; then
    aur_helper="paru"
  fi
}

get_aur_helper
export -f pkg_installed

if [ "$1" == "up" ]; then
  trap 'pkill -RTMIN+20 waybar' EXIT
  
  kitty --title "󰞒 System Update" sh -c "
    $(declare -f display_logo)
    display_logo
    printf '\n'

    if gum confirm 'Would you like to update now?' --affirmative 'Update now!' --negative 'Skip updating!' --prompt.foreground '#eabbd1' --selected.background '#eabbd1' --selected.foreground '#09080A'; then
        $0 upgrade
        ${aur_helper} -Syu
        if pkg_installed flatpak; then flatpak update; fi
        printf '\nDone!'
        sleep 2
    else
        gum spin --spinner dot --spinner.foreground '#eabbd1' --title 'Skipping...' -- sleep 2
    fi
  "
  exit
fi

if [ -n "$aur_helper" ]; then
  aur_updates=$(${aur_helper} -Qua | grep -c '^')
else
  aur_updates=0
fi

official_updates=$( (while pgrep -x checkupdates >/dev/null; do sleep 1; done); checkupdates | grep -c '^' )

if pkg_installed flatpak; then
  flatpak_updates=$(flatpak remote-ls --updates | grep -c '^')
else
  flatpak_updates=0
fi

total_updates=$((official_updates + aur_updates + flatpak_updates))

if [ "${1}" == "upgrade" ]; then
  printf "Official:  %-10s\nAUR ($aur_helper): %-10s\nFlatpak:   %-10s\n\n" "$official_updates" "$aur_updates" "$flatpak_updates"
  exit
fi

if [ $total_updates -eq 0 ]; then
  echo "{\"text\":\"󰸟\", \"tooltip\":\"Up to date\"}"
else
  tooltip="Official: $official_updates\nAUR: $aur_updates\nFlatpak: $flatpak_updates"
  echo "{\"text\":\"󰞒\", \"tooltip\":\"${tooltip}\"}"
fi
