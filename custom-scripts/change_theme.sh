#!/bin/bash

# --- المسارات الأساسية ---
WAYBAR_DIR="$HOME/.config/waybar"
SWAYNC_DIR="$HOME/.config/swaync"
KITTY_DIR="$HOME/.config/kitty"

# --- قائمة الثيمات (الاسم الأساسي) ---
themes=(
    "catppuccin-frappe"
    "catppuccin-latte"
    "catppuccin-macchiato"
    "catppuccin-mocha"
)

echo "🎨 محول الثيمات (Waybar + SwayNC + Kitty)"
echo "------------------------------------------"

# عرض قائمة الاختيار
for i in "${!themes[@]}"; do
    echo "$((i+1)) ) ${themes[$i]}"
done

echo "------------------------------------------"
read -p "أدخل رقم الثيم المختار: " choice

# التحقق من المدخلات
if [[ $choice -ge 1 && $choice -le ${#themes[@]} ]]; then
    THEME_NAME="${themes[$((choice-1))]}"

    echo "⏳ جاري تطبيق ثيم [$THEME_NAME] على جميع التطبيقات..."

    # 1. تحديث Waybar (ملف .css)
    if [ -f "$WAYBAR_DIR/themes/${THEME_NAME}.css" ]; then
        cp "$WAYBAR_DIR/themes/${THEME_NAME}.css" "$WAYBAR_DIR/theme.css"
        pkill -USR2 waybar
        echo "✅ تم تحديث Waybar."
    fi

    # 2. تحديث SwayNC (ملف .css)
    if [ -f "$SWAYNC_DIR/themes/${THEME_NAME}.css" ]; then
        cp "$SWAYNC_DIR/themes/${THEME_NAME}.css" "$SWAYNC_DIR/theme.css"
        swaync-client -rs
        echo "✅ تم تحديث SwayNC."
    fi

    # 3. تحديث Kitty (ملف .conf)
    if [ -f "$KITTY_DIR/themes/${THEME_NAME}.conf" ]; then
        cp "$KITTY_DIR/themes/${THEME_NAME}.conf" "$KITTY_DIR/theme.conf"
        # إرسال إشارة لـ Kitty لتحديث الثيم فوراً في النوافذ المفتوحة
        kill -SIGUSR1 $(pgrep kitty) 2>/dev/null
        echo "✅ تم تحديث Kitty."
    fi

    echo "------------------------------------------"
    echo "✨ تم التحديث بنجاح!"
else
    echo "❌ اختيار غير صحيح."
fi
