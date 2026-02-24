#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
#   HYPRLAND DOTFILES INSTALLER
# ══════════════════════════════════════════════════════════

set -euo pipefail

# ── الألوان ──
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLU='\033[0;34m'
MAG='\033[0;35m'
CYN='\033[0;36m'
WHT='\033[1;37m'
DIM='\033[1;30m'
BLD='\033[1m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
LOCAL_BIN="$HOME/.local/bin"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

# ══════════════════════════════════════════════════════════
banner() {
    clear
    echo -e "${CYN}${BLD}"
    echo "    ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ "
    echo "    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗"
    echo "    ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║"
    echo "    ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║"
    echo "    ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝"
    echo "    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝"
    echo -e "               ${MAG}⚡ DOTFILES INSTALLER ⚡${NC}"
    echo -e "${DIM}════════════════════════════════════════════════════════════${NC}\n"
}

sep()  { echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"; }
info() { echo -e "${BLU}  →  ${WHT}$1${NC}"; }
ok()   { echo -e "${GRN}  ✓  ${WHT}$1${NC}"; }
warn() { echo -e "${YLW}  ⚠  ${WHT}$1${NC}"; }
err()  { echo -e "${RED}  ✗  ${WHT}$1${NC}"; }
step() { echo -e "\n${CYN}${BLD}[ $1 ]${NC}"; sep; }

install_pkgs() {
    local label="$1"; shift
    local pkgs=("$@")
    info "Installing: $label"
    paru -S --noconfirm --needed --noprogressbar "${pkgs[@]}" 2>/dev/null || {
        for pkg in "${pkgs[@]}"; do
            paru -S --noconfirm --needed --noprogressbar "$pkg" 2>/dev/null \
                && ok "$pkg" \
                || warn "Skipped (not found): $pkg"
        done
    }
    ok "$label installed"
}

# ══════════════════════════════════════════════════════════
#  0. التحقق من المتطلبات
# ══════════════════════════════════════════════════════════

banner
step "0/9 — Prerequisites"

if [ ! -f /etc/arch-release ]; then
    err "This installer is for Arch Linux only."
    exit 1
fi

sudo -v || { err "sudo required"; exit 1; }

# ── دالة مساعدة: clone مع إعادة المحاولة ──────────────────
_aur_clone() {
    local repo_url="$1"
    local dest="$2"
    for attempt in 1 2 3; do
        info "Cloning $(basename "$dest") (attempt $attempt/3)..."
        rm -rf "$dest"
        if git clone "$repo_url" "$dest" 2>/dev/null; then
            return 0
        fi
        warn "Clone failed, retrying in 3 seconds..."
        sleep 3
    done
    return 1
}

# ── تثبيت yay ─────────────────────────────────────────────
if ! command -v yay &>/dev/null; then
    info "yay not found. Installing yay (AUR helper)..."

    # تأكد من وجود git و base-devel
    sudo pacman -S --needed --noconfirm git base-devel

    # فحص الاتصال بالإنترنت أولاً
    info "Checking network connectivity..."
    if ! curl -fsS --max-time 10 https://google.com > /dev/null 2>&1; then
        err "No internet connection detected."
        err "Please check your network and try again."
        exit 1
    fi
    ok "Network OK"

    YAY_INSTALLED=""

    # ── محاولة 1: yay من AUR ──
    info "Trying yay from AUR..."
    if curl -fsS --max-time 10 https://aur.archlinux.org > /dev/null 2>&1; then
        if _aur_clone "https://aur.archlinux.org/yay.git" /tmp/yay-build; then
            cd /tmp/yay-build && makepkg -si --noconfirm && cd "$DOTFILES_DIR"
            rm -rf /tmp/yay-build
            YAY_INSTALLED="yes"
            ok "yay installed"
        fi
    else
        warn "aur.archlinux.org unreachable, trying GitHub mirror..."
    fi

    # ── محاولة 2: yay من GitHub (mirror) ──
    if [[ -z "$YAY_INSTALLED" ]]; then
        info "Trying yay from GitHub mirror..."
        if _aur_clone "https://github.com/Jguer/yay.git" /tmp/yay-build; then
            cd /tmp/yay-build && makepkg -si --noconfirm && cd "$DOTFILES_DIR"
            rm -rf /tmp/yay-build
            YAY_INSTALLED="yes"
            ok "yay installed from GitHub mirror"
        fi
    fi

    if [[ -z "$YAY_INSTALLED" ]]; then
        err "Failed to install yay."
        err "Check your internet connection and try again."
        exit 1
    fi

else
    ok "yay found"
fi

# ── استخدام yay عبر اسم paru (لبقية السكريبت) ────────────
paru() { yay "$@"; }
export -f paru

info "Syncing package database..."
sudo pacman -Sy --noconfirm &>/dev/null
ok "Database synced"

# ══════════════════════════════════════════════════════════
#  1. Core Hyprland
# ══════════════════════════════════════════════════════════

step "1/9 — Core (Hyprland + Wayland)"

install_pkgs "Hyprland ecosystem" \
    hyprland \
    hyprlock \
    hypridle \
    hyprsunset \
    hyprpicker \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xorg-xwayland \
    wayland-protocols \
    qt5-wayland \
    qt6-wayland

install_pkgs "Wayland utilities" \
    grim \
    slurp \
    grimblast-git \
    swww \
    swaync \
    wl-clipboard \
    cliphist \
    imagemagick

install_pkgs "Session & Auth" \
    polkit-gnome \
    sddm \
    dbus \
    udiskie

# ══════════════════════════════════════════════════════════
#  2. Audio
# ══════════════════════════════════════════════════════════

step "2/9 — Audio"

install_pkgs "PipeWire audio stack" \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber \
    pamixer \
    pavucontrol \
    playerctl \
    libpulse \
    python-gobject \
    gst-plugin-pipewire

# wiremix — TUI audio mixer (بديل rofi للصوت)
install_pkgs "Audio TUI" \
    wiremix

# ══════════════════════════════════════════════════════════
#  3. Network & Bluetooth
# ══════════════════════════════════════════════════════════

step "3/9 — Network & Bluetooth"

install_pkgs "Network tools" \
    networkmanager \
    nm-connection-editor \
    network-manager-applet \
    rfkill

install_pkgs "Bluetooth" \
    bluez \
    bluez-utils \
    bluetui

# ══════════════════════════════════════════════════════════
#  4. UI (Waybar + Rofi + TUI tools)
# ══════════════════════════════════════════════════════════

step "4/9 — UI (Waybar + Rofi + TUI tools)"

install_pkgs "Waybar" \
    waybar \
    python \
    python-requests

install_pkgs "Rofi & plugins" \
    rofi-wayland \
    rofi-calc \
    rofi-emoji

install_pkgs "UI & TUI tools" \
    brightnessctl \
    upower \
    jq \
    curl \
    fzf \
    gum \
    libnotify

# ══════════════════════════════════════════════════════════
#  5. Applications
# ══════════════════════════════════════════════════════════

step "5/9 — Applications"

install_pkgs "Terminal & Editor" \
    kitty \
    neovim \
    starship

install_pkgs "File & Browser" \
    nautilus \
    firefox \
    xdg-utils

install_pkgs "System tools" \
    btop \
    fastfetch \
    cava \
    lazygit

install_pkgs "Media" \
    mpv \
    imv \
    obs-studio

# ══════════════════════════════════════════════════════════
#  6. Fonts & Icons
# ══════════════════════════════════════════════════════════

step "6/9 — Fonts & Icons"

install_pkgs "Nerd Fonts" \
    ttf-jetbrains-mono-nerd \
    ttf-firacode-nerd \
    noto-fonts \
    noto-fonts-emoji \
    noto-fonts-cjk \
    otf-font-awesome

install_pkgs "Icons & Cursor" \
    papirus-icon-theme \
    papirus-folders \
    bibata-cursor-theme

# ══════════════════════════════════════════════════════════
#  7. Themes
# ══════════════════════════════════════════════════════════

step "7/9 — Themes"

install_pkgs "GTK Themes" \
    catppuccin-gtk-theme-mocha \
    catppuccin-gtk-theme-frappe \
    catppuccin-gtk-theme-macchiato \
    catppuccin-gtk-theme-latte \
    gnome-themes-extra \
    gsettings-desktop-schemas

install_pkgs "Package manager extras" \
    pacman-contrib \
    paru

# ══════════════════════════════════════════════════════════
#  8. Deploy Dotfiles
# ══════════════════════════════════════════════════════════

step "8/9 — Deploying Dotfiles"

# نسخ احتياطي
info "Backing up existing config to $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"
for dir in "$CONFIG_DIR"/hypr "$CONFIG_DIR"/waybar "$CONFIG_DIR"/kitty \
           "$CONFIG_DIR"/rofi "$CONFIG_DIR"/swaync "$CONFIG_DIR"/btop \
           "$CONFIG_DIR"/cava "$CONFIG_DIR"/fastfetch; do
    [ -d "$dir" ] && cp -r "$dir" "$BACKUP_DIR/" 2>/dev/null && \
        info "Backed up: $(basename $dir)"
done
ok "Backup done → $BACKUP_DIR"

# نسخ الإعدادات
info "Copying dotfiles..."
# إزالة الملفات المحمية التي قد تسبب مشاكل صلاحيات
sudo rm -f "$CONFIG_DIR/hypr/user.png" 2>/dev/null || true
# نسخ مع تجاهل أخطاء الصلاحيات الفردية
cp -r "$DOTFILES_DIR/.config/"* "$CONFIG_DIR/" 2>/dev/null || {
    warn "Some files had permission issues, retrying with sudo for protected files..."
    sudo cp -r "$DOTFILES_DIR/.config/"* "$CONFIG_DIR/"
    sudo chown -R "$USER:$USER" "$CONFIG_DIR/"
}
ok "Dotfiles copied"

# ── نسخ أوامر ~/.local/bin ────────────────────────────────
info "Installing local commands to ~/.local/bin ..."
mkdir -p "$LOCAL_BIN"

for cmd in omarchy-launch-or-focus omarchy-launch-tui omarchy-launch-or-focus-tui omarchy-launch-audio; do
    if [ -f "$DOTFILES_DIR/.local/bin/$cmd" ]; then
        cp "$DOTFILES_DIR/.local/bin/$cmd" "$LOCAL_BIN/"
        chmod +x "$LOCAL_BIN/$cmd"
        ok "Installed: $cmd"
    fi
done
ok "Local commands installed → $LOCAL_BIN"

# تأكد أن ~/.local/bin في PATH
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    warn "~/.local/bin is not in PATH."
    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc" ] && ! grep -q 'LOCAL_BIN\|\.local/bin' "$rc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
            info "Added ~/.local/bin to PATH in $rc"
        fi
    done
    export PATH="$LOCAL_BIN:$PATH"
fi

# ── إنشاء المجلدات ──────────────────────────────────────
info "Creating required directories..."
mkdir -p \
    ~/Pictures/Screenshots \
    ~/Wallpapers/Pictures \
    ~/Wallpapers/Users \
    ~/Wallpapers/Videos \
    ~/.local/share/fonts \
    ~/.local/share/applications \
    ~/.cache \
    ~/.config/swww \
    ~/.config/systemd/user
ok "Directories created"

# ── الصورة الشخصية الافتراضية ────────────────────────────
info "Setting default user avatar..."
if command -v convert &>/dev/null; then
    convert "$DOTFILES_DIR/wallpapers/avatar.png" \
        -thumbnail 300x300^ -gravity center -extent 300x300 \
        "$HOME/.local/share/user.jpeg" 2>/dev/null \
    && ok "Avatar set → ~/.local/share/user.jpeg" \
    || {
        cp "$DOTFILES_DIR/wallpapers/avatar.png" "$HOME/.local/share/user.jpeg" 2>/dev/null
        ok "Avatar copied → ~/.local/share/user.jpeg"
    }
else
    cp "$DOTFILES_DIR/wallpapers/avatar.png" "$HOME/.local/share/user.jpeg" 2>/dev/null
    ok "Avatar copied → ~/.local/share/user.jpeg"
fi

# ── الخلفية الافتراضية ───────────────────────────────────
info "Setting default wallpaper..."
cp "$DOTFILES_DIR/wallpapers/MistyTrees.jpg" \
   "$HOME/Wallpapers/Pictures/MistyTrees.jpg" 2>/dev/null
echo "$HOME/Wallpapers/Pictures/MistyTrees.jpg" > "$HOME/.config/swww/current_wallpaper"
cp "$DOTFILES_DIR/wallpapers/MistyTrees.jpg" \
   "$HOME/.cache/hyprlock_wall.png" 2>/dev/null
cp "$DOTFILES_DIR/wallpapers/avatar.png" \
   "$HOME/Wallpapers/Users/avatar.png" 2>/dev/null
ok "Default wallpaper set → MistyTrees.jpg"

# ── صلاحيات السكريبتات ───────────────────────────────────
info "Setting permissions on all scripts..."
find "$CONFIG_DIR/hypr/scripts"    -type f              -exec chmod +x {} + 2>/dev/null
find "$CONFIG_DIR/hypr/nowplaying" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null
find "$CONFIG_DIR/rofi/scripts"    -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null
find "$CONFIG_DIR/waybar/scripts"  -type f              -exec chmod +x {} + 2>/dev/null
find "$CONFIG_DIR/swaync/scripts"  -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null
ok "Permissions set"

# ══════════════════════════════════════════════════════════
#  9. System Services & Final Config
# ══════════════════════════════════════════════════════════

step "9/9 — System Services & Final Config"

# ── hyprsunset service ──
info "Setting up systemd user services..."

cat > ~/.config/systemd/user/hyprsunset.service << 'EOF'
[Unit]
Description=Hyprsunset blue light filter
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/hyprsunset -t 4500
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

cat > ~/.config/systemd/user/swaync.service << 'EOF'
[Unit]
Description=SwayNotificationCenter
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/swaync
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
ok "User services configured"

# ── تفعيل خدمات النظام ──
info "Enabling system services..."
sudo systemctl enable --now NetworkManager  2>/dev/null && ok "NetworkManager enabled"
sudo systemctl enable --now bluetooth       2>/dev/null && ok "Bluetooth enabled" || warn "Bluetooth skipped"
sudo systemctl enable --now upower          2>/dev/null && ok "UPower enabled"
sudo systemctl enable sddm                  2>/dev/null && ok "SDDM enabled" || warn "SDDM skipped"

info "Enabling user audio services..."
systemctl --user enable --now pipewire       2>/dev/null && ok "PipeWire enabled"
systemctl --user enable --now pipewire-pulse 2>/dev/null && ok "PipeWire-Pulse enabled"
systemctl --user enable --now wireplumber    2>/dev/null && ok "WirePlumber enabled"

# ── GTK Settings ──
info "Applying GTK settings..."
gsettings set org.gnome.desktop.interface gtk-theme    "catppuccin-mocha"   2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme   "Papirus-Dark"       2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic"  2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size  16                   2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"        2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name    "Noto Sans 11"       2>/dev/null || true
ok "GTK settings applied"

# ── Font cache ──
info "Updating font cache..."
fc-cache -f &>/dev/null
ok "Font cache updated"

# ── Starship ──
if ! command -v starship &>/dev/null; then
    info "Installing starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes &>/dev/null
    ok "Starship installed"
fi
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -q "starship" "$rc"; then
        echo 'eval "$(starship init bash)"' >> "$rc" 2>/dev/null || true
        info "Starship added to $rc"
    fi
done

# ── Default themes ──
info "Setting default themes..."

WAYBAR_THEME="$CONFIG_DIR/waybar/theme.css"
[ ! -f "$WAYBAR_THEME" ] && cp "$CONFIG_DIR/waybar/themes/catppuccin-mocha.css" "$WAYBAR_THEME" 2>/dev/null || true

ROFI_THEME="$CONFIG_DIR/rofi/theme.rasi"
[ ! -f "$ROFI_THEME" ] && cp "$CONFIG_DIR/rofi/themes/catppuccin-mocha.rasi" "$ROFI_THEME" 2>/dev/null || true

SWAYNC_THEME="$CONFIG_DIR/swaync/theme.css"
[ ! -f "$SWAYNC_THEME" ] && cp "$CONFIG_DIR/swaync/themes/catppuccin-mocha.css" "$SWAYNC_THEME" 2>/dev/null || true

KITTY_THEME="$CONFIG_DIR/kitty/theme.conf"
[ ! -f "$KITTY_THEME" ] && cp "$CONFIG_DIR/kitty/themes/catppuccin-mocha.conf" "$KITTY_THEME" 2>/dev/null || true

BTOP_THEME="$CONFIG_DIR/btop/themes/theme.theme"
[ ! -f "$BTOP_THEME" ] && cp "$CONFIG_DIR/btop/themes/catppuccin_mocha.theme" "$BTOP_THEME" 2>/dev/null || true

ok "Default themes applied"

# ── اكتشاف اسم لوحة المفاتيح لـ hyprland/language ──────
info "Detecting keyboard name for language indicator..."
KB_NAME=$(hyprctl devices -j 2>/dev/null |     python3 -c "
import sys,json
d=json.load(sys.stdin)
kbs=[k['name'] for k in d.get('keyboards',[]) if 'virtual' not in k['name'].lower()]
print(kbs[0] if kbs else '')
" 2>/dev/null)

if [[ -n "$KB_NAME" ]]; then
    LANG_CONF="$CONFIG_DIR/waybar/config.jsonc"
    # أضف keyboard-name إذا لم يكن موجوداً
    if ! grep -q "keyboard-name" "$LANG_CONF"; then
        sed -i "s|"format-en": "EN",|"format-en": "EN",\n    "keyboard-name": "$KB_NAME",|" "$LANG_CONF"
    fi
    ok "Keyboard detected: $KB_NAME"
else
    warn "Could not detect keyboard name — language indicator may show full name"
    warn "Run after login: hyprctl devices and update 'keyboard-name' in waybar/config.jsonc"
fi

# ── تفعيل مؤشر Bibata-Modern-Classic ────────────────────
info "Activating Bibata-Modern-Classic cursor..."
mkdir -p "$HOME/.icons/default"

# اربط المؤشر في ~/.icons لكي تجده التطبيقات
if [ -d /usr/share/icons/Bibata-Modern-Classic ]; then
    ln -sf /usr/share/icons/Bibata-Modern-Classic "$HOME/.icons/Bibata-Modern-Classic" 2>/dev/null || true

    # index.theme لـ default cursor
    cat > "$HOME/.icons/default/index.theme" << 'ICONEOF'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Bibata-Modern-Classic
ICONEOF

    # hyprctl لتطبيق المؤشر فوراً إن كان hyprland يعمل
    hyprctl setcursor Bibata-Modern-Classic 16 &>/dev/null || true

    ok "Cursor set to Bibata-Modern-Classic (size 16)"
else
    warn "Bibata-Modern-Classic not found in /usr/share/icons — will apply after reboot"
fi

# ══════════════════════════════════════════════════════════
#  تقرير نهائي
# ══════════════════════════════════════════════════════════

sep
echo -e "\n${GRN}${BLD}  ✓  Installation Complete!${NC}\n"
sep

echo -e "${WHT}  Things you may need to configure manually:${NC}"
echo -e "${DIM}  ┌─────────────────────────────────────────────────────────┐${NC}"
echo -e "${DIM}  │${NC}  ${YLW}~/.config/waybar/scripts/weather.sh${NC}   → Set LAT & LON"
echo -e "${DIM}  │${NC}  ${YLW}~/.config/hypr/custom/monitors.conf${NC}   → Set your monitor"
echo -e "${DIM}  │${NC}  ${YLW}~/.config/hypr/custom/devices.conf${NC}    → Set your devices"
echo -e "${DIM}  │${NC}  ${YLW}~/Wallpapers/Pictures/${NC}                → Add more wallpapers"
echo -e "${DIM}  │${NC}  ${YLW}~/Wallpapers/Users/${NC}                   → Add avatar images"
echo -e "${DIM}  │${NC}  ${YLW}~/.config/waybar/config.jsonc${NC}         → keyboard-name (if language shows wrong)"
echo -e "${DIM}  └─────────────────────────────────────────────────────────┘${NC}"

echo -e "\n${WHT}  Installed commands in ~/.local/bin:${NC}"
echo -e "${DIM}  ┌─────────────────────────────────────────────────────────┐${NC}"
echo -e "${DIM}  │${NC}  ${CYN}omarchy-launch-audio${NC}            → Audio TUI (wiremix)"
echo -e "${DIM}  │${NC}  ${CYN}omarchy-launch-or-focus-tui${NC}     → Launch/focus TUI apps"
echo -e "${DIM}  │${NC}  ${CYN}omarchy-launch-or-focus${NC}         → Focus or launch any app"
echo -e "${DIM}  │${NC}  ${CYN}omarchy-launch-tui${NC}              → Launch TUI in kitty"
echo -e "${DIM}  └─────────────────────────────────────────────────────────┘${NC}"

echo -e "\n${WHT}  Backup of old config saved to:${NC}"
echo -e "  ${CYN}$BACKUP_DIR${NC}\n"

sep
read -rp "$(echo -e "${YLW}  Reboot now? [Y/n]: ${NC}")" answer
[[ "${answer,,}" != "n" ]] && sudo reboot || echo -e "\n${GRN}  Done! Run 'Hyprland' to start.${NC}\n"
