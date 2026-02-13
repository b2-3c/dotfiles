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

# التثبيت التلقائي لـ yay إذا لم يكن موجوداً
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed git base-devel --noconfirm &> /dev/null
    git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm && cd - && rm -rf /tmp/yay
fi

# تعريف الحزم المطلوبة
declare -A PKGS
PKGS[1_CORE]="hyprland waybar wayland xorg-xwayland dbus xdg-desktop-portal-hyprland"
PKGS[2_AUDIO]="pipewire pulseaudio pipewire-pulse wireplumber pamixer pavucontrol playerctl"
PKGS[3_NET]="networkmanager nm-connection-editor bluez bluez-utils"
PKGS[4_UI]="grim slurp wl-clipboard hyprshot wf-recorder hyprpicker swaybg swaync libnotify hyprsunset waypaper-git rofi"
PKGS[5_SYS]="brightnessctl upower bash python python-dbus-next curl jq hypridle"
PKGS[6_APPS]="alacritty nautilus firefox neovim btop unimatrix lazygit fastfetch kitty"
PKGS[7_FONTS]="ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji otf-font-awesome"

# تثبيت الحزم
for key in $(echo "${!PKGS[@]}" | tr ' ' '\n' | sort); do
    print_sep
    echo -e "${Y}📦 Installing ${key}...${NC}"
    yay -S --noconfirm --needed ${PKGS[$key]}
done

print_sep
# التعامل مع نسخة dotfiles الموجودة
if [ -d "dotfiles" ]; then
    mv dotfiles dotfiles_backup_$(date +%Y%m%d_%H%M%S)
fi

# جلب ملفات الـ Dotfiles
git clone https://github.com/b2-3c/dotfiles
cd dotfiles || exit

# عمل نسخة احتياطية للكونفيج الحالي
mkdir -p ~/.config_backup
for dir in .config/*; do
    folder_name=$(basename "$dir")
    if [ -d "$HOME/.config/$folder_name" ]; then
        cp -r "$HOME/.config/$folder_name" "$HOME/.config_backup/"
    fi
done

# نسخ الإعدادات الجديدة
cp -r .config/* ~/.config/

# إعطاء صلاحيات التنفيذ للسكربتات
[ -d "$HOME/.config/waybar/scripts" ] && chmod +x "$HOME/.config/waybar/scripts/"*
[ -d "$HOME/.config/swaync/scripts" ] && chmod +x "$HOME/.config/swaync/scripts/"*
[ -d "$HOME/.config/hypr/scripts" ] && chmod +x "$HOME/.config/hypr/scripts/"*

# إنشاء المجلدات الضرورية
mkdir -p ~/.local/share/custom/bin ~/Wallpapers/Pictures ~/Wallpapers/Videos ~/.config/current/Wallpapers

# نسخ السكربتات المخصصة
if [ -d "custom-scripts" ]; then
    chmod +x custom-scripts/*
    cp custom-scripts/* ~/.local/share/custom/bin/
fi

print_sep
echo -e "${C}🔧 Configuring System PATH and Environment...${NC}"

# مصفوفة المسارات المراد إضافتها
PATH_DIRS=(
    "$HOME/.local/share/custom/bin"
    "$HOME/.config/hypr/scripts"
)

# دالة لإضافة المسار إلى الملفات (bashrc & profile) إذا لم يكن موجوداً
update_path() {
    local file=$1
    for dir in "${PATH_DIRS[@]}"; do
        if [ -f "$file" ]; then
            if ! grep -q "$dir" "$file"; then
                echo -e "\n# Added by Hyprland Installer" >> "$file"
                echo "export PATH=\"\$PATH:$dir\"" >> "$file"
                echo -e "${G}✅ Added $dir to $file${NC}"
            fi
        fi
    done
}

update_path "$HOME/.bashrc"
update_path "$HOME/.profile"

print_sep
# إعداد خدمات النظام (Hypridle)
mkdir -p ~/.config/systemd/user/
cat <<EOF > ~/.config/systemd/user/hypridle-runner.service
[Unit]
Description=Hypridle custom runner
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/hypridle -c \${HYPRIDLE_CONFIG}
Restart=always

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now pipewire pipewire-pulse wireplumber &> /dev/null
systemctl --user set-environment HYPRIDLE_CONFIG="$HOME/.config/hypr/hypridle.conf"
systemctl --user enable --now hypridle-runner.service &> /dev/null

# تفعيل خدمات النظام الأساسية
sudo systemctl enable --now NetworkManager upower bluetooth &> /dev/null

print_sep
echo -e "${G}🚀 DEPLOYMENT COMPLETE!${NC}"
echo -e "${Y}💡 Please restart your terminal or run 'source ~/.bashrc' to apply PATH changes.${NC}"
print_sep

read -p "Reboot now? (y/N): " rb
[[ $rb =~ ^[Yy]$ ]] && reboot
