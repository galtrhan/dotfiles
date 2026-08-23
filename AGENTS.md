# AGENTS.md

Guidance for work on code in this repository.

## Repository Overview

This is a personal dotfiles repository for an Arch Linux system. It uses **GNU stow** to manage configuration files. Stow creates symlinks from the repo into `~/.config/`. The dotfiles repo is the source of truth for system configuration.

## Architecture

### Stow-Based Structure

The repository uses GNU stow to manage symlinks. The directory structure mirrors `~/.config/`:

```
.dotfiles/
├── .config/
│   ├── fish/          # Fish shell configuration
│   ├── hypr/          # Hyprland (Wayland WM) configuration
│   ├── quickshell/    # QuickShell bar, notifications, app launcher, menus (QML)
│   ├── nvim/          # Neovim configuration
│   ├── tmux/          # Tmux configuration + plugins (tpm, tmux-resurrect, tmux-gruvbox)
│   ├── ghostty/       # Ghostty terminal configuration
│   └── systemd/       # Systemd user units
├── install.sh         # Installation script (sets up packages and applies stow)
└── README.md
```

To activate dotfiles, run `stow .` from the repo root. This creates symlinks in `~`.

### Key Tools

- **fish**: Shell with scripted configuration
- **Hyprland**: Wayland window manager with custom scripts (volume, brightness, power management, wallpaper control)
- **Hyprlock**: Custom build from [galtrhan/hyprlock](https://github.com/galtrhan/hyprlock). Adds broken LCD effect (progressive screen glitch on failed auth or laptop lid open) and `--grace` flag. Not the upstream package. Build from source with cmake.
- **QuickShell**: QtQuick-based status bar, notification center, app launcher, and script menus (QML in `.config/quickshell/`)
  - **Battery meltdown** (`BatteryMeltdownService.qml`, `notifications/BatteryMeltdownOverlay.qml`): full-screen 5% battery alert with `meltdown.mp3` alarm and 60s suspend countdown. Triggered by `REACTOR CRITICAL` notifications from `battery.sh`.
- **Neovim**: Text editor configuration (large, includes plugins)
- **Tmux**: Terminal multiplexer with plugin manager (tpm) and plugins:
  - `tmux-resurrect`: Session persistence
  - `tmux-gruvbox`: Color theme
- **Ghostty**: Terminal emulator config

### Custom Scripts

Shell scripts for system integration:

**Hyprland scripts** (`.config/hypr/scripts/`):
- `brightness.sh`, `volume.sh` — System volume and brightness control with QuickShell OSD notifications
- `battery.sh` — Low-battery `notify-send` alerts (20/15/10%). At 5% triggers QuickShell **battery meltdown** overlay
- `wallpaper_rotate.sh`, `wallpaper_control.sh`, `wallpaper_persistence.sh`, `wallpaper_restore.sh` — Wallpaper rotation and persistence across restarts
- `power.sh` — Power management (lock, suspend) via QuickShell menu
- `qs-menu.sh` — Generic QuickShell menu picker for shell scripts
- `sudo_askpass.sh` — Graphical sudo password prompt via QuickShell. Any command needing root runs as `sudo -A <cmd>` so the QuickShell prompt fires. Never `sudo -n`; it refuses to call the askpass helper and fails outright.
- `screenshot.sh` — Screenshot capture with visual feedback
- `screen_capture.sh` — Video recording with `wf-recorder` (region select, clipboard, notifications)
- `screen_capture_menu.sh` — QuickShell menu to pick audio source before recording
- `kbd_monitor.sh` — Keyboard backlight monitoring
- `toggle_solo.sh` — Toggle active window between solo float and tiled layout

All Hyprland scripts work with Hyprland keybinds and QuickShell desktop notifications for user feedback.

### Keybinds (`.config/hypr/configs/keybinds.lua`)

- `Super+Space` — Toggle QuickShell app launcher
- `Super+P` — Power menu
- `Super+Shift+V` — Clipboard history picker
- `Super+Print` — Launch screen recording audio source menu
- `Super+Z` — Launch `shmooz` screen magnifier
- `Super+N` — Toggle QuickShell notification center
- `Super+Shift+N` — Toggle Do Not Disturb
- `Super+Ctrl+N` — Clear all notifications

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
stow fish nvim tmux quickshell

# Remove specific symlinks
stow -D fish

# Preview what stow would do (without applying)
stow -nv .
```

## Important Notes

- **All `.config/*/` directories are managed here**. Edit configs in the repo. Changes reach `~/.config/` through stow symlinks.
- **Submodules** are used for tmux plugins (tpm, tmux-resurrect, tmux-gruvbox). Always clone with `git clone --recurse-submodules`, or fetch missing submodules with `git submodule update --init --recursive`.
- The `install.sh` script handles full setup (packages and symlinks). It matches the current `.config/` structure.
- This setup is **Wayland/Hyprland-focused**. X11 environments may need changes.
- **Rootless Docker** is configured. The Docker daemon runs as a systemd user service (`docker.service`). `DOCKER_HOST` is set in `config.fish` to `unix://$XDG_RUNTIME_DIR/docker.sock`. Linger is enabled so the service starts on boot. The user was removed from the `docker` group after rootless setup.
- Fish shell configuration is sourced from multiple `.config/fish/` files. Check sourcing order when you change them.
- Individual config directories (nvim, tmux plugins, and others) may have their own documentation or READMEs.
- **`lnd`** (Latvian Name Days) is an external tool at [codeberg.org/galtrhan/latvian-name-days](https://codeberg.org/galtrhan/latvian-name-days). Build with `zig build -Doptimize=ReleaseSmall` and copy to `~/.local/bin/lnd`.
- **Battery notifications**: `battery.sh` and `battery-notify.timer`. 5% meltdown docs are in `.config/hypr/scripts/battery.md`. Alarm file: `~/.config/quickshell/sounds/meltdown.mp3` (user-provided).
- **Hyprlock** uses a custom fork (`github.com/galtrhan/hyprlock`) that adds the `broken_lcd` effect and `--grace` flag. The `install.sh` does not install the upstream `hyprlock` package. Build from source with:

```bash
cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
cmake --build ./build --config Release --target hyprlock -j$(nproc)
sudo cmake --install build
```

## Config Changes and Reloading

This repo holds config only. After changes, verify and reload:

- **Fish shell**: Changes apply on a new shell session, or via `source ~/.config/fish/config.fish`
- **Hyprland**: Changes apply on the next restart, or via `hyprctl reload` (keybind: Super+Shift+R)
- **Tmux**: Reload config with `tmux source-file ~/.tmux.conf` or the bound key (default: Prefix+R)
- **QuickShell**: Reloads on file save (watches `~/.config/quickshell/`). To restart: `pkill quickshell && quickshell &`
- **Other tools** (Ghostty, Neovim): Usually need an application restart

Always verify symlinks after changes: `ls -la ~/.config/{fish,hypr,nvim,etc}`
