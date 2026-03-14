#!/bin/bash
CONFIG="$HOME/.config/swaync/config.json"

if ! command -v powerprofilesctl &>/dev/null; then
    notify-send "Battery Mode" "Install power-profiles-daemon first" --icon=battery
    exit 1
fi

CURRENT=$(powerprofilesctl get 2>/dev/null || echo "balanced")

case "$CURRENT" in
    "balanced")     NEXT="performance" ; ICON="󱐌" ; NAME="Performance" ;;
    "performance")  NEXT="power-saver" ; ICON="󰁻" ; NAME="Power Saver"  ;;
    "power-saver")  NEXT="balanced"    ; ICON="󰁹" ; NAME="Balanced"     ;;
    *)              NEXT="balanced"    ; ICON="󰁹" ; NAME="Balanced"     ;;
esac

powerprofilesctl set "$NEXT"

# حدّث أيقونة الزر في config.json
python3 - "$CONFIG" "$ICON" << 'PYEOF'
import sys, json
cfg_path, new_icon = sys.argv[1], sys.argv[2]
cfg = json.load(open(cfg_path))
actions = cfg["widget-config"]["buttons-grid"]["actions"]
for btn in actions:
    lbl = btn.get("label","")
    if lbl in ["󰁹","󱐌","󰁻"]:
        btn["label"] = new_icon
        break
open(cfg_path, 'w').write(json.dumps(cfg, indent=2, ensure_ascii=False))
PYEOF

swaync-client --reload-css &>/dev/null
notify-send "Battery Mode" "$ICON  $NAME" --icon=battery --expire-time=2000
