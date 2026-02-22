#!/usr/bin/env bash
#
# Install Menu - Arrow key selection TUI
#

SCRIPT_DIR="$HOME/.config/rofi/scripts"

RESET='\033[0m'
BOLD='\033[1m'
BG_SEL='\033[48;5;33m'
FG_SEL='\033[38;5;15m'

ITEMS=(
  "  Pacman"
  "  AUR"
  "  Quit"
)
SELECTED=0
COUNT=${#ITEMS[@]}

draw_menu() {
  clear
  echo ""
  echo -e "  ${BOLD}󰄠  Install Package${RESET}"
  echo "  ──────────────────────────────"
  echo ""
  for i in "${!ITEMS[@]}"; do
    if [[ $i -eq $SELECTED ]]; then
      echo -e "  ${BG_SEL}${FG_SEL}  ${ITEMS[$i]}  ${RESET}"
    else
      echo "     ${ITEMS[$i]}"
    fi
  done
  echo ""
  echo "  ──────────────────────────────"
  echo "  ↑↓ Navigate   Enter Select   q Quit"
}

read_key() {
  IFS= read -rsn1 key
  if [[ $key == $'\x1b' ]]; then
    read -rsn2 -t 0.1 seq
    key+="$seq"
  fi
  echo "$key"
}

run_selection() {
  case $SELECTED in
    0) clear; bash "$SCRIPT_DIR/pacman-installer.sh" ;;
    1) clear; bash "$SCRIPT_DIR/aur-installer.sh" ;;
    2) clear; exit 0 ;;
  esac
}

while true; do
  draw_menu
  KEY=$(read_key)
  case "$KEY" in
    $'\x1b[A'|k)
      (( SELECTED = (SELECTED - 1 + COUNT) % COUNT )) ;;
    $'\x1b[B'|j)
      (( SELECTED = (SELECTED + 1) % COUNT )) ;;
    '')
      run_selection ;;
    q|Q)
      clear; exit 0 ;;
  esac
done
