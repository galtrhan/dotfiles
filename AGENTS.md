# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for an Arch Linux system using **GNU stow** to manage configuration files. Configuration directories from the repo are symlinked into `~/.config/` via stow, making the dotfiles repo the source of truth for system configuration.

## Architecture

### Stow-Based Structure

The repository uses GNU stow to manage symlinks. The directory structure mirrors `~/.config/`:

```
.dotfiles/
├── .config/
│   ├── fish/          # Fish shell configuration
│   ├── hypr/          # Hyprland (Wayland WM) configuration
│   ├── waybar/        # Waybar (status bar) configuration
│   ├── nvim/          # Neovim configuration
│   ├── tmux/          # Tmux configuration + plugins (tpm, tmux-resurrect, tmux-gruvbox)
│   ├── ghostty/       # Ghostty terminal configuration
│   ├── dunst/         # Dunst notification daemon configuration
│   ├── rofi/          # Rofi launcher configuration
│   └── systemd/       # Systemd user units
├── install.sh         # Installation script (sets up packages and applies stow)
└── README.md
```

To activate dotfiles: `stow .` from the repo root (creates symlinks in `~`).

### Key Tools

- **fish**: Shell with scripted configuration
- **Hyprland**: Wayland window manager with custom scripts (volume, brightness, power management, wallpaper control)
- **Waybar**: Status bar with custom shell helper scripts
- **Neovim**: Text editor configuration (large, includes plugins)
- **Tmux**: Terminal multiplexer with plugin manager (tpm) and plugins:
  - `tmux-resurrect`: Session persistence
  - `tmux-gruvbox`: Color theme
- **Ghostty, Dunst, Rofi**: Terminal, notifications, and launcher configs

### Custom Scripts

Shell scripts for system integration:

**Hyprland scripts** (`.config/hypr/scripts/`):
- `brightness.sh`, `volume.sh` — System volume/brightness control with dunst notifications
- `wallpaper_rotate.sh`, `wallpaper_control.sh`, `wallpaper_persistence.sh`, `wallpaper_restore.sh` — Wallpaper rotation/persistence across restarts
- `power.sh` — Power management (lock, suspend)
- `screenshot.sh` — Screenshot capture with visual feedback
- `screen_capture.sh` — Video recording with `wf-recorder` (region select, clipboard, notifications)
- `screen_capture_menu.sh` — Rofi menu to pick audio source before recording
- `kbd_monitor.sh` — Keyboard backlight monitoring
- `toggle_solo.sh` — Toggle active window between solo float and tiled layout

**Waybar scripts** (`.config/waybar/`):
- `spotify.sh` — Display active Spotify track and status
- `storage.sh` — Monitor storage usage with warning/critical thresholds
- `get_ip.sh` — Fetch and display external IP
- `screen_capture_indicator.sh` — Show active screen recording status
- `file_check.sh` — Generic file existence checker

All Hyprland scripts integrate with Hyprland keybinds and dunst notifications for user feedback.

### Keybinds (`.config/hypr/configs/keybinds.lua`)

- `Super+Print` — Launch screen recording audio source menu
- `Super+Z` — Launch `shmooz` screen magnifier

## Common Development Commands

### Install/Apply Configuration

```bash
# Full installation (packages + stow)
./install.sh

# Just apply stow (symlink all configs, after manual package install)
stow .

# Unstow (remove symlinks)
stow -D .

# Restow (reapply symlinks)
stow -R .
```

### Configuration Management

```bash
# Make specific tool config symlinks
stow fish           # Only symlink fish config
stow nvim           # Only symlink nvim config

# Make multiple configs
stow fish nvim tmux waybar

# Remove specific symlinks
stow -D fish

# Preview what stow would do (without applying)
stow -nv .
```

## Important Notes

- **All `.config/*/` directories are managed here**—edit configs in the repo; changes propagate via stow symlinks to `~/.config/`.
- **Submodules** are used for tmux plugins (tpm, tmux-resurrect, tmux-gruvbox). Always clone with `git clone --recurse-submodules` or fetch missing submodules with `git submodule update --init --recursive`.
- The `install.sh` script handles full setup (packages + symlinks). It's up-to-date with current `.config/` structure.
- This setup is **Wayland/Hyprland-focused**; X11 environments may need adjustments.
- Fish shell configuration sourced from multiple `.config/fish/` files—check sourcing order when modifying.
- Individual config directories (nvim, tmux plugins, etc.) may have their own documentation/READMEs.

## Config Changes and Reloading

Since this is config-only, changes require verification and reloading:

- **Fish shell**: Changes apply on new shell session or via `source ~/.config/fish/config.fish`
- **Hyprland**: Changes apply on next restart or via `hyprctl reload` (keybind: Super+Shift+R)
- **Tmux**: Reload config with `tmux source-file ~/.tmux.conf` or the bound key (default: Prefix+R)
- **Waybar**: Restart with `killall waybar; waybar &` or similar
- **Other tools** (Ghostty, Dunst, Rofi, Neovim): Usually require application restart

Always verify symlinks are correct after changes: `ls -la ~/.config/{fish,hypr,nvim,etc}`

