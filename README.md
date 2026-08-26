# ~/.dotfiles

Personal Arch Linux dotfiles that use **GNU stow** to manage configuration files. Stow creates symlinks from this repo into `~/.config/`. This repo is the source of truth.

This setup targets a **single-monitor** desktop. Multi-monitor behavior (for example launcher screen targeting) works, but is not the main focus.

## Included Components

### Rootless Docker

These dotfiles configure Docker to run rootless with the pasta network driver.
Rootless Docker does not need root privileges to run containers.
Pasta does not need the tun kernel module, so kernel updates do not break Docker.

What dotfiles provides:

- `install.sh` installs passt (provides pasta), Docker, Compose, rootlesskit, and slirp4netns.
- `.config/systemd/user/docker.service` defines the rootless Docker systemd service.
- `.config/systemd/user/docker.service.d/pasta.conf` sets the pasta network driver and implicit port driver.

After install.sh runs, enable and start Docker:

```bash
systemctl --user enable --now docker.service
```

Verify it works:

```bash
docker info
```

If Docker does not start, check the service log:

```bash
systemctl --user status docker.service
journalctl --user -xeu docker.service
```

### Common problem: tun kernel module missing

A kernel update can remove the tun kernel module from `/lib/modules`.
The pasta network driver does not need the tun module.
Install.sh installs passt. The systemd drop-in then uses pasta automatically.
If pasta is already installed but Docker still does not start, run:

```bash
systemctl --user daemon-reload
systemctl --user restart docker.service
```

### Window Manager & Desktop
- **Hyprland** - Wayland window manager (Lua config) with custom scripts for auth, power, media, wallpaper, and screen capture
- **Hyprlock** - Custom build from [galtrhan/hyprlock](https://github.com/galtrhan/hyprlock) with broken LCD effect (progressive screen glitch on failed auth or lid open)
- **QuickShell** - Status bar, notification center, app launcher, and script menus (QML). Bar includes Cursor plan usage via `cursor_usage_widget.py`.
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
- **DOSBox** - DOS emulator config (at `~/.dosbox/`, not `~/.config/`)
- **Systemd** - User service units (wallpaper rotation, battery notifications)

### Screen Recording
- **Screen Capture** - Video recording with `wf-recorder` (region select, audio source picker, clipboard, desktop notifications). See [`.config/hypr/scripts/screen_capture.md`](.config/hypr/scripts/screen_capture.md).

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

The script does this:
1. Update the pacman database
2. Install all required packages
3. Remove any existing default configs
4. Initialize and update git submodules (tmux plugins)
5. Install udev LED permission rules for mute and mic mute keys
6. Apply stow to create symlinks
7. Disable dunst if it was enabled before (QuickShell owns notifications)
8. Start the bluetooth service

### Manual Installation

If you install packages yourself:

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

Services exist for **systemd** (Arch) and **runit** (Artix):

#### On Arch (systemd)

After stowing, enable the wallpaper rotation service:

```bash
systemctl --user enable wallpaper-rotate.service
systemctl --user start wallpaper-rotate.service
systemctl --user enable --now battery-notify.timer
```

#### On Artix (runit)

After stowing, symlink the runit service:

```bash
mkdir -p ~/.local/share/runit/sv
ln -s ~/.config/runit/sv/wallpaper-rotate ~/.local/share/runit/sv/
```

Then make sure `runsvdir` monitors your service directory. If it is not already running, add this to your shell startup (for example `~/.config/fish/config.fish`):

```bash
runsvdir -P ~/.local/share/runit/sv
```

## Managing Configs with Stow

```bash
# Apply all configs
git submodule update --init --recursive  # Make sure tmux plugins are present
stow .

# Apply specific configs only
stow fish nvim tmux quickshell

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
| `Super+E` | Open file manager (HyprFM) |
| `Super+Space` | Application launcher (QuickShell) |
| `Super+L` | Lock screen (Hyprlock) |
| `Super+P` | Power menu |
| `Super+Q` | Kill active window |
| `Super+C` | Toggle floating |
| `Super+F` | Fullscreen |
| `Super+Shift+V` | Clipboard history (Cliphist) |
| `Super+B` | Toggle QuickShell bar |
| `Super+Shift+O` | Restart QuickShell |
| `Super+O` | Restart QuickShell (hard restart) |
| `Super+N` | Toggle notification center |
| `Super+Shift+N` | Toggle Do Not Disturb |
| `Super+Ctrl+N` | Clear all notifications |
| `Super+G` | Toggle solo layout on active window (75% × 70% centered float) |

### Screen Capture & Recording
| Key | Action |
|-----|--------|
| `Super+Print` | Audio source picker → start or stop video recording |
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

## Hyprland Scripts

Scripts live in [`.config/hypr/scripts/`](.config/hypr/scripts/). Hyprland is configured via [`.config/hypr/hyprland.lua`](.config/hypr/hyprland.lua).

### Authentication

| Script | Trigger | Description |
|--------|---------|-------------|
| [`sudo_askpass.sh`](.config/hypr/scripts/sudo_askpass.sh) | Non-interactive `sudo` (no TTY) | Graphical sudo password prompt used as `SUDO_ASKPASS` |

**Sudo askpass behavior:**
- Sends a critical desktop notification when a password is required
- Shows a QuickShell password overlay via `qs ipc call menu show_password`
- Returns the entered password on stdout for `sudo -A` (empty string if cancelled)

Fish is configured in [`.config/fish/config.fish`](.config/fish/config.fish) to use `sudo -A` only when stdin is not a terminal (for example agent subprocesses). Interactive terminal `sudo` prompts in the shell as usual.

Requires QuickShell to be running (started with Hyprland).

### Power & Session

| Script | Trigger | Description |
|--------|---------|-------------|
| [`power.sh`](.config/hypr/scripts/power.sh) | `Super+P` | QuickShell menu: lock, logout, suspend, reboot, shutdown |
| [`qs-menu.sh`](.config/hypr/scripts/qs-menu.sh) | Called by scripts | Generic QuickShell menu picker (replaces dmenu-style prompts) |
| [`battery.sh`](.config/hypr/scripts/battery.sh) | `battery-notify.timer` | Low-battery notifications at 20/15/10%. **5% meltdown overlay** with alarm, countdown, and auto-suspend. See [`.config/hypr/scripts/battery.md`](.config/hypr/scripts/battery.md). |

### Hardware Controls

| Script | Trigger | Description |
|--------|---------|-------------|
| [`brightness.sh`](.config/hypr/scripts/brightness.sh) | `XF86MonBrightnessUp/Down` | Adjust backlight via `brightnessctl` with QuickShell OSD feedback |
| [`volume.sh`](.config/hypr/scripts/volume.sh) | `XF86Audio*` keys | Volume, mute, and mic control via PipeWire (`wpctl`) with QuickShell OSD feedback and ThinkPad mute LED sync |
| [`kbd_monitor.sh`](.config/hypr/scripts/kbd_monitor.sh) | Hyprland autostart | Watches keyboard backlight changes and shows QuickShell notifications |

### Window Layout

| Script | Trigger | Description |
|--------|---------|-------------|
| [`toggle_solo.sh`](.config/hypr/scripts/toggle_solo.sh) | `Super+G` | Toggle active window between tiled and solo float (75% × 70%, centered) |

### Wallpaper

| Script | Role |
|--------|------|
| [`wallpaper_control.sh`](.config/hypr/scripts/wallpaper_control.sh) | CLI for rotation service and on-demand changes (`Super+Shift+B` → `change`) |
| [`wallpaper_restore.sh`](.config/hypr/scripts/wallpaper_restore.sh) | Restores last wallpaper on Hyprland startup |
| [`wallpaper_rotate.sh`](.config/hypr/scripts/wallpaper_rotate.sh) | Rotation loop used by `wallpaper-rotate.service` |
| [`wallpaper_cron.sh`](.config/hypr/scripts/wallpaper_cron.sh) | Single wallpaper change (used by control script or cron) |
| [`wallpaper_persistence.sh`](.config/hypr/scripts/wallpaper_persistence.sh) | Save and restore wallpaper state across restarts |

Full wallpaper system docs: [`.config/hypr/scripts/wallpaper.md`](.config/hypr/scripts/wallpaper.md)

### Screen Capture & Screenshots

| Script | Trigger | Description |
|--------|---------|-------------|
| [`screen_capture_menu.sh`](.config/hypr/scripts/screen_capture_menu.sh) | `Super+Print` | QuickShell picker for audio source, then start or stop recording |
| [`screen_capture.sh`](.config/hypr/scripts/screen_capture.sh) | Called by menu | Region recording via `wf-recorder` and `slurp`, clipboard copy, notifications |
| [`screenshot.sh`](.config/hypr/scripts/screenshot.sh) / [`screenshot.py`](.config/hypr/scripts/screenshot.py) | `Print` | Region screenshot via `hyprshot` |
| [`ip_widget.sh`](.config/hypr/scripts/ip_widget.sh) | QuickShell IP widget right click | Save current MAC to history and randomize MAC with `macchanger` |
| [`cursor_usage_widget.py`](.config/hypr/scripts/cursor_usage_widget.py) | QuickShell Cursor usage widget | Read plan pool % from `cursor.com/api/usage-summary` for the status bar |

Full screen capture docs: [`.config/hypr/scripts/screen_capture.md`](.config/hypr/scripts/screen_capture.md)

## QuickShell Launcher & Menus

App launcher and script menus are built into QuickShell (`.config/quickshell/launcher/`). Hyprland keybinds call `qs ipc`:

| IPC target | Function | Use |
|------------|----------|-----|
| `launcher` | `toggle`, `open`, `close` | App launcher (`Super+Space`) |
| `menu` | `show(title, options)` | Compact script menus (`qs-menu.sh --compact`) |
| `menu` | `show_search(title, options)` | Wide searchable picker (default in `qs-menu.sh`) |
| `menu` | `show_password(prompt)` | Sudo password prompt |

Examples:

```bash
qs ipc call launcher toggle
qs ipc call -- menu show "Power Menu" $'Lock\nLogout\nSuspend'
~/.config/hypr/scripts/qs-menu.sh "Recording Audio" "None (no audio)" "System Audio (output)"
```

QuickShell reloads QML on save. Restart with `Super+Shift+O` or `pkill quickshell; quickshell &`.

### IP Widget

The status bar IP widget shows your public IP address. It polls `api.ipify.org` every 30 seconds.

| Action | Result |
|--------|--------|
| Hover | Tooltip shows public IP, current MAC, and up to three previous MAC addresses |
| Left click | Copy public IP to clipboard |
| Right click | Save current MAC to history and set a random MAC with `macchanger` |

The tooltip lists the current MAC at full brightness. Each older MAC in history is 10% dimmer than the line above it.

MAC history is stored at `~/.local/state/quickshell/mac-history`. The file keeps the last three MAC addresses. When you randomize, the script removes the oldest entry if the list is full.

The script is [`.config/hypr/scripts/ip_widget.sh`](.config/hypr/scripts/ip_widget.sh). It uses the default route network interface. Random MAC change needs `sudo` and uses the graphical askpass prompt when QuickShell runs the script.

`install.sh` installs `macchanger`.

### Cursor Usage Widget

The status bar shows Cursor plan usage after the IP widget. It polls [`.config/hypr/scripts/cursor_usage_widget.py`](.config/hypr/scripts/cursor_usage_widget.py) every five minutes. The script reads your Cursor IDE session from `state.vscdb` and calls `GET https://cursor.com/api/usage-summary` with a `cursor-agent` User-Agent.

| Display | Meaning |
|---------|---------|
| Cursor icon + `6% / 12%` | Included (Auto + Composer) and API pool **used** % |
| Blue | Used &lt; 60% |
| Orange | Used 60–84% |
| Red | Used ≥ 85% |

| Action | Result |
|--------|--------|
| Hover | Tooltip with plan, account, and per-pool used / left % |
| Left click | Open [cursor.com/dashboard/usage](https://cursor.com/dashboard/usage) |

**Requirements:**

- Sign in to the **Cursor IDE** on this machine (`~/.config/Cursor/User/globalStorage/state.vscdb`).
- `python3` on PATH (stdlib only; no extra packages).
- The widget stays hidden if auth fails or the API returns no meters.

Verify from the terminal:

```bash
python3 ~/.config/hypr/scripts/cursor_usage_widget.py | python3 -m json.tool
```

**Note on `usagenometer` (`usg`):** The AUR package [usagenometer](https://github.com/horizzon3507/usagenometer) is optional for terminal meters. As of 0.1.2-beta it calls `www.cursor.com` with a custom User-Agent and may report `Cursor session was rejected` even when the IDE is signed in. This dotfiles bar uses `cursor_usage_widget.py` instead, which matches how the Cursor CLI reaches the API.

Widget code: [`.config/quickshell/widgets/CursorUsageWidget.qml`](.config/quickshell/widgets/CursorUsageWidget.qml). Parser: [`.config/quickshell/lib/CursorUsageLogic.js`](.config/quickshell/lib/CursorUsageLogic.js).

### Battery Meltdown Overlay

At **5% battery** while discharging, QuickShell shows a full-screen critical overlay (not the corner popup). The overlay uses a flashing red UI, a looping `meltdown.mp3` alarm, and a **60-second countdown**. When the countdown ends, the system suspends. Click to dismiss, or plug in to cancel.

Requires `battery-notify.timer`, `ffmpeg` (`ffplay`), and `~/.config/quickshell/sounds/meltdown.mp3`. Full details: [`.config/hypr/scripts/battery.md`](.config/hypr/scripts/battery.md).

## Configuration

Common tuning points:

| Setting | File | Property / location |
|---------|------|---------------------|
| Notification badge exclusions (tray apps that should not increment the unread count) | [`.config/quickshell/NotificationService.qml`](.config/quickshell/NotificationService.qml) | `badgeExcludedApps` |
| Battery meltdown suspend countdown | [`.config/quickshell/BatteryMeltdownService.qml`](.config/quickshell/BatteryMeltdownService.qml) | `suspendDelaySec` |
| Battery meltdown alarm file | [`.config/quickshell/Paths.qml`](.config/quickshell/Paths.qml) | `batteryMeltdownSound` |
| Low-battery thresholds | [`.config/hypr/scripts/battery.sh`](.config/hypr/scripts/battery.sh) | `THRESHOLDS` |
| IP widget MAC history size | [`.config/hypr/scripts/ip_widget.sh`](.config/hypr/scripts/ip_widget.sh) | `MAX_HISTORY` |
| IP widget MAC history file | `~/.local/state/quickshell/mac-history` | Written by `ip_widget.sh` |
| Cursor usage poll interval | [`.config/quickshell/widgets/CursorUsageWidget.qml`](.config/quickshell/widgets/CursorUsageWidget.qml) | `ScriptPoll` `interval` (default: 300000 ms) |
| Cursor usage fetch script | [`.config/hypr/scripts/cursor_usage_widget.py`](.config/hypr/scripts/cursor_usage_widget.py) | stdout → JSON for QuickShell |
| Cursor usage bar icon | [`.config/quickshell/icons/cursor.png`](.config/quickshell/icons/cursor.png) | 32×32 bar icon (`Paths.cursorIcon`) |
| Clipboard history size (text / image) | [`.config/hypr/hyprland.lua`](.config/hypr/hyprland.lua) | `cliphist -max-items` in the `wl-paste --watch` autostart lines (default: 100 text, 10 image) |
| Launcher list highlight color | [`.config/quickshell/Theme.qml`](.config/quickshell/Theme.qml) | `launcherHighlight` |

Notification history exclusions (volume, brightness, keyboard OSD) are in the same `NotificationService.qml` file under `historyExcludedApps`.

## Directory Structure

```
~/.dotfiles/
├── .config/
│   ├── fish/          # Shell configuration
│   ├── hypr/          # Hyprland Lua config, window rules, and scripts (see Hyprland Scripts)
│   ├── quickshell/    # Status bar, notifications, app launcher, menus (QML)
│   ├── nvim/          # Neovim configuration
│   ├── tmux/          # Tmux + plugins
│   ├── ghostty/       # Terminal emulator config
│   └── systemd/       # Systemd user units
├── .dosbox/           # DOSBox config (symlinked to ~/.dosbox/)
├── install.sh         # Installation script (packages + stow)
└── README.md
```

## Notes

- Targets a **single monitor**. Multi-monitor setups may need launcher or notification tweaks.
- This setup is for Wayland (Hyprland). Other environments may need changes.
- Config submodules are included for tmux plugins. Clone with `--recurse-submodules`.
- Each config directory may have its own documentation.
- **Brightness control** (`brightnessctl`) is required for screen brightness. `install.sh` installs it.
- **Mute LED control** for `XF86AudioMute` and `XF86AudioMicMute` uses udev ownership rules that `install.sh` installs.
- **Sudo askpass** needs Fish (for the non-TTY `sudo -A` wrapper) and QuickShell for the password overlay. It applies when stdin is not a terminal.
- **Desktop notifications** are handled by QuickShell (`notify-send` / `libnotify`). Disable or mask `dunst.service` if you migrate from an older setup.
- **Cursor usage in the bar** reads the local Cursor IDE session via `cursor_usage_widget.py`. Sign in to Cursor IDE. Run the script manually if the widget does not appear.
- **Battery meltdown** at 5% uses a QuickShell full-screen overlay with alarm sound and auto-suspend countdown. See [`.config/hypr/scripts/battery.md`](.config/hypr/scripts/battery.md).
- **Hyprlock** is a custom build from [galtrhan/hyprlock](https://github.com/galtrhan/hyprlock), not the upstream `hyprlock` package. The `broken_lcd` effect and `--grace` flag need this fork. Build with cmake (see repo README) and `sudo cmake --install build`.
- For development or contributions, see [AGENTS.md](./AGENTS.md)
