# Dotfiles – Hyprland

## Screenshots
![Screenshot](screenshots/1.png)
<details>
<summary> Screenshots
</summary>

![Screenshot](screenshots/2.png)
![Screenshot](screenshots/3.png)

</details>

A personal **Hyprland + Waybar** dotfiles setup focused on a clean Wayland workflow. These dotfiles are primarily tested on **NixOS**, but most parts should work on other Linux distributions with minimal adjustments.

---

## ✨ Features

| Feature | Description |
|---|---|
| Hyprland | Wayland compositor |
| Modular Waybar configuration | Customizable Waybar setup |
| PipeWire-based audio stack | Modern audio management |
| Screenshot, recording, and color-picking utilities | Tools for screen capture and color selection |
| Dynamic wallpapers | Image and video wallpaper support |
| SwayNC notifications | Notification system |
| Custom scripts and small Waybar extensions | Enhanced functionality and customization |

---

## ⚠️ Installation

### Automatic Installation

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/b2-3c/dotfiles/refs/heads/main/install.sh)"
```

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

## 📦 Dependencies

Below is a **non-exhaustive but required** list of programs needed for everything to work as intended.

### System Basics & Wayland

| Component | Description |
|---|---|
| hyprland | Wayland compositor |
| waybar | Highly customizable Wayland bar for Hyprland |
| wayland | Display server protocol |
| xorg.xwayland | XWayland compatibility layer |
| dbus | Message bus system |
| systemd (user) | System and service manager |
| xdg-desktop-portal | Flatpak/Snap integration for desktop features |
| xdg-desktop-portal-hyprland | Hyprland specific xdg-desktop-portal implementation |

### Audio & Microphone

| Component | Description |
|---|---|
| pipewire | Audio and video server |
| pulseaudio | Sound server (for compatibility) |
| pipewire-pulse | PipeWire PulseAudio replacement |
| wireplumber | Session and policy manager for PipeWire |
| pamixer | PulseAudio command-line mixer |
| pavucontrol | PulseAudio volume control GUI |
| playerctl | Command-line utility for controlling media players |

### Networking

| Component | Description |
|---|---|
| networkmanager | Manages network connections |
| nm-connection-editor | NetworkManager connection editor GUI |

### Screenshots & Recording

| Component | Description |
|---|---|
| grim | Grab images from a Wayland compositor |
| slurp | Select a region in a Wayland compositor |
| wl-clipboard | Command-line copy/paste utilities for Wayland |
| hyprshot | Screenshot utility for Hyprland |
| wf-recorder | Screen recorder for Wayland |
| hyprpicker | Color picker for Wayland |

### Wallpapers

| Component | Description |
|---|---|
| swaybg | Wallpaper utility for Wayland |

### Notifications

| Component | Description |
|---|---|
| swaync | Notification daemon for Wayland |
| swaync-client | Command-line client for SwayNC |
| libnotify (`notify-send`) | Sends desktop notifications |

### Brightness & Power

| Component | Description |
|---|---|
| brightnessctl | Control screen brightness |
| upower | Power management daemon |

### Scripting & CLI Tools

| Component | Description |
|---|---|
| bash | GNU Bourne-Again Shell |
| python3 | Python 3 interpreter |
| python-dbus **or** python-dbus-next | Python bindings for D-Bus |
| curl | Command-line tool for transferring data with URLs |
| jq | Command-line JSON processor |
| coreutils | GNU core utilities |
| procps | Utilities for browsing /proc |

### Media

*   spotify (optional)

> Uses `playerctl` for Waybar integration

### Essential Applications

| Application | Description |
|---|---|
| alacritty | GPU-accelerated terminal emulator |
| nautilus | GNOME file manager |
| firefox | Web browser |
| neovim | Highly extensible Vim-based text editor |
| btop | Resource monitor |
| unimatrix | CLI tool for matrix effect |
| lazygit | Simple terminal UI for git commands |
| fastfetch | Neofetch-like system information tool |

### Fonts & Icons (**Important**)

| Font/Icon Set | Description |
|---|---|
| nerd-fonts | Iconic font collection for developers |
| noto-fonts | Google Noto fonts, designed to cover all Unicode scripts |
| noto-fonts-emoji | Noto Color Emoji fonts |
| font-awesome | Popular icon set |

---

## 🧩 NixOS-Specific Requirements

If you are using **NixOS**, make sure you also have:

| Component | Description |
|---|---|
| polkit | Authorization manager |
| polkit-gnome | GNOME Polkit authentication agent (or similar) |

---

## ⌨️ Keyboard Shortcuts ($mainMod = SUPER)

### 📸 Screenshots & Recording
| Shortcut | Action |
|---|---|
| `Print` | Capture area to clipboard (grim + slurp) |
| `Shift + Print` | Capture full screen to clipboard |
| `$mainMod + Print` | Save area screenshot to `~/Pictures/Screenshots` |
| `$mainMod + Shift + Print` | Save full screen to `~/Pictures/Screenshots` |
| `$mainMod + R` | Toggle screen recording script |

### 🚀 Applications
| Shortcut | Action |
|---|---|
| `$mainMod + Return` | Open Terminal (**Kitty**) |
| `$mainMod + B` | Launch **Firefox** |
| `$mainMod + F` | Launch **Nautilus** (File Manager) |
| `$mainMod + Space` | App Launcher (**Wofi**) |
| `$mainMod + N` | Launch **Neovim** |

### 🛠 Terminal Tools (Floating)
| Shortcut | Action |
|---|---|
| `$mainMod + Q` | System info (**Fastfetch**) |
| `$mainMod + T` | System monitor (**Btop**) |
| `$mainMod + L` | Git interface (**Lazygit**) |
| `$mainMod + U` | Matrix effect (**Unimatrix**) |

### 🪟 Window Management
| Shortcut | Action |
|---|---|
| `$mainMod + W` | Kill active window |
| `$mainMod + V` | Toggle floating mode |
| `$mainMod + J` | Toggle split |
| `$mainMod + M` | Fullscreen toggle |
| `Alt + Tab` | Cycle next window |
| `$mainMod + Arrows` | Resize active window |
| `$mainMod + Shift + Arrows` | Move window position |

### 🌌 Workspaces
| Shortcut | Action |
|---|---|
| `$mainMod + [0-9]` | Switch to workspace 1-10 |
| `$mainMod + Shift + [0-9]` | Move window to workspace 1-10 |
| `$mainMod + Mouse_Scroll` | Cycle through workspaces |
| **Special Workspaces:** ||
| `AltGr + ,` | Toggle Calculator |
| `$mainMod + Y` | Toggle Spotify |
| `$mainMod + H` | Toggle Magic workspace |

### 🔉 Audio & Brightness
| Shortcut | Action |
|---|---|
| `Ctrl + Shift + Up/Down` | Screen brightness +/- |
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute audio |
| `XF86AudioMicMute` | Mute microphone |
| `Media Keys` | Play/Pause/Next/Prev via `playerctl` |

---

## ❗ Important Notes

It is crucial to **back up your system before copying any files** from this repository. Please be aware that existing files in `~/.config` **will be overwritten** if there are name collisions. The author is **not responsible** for any broken setups or lost configurations that may result from using these dotfiles.

---

## 📝 Notes & Credits
The GTK CSS implementation is currently experimental and may have some minor issues. Contributions and improvements in this area are highly welcome.

---

## 🤝 Contributions

Suggestions, fixes, and improvements are welcome. Feel free to open an issue or PR.
