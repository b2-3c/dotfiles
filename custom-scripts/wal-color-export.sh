#!/usr/bin/env bash

WALJSON="$HOME/.cache/wal/colors.json"
TPL="$HOME/.config/current/wal-colors-template.css"
OUT="$HOME/.config/current/wal-colors.css"

# التأكد من وجود ملف الألوان الخاص بـ pywal
[ ! -f "$WALJSON" ] && echo "Pywal colors not found!" && exit 1

# جلب الألوان
BG=$(jq -r '.special.background' "$WALJSON")
FG=$(jq -r '.special.foreground' "$WALJSON")
ACCENT=$(jq -r '.colors.color4' "$WALJSON") 
BORDER="$ACCENT"

# دالة تحويل Hex إلى RGBA
hex_to_rgba() {
   local hex=${1#\#}
   local r=$((16#${hex:0:2}))
   local g=$((16#${hex:2:2}))
   local b=$((16#${hex:4:2}))
   local a=${2:-1}
   echo "rgba(${r}, ${g}, ${b}, ${a})"
}

# تحديث ملف CSS من القالب
cp "$TPL" "$OUT"

sed -i "s|<selected>|$ACCENT|g" "$OUT"
sed -i "s|<text>|$(hex_to_rgba "$FG" 0.9)|g" "$OUT"
sed -i "s|<base>|$(hex_to_rgba "$BG" 0.4)|g" "$OUT"
sed -i "s|<border>|$(hex_to_rgba "$ACCENT" 0.7)|g" "$OUT"
sed -i "s|<foreground>|$(hex_to_rgba "$FG" 0.9)|g" "$OUT"
sed -i "s|<background>|$(hex_to_rgba "$BG" 0.9)|g" "$OUT"

# --- الجزء الأهم: إعادة تشغيل الخدمات لتطبيق الألوان ---

# 1. تحديث Waybar
pkill waybar
waybar & disown

# 2. تحديث SwayNC (مركز التنبيهات)
# هذا الأمر يخبر SwayNC بإعادة قراءة ملفات الـ CSS فوراً
swaync-client -rs

# 3. تحديث Walker (إذا كنت تستخدمه)
pkill walker
# walker --daemon & disown

echo "Theme updated successfully!"
