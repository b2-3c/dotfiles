# Hyprland Dotfiles

![Screenshot](screenshots/1.png)

A personal Hyprland setup built on **Catppuccin** — clean, fast, and customizable.

---

## 🖥️ Components

| Component | Tool |
|-----------|------|
| Compositor | Hyprland |
| Bar | Waybar |
| Launcher | Rofi (wayland) |
| Terminal | Kitty |
| Notifications | SwayNC |
| Wallpaper | swww |
| Lock Screen | Hyprlock + Hypridle |
| Shell Prompt | Starship |
| File Manager | Nautilus |
| Clipboard | cliphist |

---

## ✨ Features

### 🎨 Theme System
Change the theme with one click from **Menu → Style** — applies instantly to:
- Waybar · SwayNC · Kitty · Rofi · btop · Window borders

**Available themes:** `catppuccin-mocha` · `catppuccin-frappe` · `catppuccin-macchiato` · `catppuccin-latte`

---

### 󰸉 Wallpaper Menu (`Super + I`)

| Option | Function |
|--------|----------|
| 󰸉 Desktop Wallpaper | Change desktop wallpaper + lock screen together |
| 󰷛 Lock Screen Wallpaper | Change lock screen wallpaper only |
| 󰀄 Account Avatar | Change avatar on lock screen |
| 󰑓 Random Wallpaper | Set a random wallpaper |
| 󰹑 Set per Monitor | Set different wallpaper per monitor |
| 󰋩 Open Wallpaper Folder | Open wallpapers folder |

> Wallpapers are read from `~/Wallpapers/Pictures/` with thumbnail previews.
> Avatar images are read from `~/Wallpapers/Users/`.

---

### 󰅍 Clipboard (`Super + V`)

- **Text** → Classic rofi interface
- **Images** → Shown as thumbnails with preview
- **Mixed** → Asks first: text or images?

---

### 󰷛 Lock Screen (`Super + Shift + Backspace`)

- Background is your last chosen wallpaper (auto-saved with blur)
- Time and date centered
- Avatar and password field
- Mouse cursor visible

---

### 󰀻 Rofi Main Menu

| Option | Function |
|--------|----------|
| 󰕰 Apps | Full app launcher with icons |
| 󰒓 Style | Change theme for all apps |
| 󰄠 Install | Install packages |
| 󰗼 Remove | Remove packages |
| 󰑓 Update | Update system |
| ⏻ System | Lock · Logout · Suspend · Reboot · Shutdown |

---

## ⚙️ Installation

### Automatic

```bash
git clone https://github.com/b2-3c/dotfiles
cd dotfiles
bash install.sh
```

Or directly:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/b2-3c/dotfiles/main/install.sh)"
```

> The installer handles everything: package installation, copying files, setting permissions, enabling services, and setting the default wallpaper and avatar.

### Manual

```bash
git clone https://github.com/b2-3c/dotfiles
cd dotfiles

cp -r .config/* ~/.config/

mkdir -p ~/Pictures/Screenshots ~/Wallpapers/Pictures ~/Wallpapers/Users

find ~/.config/hypr/scripts    -type f              -exec chmod +x {} +
find ~/.config/hypr/nowplaying -type f -name "*.sh" -exec chmod +x {} +
find ~/.config/rofi/scripts    -type f -name "*.sh" -exec chmod +x {} +
find ~/.config/waybar/scripts  -type f              -exec chmod +x {} +
find ~/.config/swaync/scripts  -type f -name "*.sh" -exec chmod +x {} +

cp ~/.config/waybar/themes/catppuccin-mocha.css ~/.config/waybar/theme.css
cp ~/.config/rofi/themes/catppuccin-mocha.rasi  ~/.config/rofi/theme.rasi
cp ~/.config/swaync/themes/catppuccin-mocha.css ~/.config/swaync/theme.css
cp ~/.config/kitty/themes/catppuccin-mocha.conf ~/.config/kitty/theme.conf
cp ~/.config/hypr/themes/catppuccin-mocha.conf  ~/.config/hypr/theme.conf
```

---

## 📦 Dependencies

### Core
```
hyprland hyprlock hypridle hyprsunset hyprpicker
xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
xorg-xwayland wayland-protocols qt5-wayland qt6-wayland
grim slurp grimblast-git swww swaync
wl-clipboard cliphist imagemagick
polkit-gnome sddm dbus udiskie
```

### Audio
```
pipewire pipewire-pulse pipewire-alsa wireplumber
pamixer pavucontrol playerctl python-gobject
```

### Network
```
networkmanager nm-connection-editor bluez bluez-utils rfkill
```

### UI
```
waybar rofi-wayland rofi-calc rofi-emoji
brightnessctl upower jq curl fzf libnotify
```

### Applications
```
kitty neovim starship nautilus firefox
btop fastfetch cava lazygit mpv obs-studio
```

### Fonts & Icons
```
ttf-jetbrains-mono-nerd ttf-commit-mono-nerd
noto-fonts noto-fonts-emoji otf-font-awesome
papirus-icon-theme bibata-cursor-theme
```

---

## ⌨️ Keybindings

> `$mod` = Super

### Menus

| Shortcut | Action |
|----------|--------|
| `Super + A` | App launcher |
| `Super + V` | Clipboard |
| `Super + X` | Calculator |
| `Super + M` | Emoji picker |
| `Super + W` | Window switcher |
| `Super + I` | Wallpaper menu |
| `Super + P` | Now Playing |

### Applications

| Shortcut | Action |
|----------|--------|
| `Super + T` | Terminal (Kitty) |
| `Super + C` | Code editor |
| `Super + E` | File manager (Nautilus) |
| `Super + F` | Browser (Firefox) |
| `Super + Shift + F` | Browser private window |
| `Super + Shift + N` | Toggle notifications |

### Screenshots

| Shortcut | Action |
|----------|--------|
| `Print` | Selected area |
| `Super + Print` | Full screen |
| `Super + Alt + Print` | Active window |

### Audio

| Shortcut | Action |
|----------|--------|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute |
| `XF86AudioMicMute` | Mute microphone |
| `Super + Alt + R/L` | Volume up/down |
| `Super + Alt + M` | Mute |
| `XF86AudioPlay/Next/Prev` | Media control |

### Brightness

| Shortcut | Action |
|----------|--------|
| `XF86MonBrightnessUp/Down` | Brightness up/down |
| `Super + Alt + U/D` | Brightness up/down |

### Window Management

| Shortcut | Action |
|----------|--------|
| `Super + Q` | Close window |
| `Super + Return` | Fullscreen |
| `Super + Shift + W` | Float window |
| `Super + \` | Next window |
| `Super + H/J/K/L` | Move focus |
| `Super + Arrows` | Move focus |
| `Super + Shift + H/J/K/L` | Resize |
| `Super + S` | Special workspace |
| `Super + Shift + Drag` | Drag window |
| `Super + Right Click` | Resize with mouse |

### Workspaces

| Shortcut | Action |
|----------|--------|
| `Super + 1-0` | Switch to workspace 1-10 |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + Alt + 1-0` | Silent move |
| `Super + Ctrl + Left/Right` | Previous/Next workspace |
| `Super + Ctrl + H/L` | Previous/Next workspace |
| `Super + Ctrl + Down/J` | First empty workspace |

### System

| Shortcut | Action |
|----------|--------|
| `Super + Shift + Backspace` | Lock screen |
| `Super + Ctrl + W` | Restart Waybar |
| `Super + Alt + B` | Toggle Bluetooth |
| `Super + Alt + N` | Toggle Wi-Fi |

---

## 📁 File Structure

```
~/.config/
├── hypr/
│   ├── hyprland.conf
│   ├── hyprlock.conf
│   ├── hypridle.conf
│   ├── theme.conf              # ← active border colors (copied from themes/)
│   ├── themes/                 # border color per theme
│   ├── custom/
│   │   ├── binds.conf          # keybindings
│   │   ├── exec.conf           # autostart apps
│   │   ├── monitors.conf       # ← edit this
│   │   ├── devices.conf        # ← edit this
│   │   ├── rules.conf
│   │   └── variables.conf
│   ├── scripts/
│   │   ├── set-theme           # theme switcher
│   │   ├── lock.sh
│   │   └── screenshot.sh
│   └── nowplaying/
│
├── waybar/
│   ├── config.jsonc
│   ├── style.css
│   ├── theme.css               # ← copied from themes/
│   └── themes/
│
├── rofi/
│   ├── theme.rasi
│   └── scripts/
│       ├── wallpaper-menu.sh
│       └── launcher-menu.sh
│
├── swaync/
├── kitty/
├── btop/
├── cava/
├── fastfetch/
└── starship.toml

~/
├── Wallpapers/
│   ├── Pictures/               # desktop wallpapers
│   └── Users/                  # avatar images
└── Pictures/
    └── Screenshots/
```

---

## ⚠️ Manual Configuration After Install

| File | What to Edit |
|------|-------------|
| `~/.config/hypr/custom/monitors.conf` | Monitor name and resolution |
| `~/.config/hypr/custom/devices.conf` | Keyboard and mouse names |
| `~/.config/waybar/scripts/weather.sh` | Set LAT and LON coordinates |

---

## 📝 Notes

- Default wallpaper: `MistyTrees.jpg` — Default avatar: `avatar.png`
- Changing wallpaper from the menu also updates the lock screen automatically
- Screenshots are saved to `~/Pictures/Screenshots/`
- A config backup is saved to `~/.config_backup_*` on every install

---

## 🤝 Contributing

Suggestions and fixes are welcome — open an Issue or PR.
