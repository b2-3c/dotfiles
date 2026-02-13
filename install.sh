#!/bin/bash

C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; M='\033[0;35m'; W='\033[1;37m'; DG='\033[1;30m'; R='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

print_banner() {
    clear
    echo -e "${C}${BOLD}"
    echo "    ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ "
    echo "    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗"
    echo "    ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║"
    echo "    ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║"
    echo "    ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝"
    echo "    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ "
    echo -e "               ${M}⚡ HYPRLAND ULTIMATE INSTALLER ⚡${NC}"
    echo -e "${DG}──────────────────────────────────────────────────────────────────────────${NC}"
}

print_sep() { echo -e "${DG}──────────────────────────────────────────────────────────────────────────${NC}"; }

print_banner
sudo -v

# 1. التأكد من وجود yay
if ! command -v yay &> /dev/null; then
    echo -e "${Y}Installing yay (AUR Helper)...${NC}"
    sudo pacman -S --needed git base-devel --noconfirm &> /dev/null
    git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm && cd - && rm -rf /tmp/yay
fi

# 2. تعريف الحزم الكاملة (شاملة Rofi Plugins وكل السكربتات)
declare -A PKGS
PKGS[1_CORE]="hyprland waybar wayland xorg-xwayland dbus xdg-desktop-portal-hyprland polkit-gnome udiskie"
PKGS[2_AUDIO]="pipewire pulseaudio pipewire-pulse wireplumber pamixer pavucontrol playerctl libpulse"
PKGS[3_NET]="networkmanager nm-connection-editor bluez bluez-utils rfkill"
PKGS[4_UI]="grim slurp wl-clipboard hyprshot wf-recorder hyprpicker swaybg swaync libnotify hyprsunset waypaper-git rofi rofi-calc rofi-emoji grimblast-git cliphist fzf"
PKGS[5_SYS]="brightnessctl upower bash python python-dbus-next curl jq hypridle hyprlock gsettings-desktop-schemas pacman-contrib sddm"
PKGS[6_APPS]="kitty nautilus firefox neovim btop unimatrix lazygit fastfetch qview mpv obs-studio"
PKGS[7_FONTS]="ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji otf-font-awesome"
PKGS[8_THEMES]="tokyonight-gtk-theme-git papirus-icon-theme"

for key in $(echo "${!PKGS[@]}" | tr ' ' '\n' | sort); do
    print_sep
    echo -e "${Y}📦 Installing ${key}...${NC}"
    yay -S --noconfirm --needed ${PKGS[$key]}
done

print_sep
# 3. جلب الـ Dotfiles وتطبيق الإعدادات
if [ -d "dotfiles" ]; then
    mv dotfiles dotfiles_backup_$(date +%Y%m%d_%H%M%S)
fi
echo -e "${C}📥 Cloning Dotfiles...${NC}"
git clone https://github.com/b2-3c/dotfiles
cd dotfiles || exit

# نسخة احتياطية للكونفيج الحالي
mkdir -p ~/.config_backup
for dir in .config/*; do
    folder_name=$(basename "$dir")
    [ -d "$HOME/.config/$folder_name" ] && cp -r "$HOME/.config/$folder_name" "$HOME/.config_backup/"
done

# نسخ الملفات الجديدة
cp -r .config/* ~/.config/

# 4. تفعيل الصلاحيات لجميع السكربتات في كل المسارات
echo -e "${C}🔑 Setting execution permissions for all scripts...${NC}"
# تشمل مسارات Hypr و Rofi و Waybar و SwayNC
find ~/.config/hypr/scripts -type f -name "*.sh" -exec chmod +x {} +
find ~/.config/rofi/scripts -type f -name "*.sh" -exec chmod +x {} +
find ~/.config/waybar/scripts -type f -name "*.sh" -exec chmod +x {} +
find ~/.config/swaync/scripts -type f -name "*.sh" -exec chmod +x {} +

# 5. إعداد المسارات (PATH) لضمان عمل الاختصارات (Binds)
echo -e "${C}🔧 Configuring System PATH...${NC}"
PATH_DIRS=(
    "$HOME/.local/share/custom/bin"
    "$HOME/.config/hypr/scripts"
    "$HOME/.config/waybar/scripts"
    "$HOME/.config/rofi/scripts"
    "$HOME/.config/swaync/scripts"
)

for file in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc"; do
    if [ -f "$file" ]; then
        for dir in "${PATH_DIRS[@]}"; do
            if ! grep -q "$dir" "$file"; then
                echo "export PATH=\"\$PATH:$dir\"" >> "$file"
            fi
        done
    fi
done

# 6. إعداد خدمات النظام
echo -e "${C}⚙️ Enabling System Services...${NC}"
# إنشاء خدمة hyprsunset إذا لم تكن موجودة
mkdir -p ~/.config/systemd/user/
cat <<EOF > ~/.config/systemd/user/hyprsunset.service
[Unit]
Description=Hyprsunset blue light filter
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/hyprsunset
Restart=always

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now pipewire pipewire-pulse wireplumber &> /dev/null
sudo systemctl enable --now NetworkManager upower bluetooth sddm &> /dev/null

# 7. التنظيف النهائي وإنشاء المجلدات
mkdir -p ~/Pictures/Screenshots ~/Wallpapers/Pictures ~/Wallpapers/Videos ~/.local/share/custom/bin

print_sep
echo -e "${G}🚀 ALL DONE! YOUR SYSTEM IS READY.${NC}"
echo -e "${W}Rofi themes, Toggle scripts, and Binds are fully configured.${NC}"
print_sep

read -p "Reboot now? (y/N): " rb
[[ $rb =~ ^[Yy]$ ]] && reboot
