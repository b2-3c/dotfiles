#!/usr/bin/env bash
WALJSON="$HOME/.cache/wal/colors.json"
TPL="$HOME/.config/current/wal-colors-template.css"
OUT="$HOME/.config/current/wal-colors.css"

# grab colors from pywal
BG=$(jq -r '.special.background' "$WALJSON")
FG=$(jq -r '.special.foreground' "$WALJSON")
ACCENT=$(jq -r '.colors.color4' "$WALJSON") # tweak which color slot you like
BORDER="$ACCENT"

# create semi-transparent rgba versions (optional)
BG_ALPHA="rgba(${BG#\#}, 0.1)" # not valid hex→rgba, so we’ll patch below

# this converts hex to rgba manually
hex_to_rgba() {
   local hex=${1#\#}
   local r=$((16#${hex:0:2}))
   local g=$((16#${hex:2:2}))
   local b=$((16#${hex:4:2}))
   local a=${2:-1}
   echo "rgba(${r}, ${g}, ${b}, ${a})"
}

# do replacements
cp "$TPL" "$OUT"

sed -i "s|<selected>|$ACCENT|g" "$OUT"
sed -i "s|<text>|$(hex_to_rgba "$FG" 0.9)|g" "$OUT"
sed -i "s|<base>|$(hex_to_rgba "$BG" 0.4)|g" "$OUT"
sed -i "s|<border>|$(hex_to_rgba "$ACCENT" 0.7)|g" "$OUT"
sed -i "s|<foreground>|$(hex_to_rgba "$FG" 0.9)|g" "$OUT"
sed -i "s|<background>|$(hex_to_rgba "$BG" 0.9)|g" "$OUT"

pkill walker
