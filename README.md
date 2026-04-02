# ~/.dotfiles

Personal Arch Linux dotfiles setup using **GNU stow** for managing configuration files. All configs are symlinked from this repo into `~/.config/`, making this the single source of truth.

## What's Included

### Window Manager & Desktop
- **Hyprland** - Wayland window manager with custom scripts (brightness, volume, power, screenshot, wallpaper)
- **Waybar** - Status bar with custom widgets (spotify, storage monitoring)
- **Rofi** - Application launcher and menu
- **Dunst** - Notification daemon

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
4. Apply stow to create symlinks
5. Start bluetooth service

### Manual Installation

If you prefer to install packages separately:

```bash
git clone --recurse-submodules https://codeberg.org/galtrhan/dotfiles ~/.dotfiles
cd ~/.dotfiles
stow .  # Create symlinks for all configs
```

## Managing Configs with Stow

```bash
# Apply all configs
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

## Directory Structure

```
~/.dotfiles/
├── .config/
│   ├── fish/          # Shell configuration
│   ├── hypr/          # Hyprland WM config + scripts
│   ├── waybar/        # Status bar + custom scripts
│   ├── nvim/          # Neovim configuration
│   ├── tmux/          # Tmux + plugins
│   ├── ghostty/       # Terminal emulator config
│   ├── dunst/         # Notification daemon
│   ├── rofi/          # Application launcher
│   └── systemd/       # Systemd user units
└── install.sh
```

## Notes

- This setup is tailored for Wayland (Hyprland) and may require adjustments for other environments
- Config submodules are included for tmux plugins—clone with `--recurse-submodules`
- Each config directory may have its own documentation
- For development or contributions, see [CLAUDE.md](./CLAUDE.md)
