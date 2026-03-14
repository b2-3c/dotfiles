#!/usr/bin/env bash
#
# يكتشف جهاز الإضاءة ويحدّث swaync config تلقائياً
#

SWAYNC_CONF="$HOME/.config/swaync/config.json"
BACKLIGHT_DIR="/sys/class/backlight"

# ابحث عن أفضل جهاز متاح بالأولوية
DEVICE=""
for preferred in intel_backlight amdgpu_bl0 amdgpu_bl1 nvidia_0 acpi_video0; do
    if [ -d "$BACKLIGHT_DIR/$preferred" ]; then
        DEVICE="$preferred"
        break
    fi
done

# إذا ما وجدنا بالأولوية، خذ أول جهاز متاح
if [ -z "$DEVICE" ]; then
    DEVICE=$(ls "$BACKLIGHT_DIR" 2>/dev/null | head -1)
fi

# إذا ما في أي جهاز، احذف backlight من swaync
if [ -z "$DEVICE" ]; then
    python3 -c "
import json
with open('$SWAYNC_CONF') as f:
    c = json.load(f)
c['widgets'] = [w for w in c['widgets'] if w not in ('backlight', 'backlight/slider')]
for k in ('backlight', 'backlight/slider'):
    c['widget-config'].pop(k, None)
with open('$SWAYNC_CONF', 'w') as f:
    json.dump(c, f, indent=2)
" 2>/dev/null
    exit 0
fi

# حدّث config بالجهاز الصحيح
python3 -c "
import json
with open('$SWAYNC_CONF') as f:
    c = json.load(f)

# أضف backlight بعد volume إذا لم يكن موجوداً
for widget in ['backlight']:
    if widget not in c['widgets']:
        idx = c['widgets'].index('volume') if 'volume' in c['widgets'] else 0
        c['widgets'].insert(idx + 1, widget)

# إعداد الـ widget
c['widget-config']['backlight'] = {
    'label': '󰃠',
    'device': '$DEVICE'
}

with open('$SWAYNC_CONF', 'w') as f:
    json.dump(c, f, indent=2)
print('backlight device:', '$DEVICE')
" 2>/dev/null
