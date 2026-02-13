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
    echo -e "               ${M}⚡ HYPRLAND DOTFILES ARCHITECTURE ⚡${NC}"
    echo -e "${DG}──────────────────────────────────────────────────────────────────────────${NC}"
}

print_sep() { echo -e "${DG}──────────────────────────────────────────────────────────────────────────${NC}"; }

print_banner
sudo -v

# 1. التأكد من وجود yay
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed git base-devel --noconfirm &> /dev/null
    git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm && cd - && rm -rf /tmp/yay
fi

# 2. تحديث قائمة الحزم لتشمل كل احتياجات الـ binds والسكربتات
declare -A PKGS
PKGS[1_CORE]="hyprland waybar wayland xorg-xwayland dbus xdg-desktop-portal-hyprland polkit-gnome udiskie"
PKGS[2_AUDIO]="pipewire pulseaudio pipewire-pulse wireplumber pamixer pavucontrol playerctl"
PKGS[3_NET]="networkmanager nm-connection-editor bluez bluez-utils"
# تم إضافة grimblast و cliphist و rofi-calc/emoji بناءً على binds.conf
PKGS[4_UI]="grim slurp wl-clipboard hyprshot wf-recorder hyprpicker swaybg swaync libnotify hyprsunset waypaper-git rofi rofi-calc rofi-emoji grimblast-git cliphist"
PKGS[5_SYS]="brightnessctl upower bash python python-dbus-next curl jq hypridle hyprlock gsettings-desktop-schemas"
PKGS[6_APPS]="kitty nautilus firefox neovim btop unimatrix lazygit fastfetch qview mpv obs-studio"
PKGS[7_FONTS]="ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji otf-font-awesome"

for key in $(echo "${!PKGS[@]}" | tr ' ' '\n' | sort); do
    print_sep
    echo -e "${Y}📦 Installing ${key}...${NC}"
    yay -S --noconfirm --needed ${PKGS[$key]}
done

print_sep
# 3. التعامل مع ملفات الإعدادات (Dotfiles)
if [ -d "dotfiles" ]; then
    mv dotfiles dotfiles_backup_$(date +%Y%m%d_%H%M%S)
fi
git clone https://github.com/b2-3c/dotfiles
cd dotfiles || exit

mkdir -p ~/.config_backup
for dir in .config/*; do
    folder_name=$(basename "$dir")
    [ -d "$HOME/.config/$folder_name" ] && cp -r "$HOME/.config/$folder_name" "$HOME/.config_backup/"
done

cp -r .config/* ~/.config/

# 4. تفعيل صلاحيات التنفيذ لجميع السكربتات المذكورة في binds.conf
[ -d "$HOME/.config/hypr/scripts" ] && chmod +x "$HOME/.config/hypr/scripts/"*
[ -d "$HOME/.config/rofi/scripts" ] && chmod +x "$HOME/.config/rofi/scripts/"*
[ -d "$HOME/.config/waybar/scripts" ] && chmod +x "$HOME/.config/waybar/scripts/"*

# 5. إعداد البيئة والمسارات (PATH)
mkdir -p ~/.local/share/custom/bin
[ -d "custom-scripts" ] && chmod +x custom-scripts/* && cp custom-scripts/* ~/.local/share/custom/bin/

print_sep
echo -e "${C}🔧 Configuring System PATH...${NC}"
PATH_DIRS=("$HOME/.local/share/custom/bin" "$HOME/.config/hypr/scripts")
for file in "$HOME/.bashrc" "$HOME/.profile"; do
    for dir in "${PATH_DIRS[@]}"; do
        if [ -f "$file" ] && ! grep -q "$dir" "$file"; then
            echo "export PATH=\"\$PATH:$dir\"" >> "$file"
        fi
    done
done

# 6. إعداد خدمات النظام
systemctl --user enable --now pipewire pipewire-pulse wireplumber &> /dev/null
sudo systemctl enable --now NetworkManager upower bluetooth &> /dev/null

print_sep
echo -e "${G}🚀 DEPLOYMENT COMPLETE!${NC}"
print_sep

read -p "Reboot now? (y/N): " rb
[[ $rb =~ ^[Yy]$ ]] && reboot
