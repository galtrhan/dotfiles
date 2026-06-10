# ~/.dotfiles

Personal Arch Linux dotfiles setup using **GNU stow** for managing configuration files. All configs are symlinked from this repo into `~/.config/`, making this the single source of truth.

## What's Included

### Window Manager & Desktop
- **Hyprland** - Wayland window manager with custom scripts (brightness, volume, power, screenshot, wallpaper, screen recording)
- **Waybar** - Status bar with custom widgets (spotify, storage, screen recording indicator, external IP)
- **Rofi** - Application launcher and menu
- **Dunst** - Notification daemon
- **Shmooz** - Screen magnifier (zoom, annotation, spotlight, color picker)

### Shell & Terminal
- **Fish** - Shell configuration and functions
- **Ghostty** - Terminal emulator config
- **Tmux** - Terminal multiplexer with plugins:
  - `tpm` - Plugin manager
  - `tmux-resurrect` - Session persistence
  - `tmux-gruvbox` - Color theme

### Editor & Tools
- **Neovim** - Editor configuration
- **Systemd** - User service units
- **Shmooz** - Screen magnifier with zoom, annotation, spotlight, and color picker

### Screen Recording
- **Screen Capture** - Video recording with `wf-recorder` (region select, audio source picker, clipboard integration, desktop notifications)

## Installation

### Prerequisites

- Arch Linux with `pacman`
- `git` (required for cloning)
- Sudo access

### Quick Start

**Make a backup snapshot first:**
```bash
sudo pacman -S timeshift
sudo timeshift --create --comments "Before installing .dotfiles"
```

**Clone and install:**
```bash
git clone --recurse-submodules https://codeberg.org/galtrhan/dotfiles ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

The script will:
1. Update pacman database
2. Install all required packages
3. Remove any existing default configs
4. Initialize/update git submodules (tmux plugins)
5. Install udev LED permission rules for mute/mic mute keys
6. Apply stow to create symlinks
7. Start bluetooth service

### Manual Installation

If you prefer to install packages separately:

```bash
git clone --recurse-submodules https://codeberg.org/galtrhan/dotfiles ~/.dotfiles
cd ~/.dotfiles
git submodule update --init --recursive
sed "s/__DOTFILES_USER__/$(id -un)/g; s/__DOTFILES_GROUP__/$(id -gn)/g" \
  ~/.dotfiles/.config/hypr/udev/90-audio-leds.rules \
  | sudo tee /etc/udev/rules.d/90-audio-leds.rules > /dev/null
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=leds
stow .  # Create symlinks for all configs
```

### Init System Setup

Services are provided for both **systemd** (Arch) and **runit** (Artix):

#### On Arch (systemd)

After stowing, enable the wallpaper rotation service:

```bash
systemctl --user enable wallpaper-rotate.service
systemctl --user start wallpaper-rotate.service
```

#### On Artix (runit)

After stowing, symlink the runit service:

```bash
mkdir -p ~/.local/share/runit/sv
ln -s ~/.config/runit/sv/wallpaper-rotate ~/.local/share/runit/sv/
```

Then ensure `runsvdir` monitors your service directory. If not already running, add to your shell startup (e.g., `~/.config/fish/config.fish`):

```bash
runsvdir -P ~/.local/share/runit/sv
```

## Managing Configs with Stow

```bash
# Apply all configs
git submodule update --init --recursive  # Ensure tmux plugins are present
stow .

# Apply specific configs only
stow fish nvim tmux waybar

# Preview changes without applying
stow -nv .

# Remove symlinks
stow -D .

# Reapply symlinks
stow -R .
```

## Keybinds

### General
| Key | Action |
|-----|--------|
| `Super+Return` | Open terminal (Ghostty) |
| `Super+W` | Open browser (Zen) |
| `Super+E` | Open file manager (Nautilus) |
| `Super+Space` | Application launcher (Rofi) |
| `Super+L` | Lock screen (Hyprlock) |
| `Super+P` | Power menu |
| `Super+Q` | Kill active window |
| `Super+C` | Toggle floating |
| `Super+F` | Fullscreen |
| `Super+Shift+V` | Clipboard history (Cliphist) |
| `Super+B` | Toggle Waybar |
| `Super+G` | Toggle Ghostty solo layout (75% × 70% centered) |

### Screen Capture & Recording
| Key | Action |
|-----|--------|
| `Super+Print` | Audio source picker → start/stop video recording |
| `Print` | Screenshot (region) |

### Screen Magnifier
| Key | Action |
|-----|--------|
| `Super+Z` | Launch `shmooz` screen magnifier (scroll to zoom, drag to pan, right-click to exit) |

### Window Management
| Key | Action |
|-----|--------|
| `Super+Arrows` | Move focus between windows |
| `Super+Shift+[0-9]` | Move window to workspace |
| `Super+[0-9]` | Switch to workspace |
| `Super+S` | Toggle scratchpad (magic workspace) |
| `Super+\` | Toggle terminal scratchpad |

### Wallpaper & Multimedia
| Key | Action |
|-----|--------|
| `Super+Shift+B` | Change wallpaper |
| `XF86MonBrightnessUp/Down` | Adjust screen brightness (requires `brightnessctl`) |
| `XF86AudioRaiseVolume/LowerVolume` | Adjust volume |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Toggle microphone mute |

## Directory Structure

```
~/.dotfiles/
├── .config/
│   ├── fish/          # Shell configuration
│   ├── hypr/          # Hyprland WM config + scripts (brightness, volume, power, screenshot, screen recording, wallpaper)
│   ├── waybar/        # Status bar + custom scripts
│   ├── nvim/          # Neovim configuration
│   ├── tmux/          # Tmux + plugins
│   ├── ghostty/       # Terminal emulator config
│   ├── dunst/         # Notification daemon
│   ├── rofi/          # Application launcher
│   └── systemd/       # Systemd user units
├── install.sh         # Installation script (packages + stow)
└── README.md
```

## Notes

- This setup is tailored for Wayland (Hyprland) and may require adjustments for other environments
- Config submodules are included for tmux plugins—clone with `--recurse-submodules`
- Each config directory may have its own documentation
- **Brightness control** (`brightnessctl`) is required for screen brightness adjustments. Installed by `install.sh`
- **Mute LED control** for `XF86AudioMute` and `XF86AudioMicMute` uses udev ownership rules installed by `install.sh`
- For development or contributions, see [CLAUDE.md](./CLAUDE.md)
