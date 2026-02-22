#!/usr/bin/env bash
#
# System Update - Arrow key selection TUI
#

LOG="/tmp/pkg-update-tui.log"

RESET='\033[0m'
BOLD='\033[1m'
BG_SEL='\033[48;5;34m'
FG_SEL='\033[38;5;15m'
DIM='\033[2m'

# Detect AUR helper
aur_helper() {
  if command -v paru &>/dev/null; then echo "paru"
  elif command -v yay &>/dev/null; then echo "yay"
  else echo ""
  fi
}

AUR=$(aur_helper)

# Get update count once
if [[ -n "$AUR" ]]; then
  ALL_UPDATES=$("$AUR" -Qu 2>/dev/null)
else
  ALL_UPDATES=$(checkupdates 2>/dev/null)
fi
[[ -n "$ALL_UPDATES" ]] && TOTAL=$(echo "$ALL_UPDATES" | wc -l) || TOTAL=0

fzf_args=(
  --multi
  --preview 'pacman -Si {1} 2>/dev/null || pacman -Qi {1} 2>/dev/null'
  --preview-label='alt-p: toggle preview | alt-j/k: scroll | tab: multi-select'
  --preview-label-pos='bottom'
  --preview-window 'down:65%:wrap'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
  --color 'pointer:green,marker:green'
  --header 'Tab: multi-select | Enter: confirm | q: quit'
  --prompt '󰑓 Update: '
)

build_items() {
  ITEMS=(
    "  Update all   ($TOTAL available)"
    "  System only  (pacman)"
  )
  [[ -n "$AUR" ]] && ITEMS+=("  AUR only     ($AUR)")
  ITEMS+=(
    "  Select packages"
    "  Check available"
    "  Quit"
  )
  COUNT=${#ITEMS[@]}
}

draw_menu() {
  clear
  echo ""
  echo -e "  ${BOLD}󰑓  System Update${RESET}"
  echo "  ──────────────────────────────"
  [[ -n "$AUR" ]] && echo -e "  ${DIM}AUR helper: $AUR${RESET}" && echo ""
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

do_update_all() {
  clear
  if [[ "$TOTAL" -eq 0 ]]; then
    echo ""; echo "  ✓  System is already up to date!"
    echo ""; echo "  Press any key..."; read -n 1 -s; return
  fi
  read -rp "  Update all $TOTAL packages? [y/N]: " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo ""
    [[ -n "$AUR" ]] && "$AUR" -Syu 2>&1 | tee "$LOG" || sudo pacman -Syu 2>&1 | tee "$LOG"
    echo ""; echo "  ✓  Done! Press any key..."; read -n 1 -s
  fi
}

do_update_system() {
  clear
  read -rp "  Update system packages? [y/N]: " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo ""
    sudo pacman -Syu 2>&1 | tee "$LOG"
    echo ""; echo "  ✓  Done! Press any key..."; read -n 1 -s
  fi
}

do_update_aur() {
  clear
  if [[ -z "$AUR" ]]; then
    echo ""; echo "  ✗  No AUR helper found!"
    sleep 2; return
  fi
  read -rp "  Update AUR packages? [y/N]: " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo ""
    "$AUR" -Sua 2>&1 | tee "$LOG"
    echo ""; echo "  ✓  Done! Press any key..."; read -n 1 -s
  fi
}

do_select_update() {
  clear
  if [[ "$TOTAL" -eq 0 ]]; then
    echo ""; echo "  ✓  No updates available!"
    sleep 2; return
  fi
  pkg_names=$(echo "$ALL_UPDATES" | awk '{print $1}' | fzf "${fzf_args[@]}")
  if [[ -n "$pkg_names" ]]; then
    echo ""; echo "  Packages to update:"; echo "$pkg_names" | sed 's/^/    /'; echo ""
    read -rp "  Confirm update? [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo ""
      if [[ -n "$AUR" ]]; then
        echo "$pkg_names" | tr '\n' ' ' | xargs "$AUR" -S --noconfirm 2>&1 | tee "$LOG"
      else
        echo "$pkg_names" | tr '\n' ' ' | xargs sudo pacman -S --noconfirm 2>&1 | tee "$LOG"
      fi
      echo ""; echo "  ✓  Done! Press any key..."; read -n 1 -s
    fi
  fi
}

do_check() {
  clear; echo ""
  if [[ "$TOTAL" -eq 0 ]]; then
    echo "  ✓  System is already up to date!"
  else
    echo "  Available updates ($TOTAL):"; echo ""
    echo "$ALL_UPDATES" | awk '{printf "  %-28s  %s  →  %s\n", $1, $2, $4}'
  fi
  echo ""; echo "  Press any key..."; read -n 1 -s
  # Refresh counts after check
  if [[ -n "$AUR" ]]; then
    ALL_UPDATES=$("$AUR" -Qu 2>/dev/null)
  else
    ALL_UPDATES=$(checkupdates 2>/dev/null)
  fi
  [[ -n "$ALL_UPDATES" ]] && TOTAL=$(echo "$ALL_UPDATES" | wc -l) || TOTAL=0
  build_items
}

run_selection() {
  # Determine quit index dynamically
  local quit_idx=$(( COUNT - 1 ))
  local aur_offset=0
  [[ -n "$AUR" ]] && aur_offset=1

  if [[ $SELECTED -eq $quit_idx ]]; then
    clear; exit 0
  fi

  case $SELECTED in
    0) do_update_all ;;
    1) do_update_system ;;
    2) [[ -n "$AUR" ]] && do_update_aur || do_select_update ;;
    3) [[ -n "$AUR" ]] && do_select_update || do_check ;;
    4) [[ -n "$AUR" ]] && do_check ;;
  esac
}

SELECTED=0
build_items

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
