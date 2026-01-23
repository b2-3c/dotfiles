# Dotfiles – Hyprland

## Screenshots
![Screenshot](screenshots/1.png)
<details>
<summary> Screenshots
</summary>

![Screenshot](screenshots/2.png)
![Screenshot](screenshots/3.png)

</details>


A personal **Hyprland + Waybar** dotfiles setup focused on a clean Wayland workflow.
These dotfiles are primarily tested on **NixOS**, but most parts should work on other Linux distributions with minimal adjustments.

---

## ✨ Features

* Hyprland (Wayland compositor)
* Modular Waybar configuration
* PipeWire-based audio stack
* Screenshot, recording, and color-picking utilities
* Dynamic wallpapers (image & video)
* SwayNC notifications
* Custom scripts and small Waybar extensions

---

## 📦 Dependencies

Below is a **non-exhaustive but required** list of programs needed for everything to work as intended.

### System Basics & Wayland

* hyprland
* waybar
* wayland
* xorg.xwayland
* dbus
* systemd (user)
* xdg-desktop-portal
* xdg-desktop-portal-hyprland

### Audio & Microphone

* pipewire
* pulseaudio
* pipewire-pulse
* wireplumber
* pamixer
* pavucontrol
* playerctl

### Networking

* networkmanager
* nm-connection-editor

### Screenshots & Recording

* grim
* slurp
* wl-clipboard
* hyprshot
* wf-recorder
* hyprpicker

### Wallpapers

* swaybg

### Notifications

* swaync
* swaync-client
* libnotify (`notify-send`)

### Brightness & Power

* brightnessctl
* upower

### Scripting & CLI Tools

* bash
* python3
* python-dbus **or** python-dbus-next
* curl
* jq
* coreutils
* procps

### Media

* spotify (optional)

> Uses `playerctl` for Waybar integration

### Essential Applications

* alacritty
* nautilus
* firefox
* neovim
* btop
* unimatrix
* lazygit
* fastfetch

### Fonts & Icons (**Important**)

* nerd-fonts
* noto-fonts
* noto-fonts-emoji
* font-awesome


---

## 🧩 NixOS-Specific Requirements

If you are using **NixOS**, make sure you also have:

* polkit
* polkit-gnome (or another Polkit agent)

---

## ⚠️ Installation

> **Warning:** These dotfiles are not plug-and-play and may overwrite your existing configuration.

### Manual Installation (Classic Dotfiles Style)

```bash
git clone https://github.com/b2-3c/dotfiles
cd dotfiles

# Config files
cp -r .config/* ~/.config/

# Custom scripts
mkdir -p ~/.local/share/custom/bin
chmod +x custom-scripts/*
cp custom-scripts/* ~/.local/share/custom/bin/

# Wallpapers
mkdir -p ~/.config/current/Wallpapers
mkdir -p ~/Wallpapers/Pictures   # Put image wallpapers here
mkdir -p ~/Wallpapers/Videos     # Put mp4 wallpapers here
```
---
## ⌨️ Keyboard Shortcuts ($mainMod = SUPER)

### 📸 Screenshots & Recording
* `Print` : Capture area to clipboard (grim + slurp)
* `Shift + Print` : Capture full screen to clipboard
* `$mainMod + Print` : Save area screenshot to `~/Pictures/Screenshots`
* `$mainMod + Shift + Print` : Save full screen to `~/Pictures/Screenshots`
* `$mainMod + R` : Toggle screen recording script

### 🚀 Applications
* `$mainMod + Return` : Open Terminal (**Kitty**)
* `$mainMod + B` : Launch **Firefox**
* `$mainMod + F` : Launch **Nautilus** (File Manager)
* `$mainMod + Space` : App Launcher (**Wofi**)
* `$mainMod + N` : Launch **Neovim**

### 🛠 Terminal Tools (Floating)
* `$mainMod + Q` : System info (**Fastfetch**)
* `$mainMod + T` : System monitor (**Btop**)
* `$mainMod + L` : Git interface (**Lazygit**)
* `$mainMod + U` : Matrix effect (**Unimatrix**)

### 🪟 Window Management
* `$mainMod + W` : Kill active window
* `$mainMod + V` : Toggle floating mode
* `$mainMod + J` : Toggle split
* `$mainMod + M` : Fullscreen toggle
* `Alt + Tab` : Cycle next window
* `$mainMod + Arrows` : Resize active window
* `$mainMod + Shift + Arrows` : Move window position

### 🌌 Workspaces
* `$mainMod + [0-9]` : Switch to workspace 1-10
* `$mainMod + Shift + [0-9]` : Move window to workspace 1-10
* `$mainMod + Mouse_Scroll` : Cycle through workspaces
* **Special Workspaces:**
    * `AltGr + ,` : Toggle Calculator
    * `$mainMod + Y` : Toggle Spotify
    * `$mainMod + H` : Toggle Magic workspace

### 🔉 Audio & Brightness
* `Ctrl + Shift + Up/Down` : Screen brightness +/-
* `XF86AudioRaiseVolume` : Volume up
* `XF86AudioLowerVolume` : Volume down
* `XF86AudioMute` : Mute audio
* `XF86AudioMicMute` : Mute microphone
* `Media Keys` : Play/Pause/Next/Prev via `playerctl`
---
## ❗ Important Notes

* **Back up your system before copying anything**
* Existing files in `~/.config` **will be overwritten** if names collide
* I am **not responsible** for broken setups or lost configurations

---

## 📝 Notes & Credits
* GTK CSS is experimental and slightly broken — improvements are welcome
---

## 🤝 Contributions

Suggestions, fixes, and improvements are welcome. Feel free to open an issue or PR.
