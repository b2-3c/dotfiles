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
    echo -e "              ${M}⚡ HYPRLAND DOTFILES ARCHITECTURE ⚡${NC}"
    echo -e "${DG}──────────────────────────────────────────────────────────────────────────${NC}"
}

print_sep() { echo -e "${DG}──────────────────────────────────────────────────────────────────────────${NC}"; }

print_banner
sudo -v

if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed git base-devel --noconfirm &> /dev/null
    git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm && cd - && rm -rf /tmp/yay
fi

declare -A PKGS
PKGS[1_CORE]="hyprland waybar wayland xorg-xwayland dbus xdg-desktop-portal-hyprland"
PKGS[2_AUDIO]="pipewire pulseaudio pipewire-pulse wireplumber pamixer pavucontrol playerctl"
PKGS[3_NET]="networkmanager nm-connection-editor bluez bluez-utils"
PKGS[4_UI]="grim slurp wl-clipboard hyprshot wf-recorder hyprpicker swaybg swaync libnotify hyprsunset waypaper-git"
PKGS[5_SYS]="brightnessctl upower bash python python-dbus-next curl jq hypridle"
PKGS[6_APPS]="alacritty nautilus firefox neovim btop unimatrix lazygit fastfetch"
PKGS[7_FONTS]="ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji otf-font-awesome"

for key in $(echo "${!PKGS[@]}" | tr ' ' '\n' | sort); do
    print_sep
    yay -S --noconfirm --needed ${PKGS[$key]}
done

print_sep
if [ -d "dotfiles" ]; then
    mv dotfiles dotfiles_backup_$(date +%Y%m%d_%H%M%S)
fi
git clone https://github.com/b2-3c/dotfiles
cd dotfiles || exit

mkdir -p ~/.config_backup
for dir in .config/*; do
    folder_name=$(basename "$dir")
    if [ -d "$HOME/.config/$folder_name" ]; then
        cp -r "$HOME/.config/$folder_name" "$HOME/.config_backup/"
    fi
done

cp -r .config/* ~/.config/

[ -d "$HOME/.config/waybar/scripts" ] && chmod +x "$HOME/.config/waybar/scripts/"*
[ -d "$HOME/.config/swaync/scripts" ] && chmod +x "$HOME/.config/swaync/scripts/"*

mkdir -p ~/.local/share/custom/bin ~/Wallpapers/Pictures ~/Wallpapers/Videos ~/.config/current/Wallpapers
if [ -d "custom-scripts" ]; then
    chmod +x custom-scripts/*
    cp custom-scripts/* ~/.local/share/custom/bin/
fi

print_sep
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

sudo systemctl enable --now NetworkManager upower bluetooth &> /dev/null

print_sep
echo -e "${G}🚀 DEPLOYMENT COMPLETE!${NC}"
print_sep

read -p "Reboot now? (y/N): " rb
[[ $rb =~ ^[Yy]$ ]] && reboot
