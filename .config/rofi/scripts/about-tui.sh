#!/usr/bin/env bash
#
# About - System Info in Terminal
#

echo ""

# Use fastfetch if available, else neofetch, else manual info
if command -v fastfetch &>/dev/null; then
  fastfetch
elif command -v neofetch &>/dev/null; then
  neofetch
else
  # Manual system info display
  OS=$(grep "^PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"')
  KERNEL=$(uname -r)
  UPTIME=$(uptime -p | sed 's/up //')
  CPU=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
  MEM_USED=$(free -h | awk '/^Mem:/{print $3}')
  MEM_TOTAL=$(free -h | awk '/^Mem:/{print $2}')
  DISK=$(df -h / | awk 'NR==2{print $3"/"$2}')
  SHELL_NAME=$(basename "$SHELL")
  PKGS=$(pacman -Qq 2>/dev/null | wc -l)
  WM="Hyprland"

  echo "  ┌─────────────────────────────────────────┐"
  echo "  │              System Info                │"
  echo "  ├─────────────────────────────────────────┤"
  printf "  │  %-12s  %-26s│\n" "OS:"      "$OS"
  printf "  │  %-12s  %-26s│\n" "Kernel:"  "$KERNEL"
  printf "  │  %-12s  %-26s│\n" "WM:"      "$WM"
  printf "  │  %-12s  %-26s│\n" "Shell:"   "$SHELL_NAME"
  printf "  │  %-12s  %-26s│\n" "Uptime:"  "$UPTIME"
  printf "  │  %-12s  %-26s│\n" "CPU:"     "${CPU:0:26}"
  printf "  │  %-12s  %-26s│\n" "Memory:"  "$MEM_USED / $MEM_TOTAL"
  printf "  │  %-12s  %-26s│\n" "Disk:"    "$DISK"
  printf "  │  %-12s  %-26s│\n" "Packages:" "$PKGS (pacman)"
  echo "  └─────────────────────────────────────────┘"
fi

echo ""
echo "  Press any key to close..."
read -n 1 -s
