# Wallpaper System for Hyprland

Wallpaper management for Hyprland with hyprpaper. Supports automatic rotation, persistence across restarts, and manual control.

## System Overview

The system has two parts:
- **Automatic rotation**: Changes wallpapers at set intervals
- **Persistence**: Saves and restores your wallpaper across restarts

## Features

### Rotation System
- Changes wallpapers every 30 minutes by default
- Picks a random wallpaper from your collection
- Shows a desktop notification when the wallpaper changes
- Commands to start, stop, and manage rotation
- Starts on login
- Change wallpaper on demand with `SUPER + SHIFT + B`

### Persistence System
- Saves wallpaper state on each change
- Restores wallpaper on Hyprland startup
- Save and restore wallpapers on demand
- Sets a random wallpaper if saved state is invalid
- Commands to manage wallpaper persistence

## Files

### Core Scripts
- `wallpaper_rotate.sh` - Main rotation script (runs continuously)
- `wallpaper_cron.sh` - Single wallpaper change script (for cron jobs)
- `wallpaper_control.sh` - Control script for the service
- `wallpaper_persistence.sh` - Persistence management script
- `wallpaper_restore.sh` - Startup restoration script

### Configuration
- `wallpaper-rotate.service` - Systemd user service file
- `wallpaper_state` - State file (created on first change)
- `hyprland.lua` - Startup restoration via `wallpaper_restore.sh`

## Quick Start

### 1. Check Status
```bash
~/.config/hypr/scripts/wallpaper_control.sh status
```

### 2. Start Rotation
```bash
~/.config/hypr/scripts/wallpaper_control.sh start
```

### 3. Change Wallpaper Now
```bash
~/.config/hypr/scripts/wallpaper_control.sh change
# Or use keyboard shortcut: SUPER + SHIFT + B
```

### 4. Save Current Wallpaper
```bash
~/.config/hypr/scripts/wallpaper_control.sh save
```

## Control Commands

### Wallpaper Control Script
| Command | Description |
|---------|-------------|
| `start` | Start wallpaper rotation |
| `stop` | Stop wallpaper rotation |
| `restart` | Restart the service |
| `status` | Show service status |
| `change` | Change wallpaper now |
| `enable` | Enable auto-start on boot |
| `disable` | Disable auto-start on boot |
| `save` | Save current wallpaper state |
| `restore` | Restore saved wallpaper |
| `help` | Show help message |

### Persistence Script
| Command | Description |
|---------|-------------|
| `save` | Save current wallpaper state |
| `restore` | Restore saved wallpaper |
| `set <path>` | Set a specific wallpaper with persistence |
| `status` | Show current state |
| `clear` | Clear saved state |
| `help` | Show help message |

## Configuration

### Wallpaper Directory
Wallpapers load from: `~/Pictures/Wallpapers/`

### Supported Formats
- PNG, JPG, JPEG, BMP, WebP

### Rotation Interval
Default: 30 minutes

To change the interval, edit the service file:
```bash
nano ~/.config/systemd/user/wallpaper-rotate.service
```

Change the `ExecStart` line:
```ini
ExecStart=%h/.config/hypr/scripts/wallpaper_rotate.sh 60  # 60 minutes
```

Then reload and restart:
```bash
systemctl --user daemon-reload
systemctl --user restart wallpaper-rotate.service
```

### Keyboard Shortcut
- **Shortcut**: `SUPER + SHIFT + B`
- **Action**: Change wallpaper now
- **Location**: `~/.config/hypr/configs/keybinds.lua`

## How Persistence Works

### Automatic Persistence
1. Every wallpaper change saves the new wallpaper path
2. On Hyprland startup, the restore script runs after hyprpaper starts
3. If the saved wallpaper exists, it is restored. Otherwise a random one is set.

### State File
- **Location**: `~/.config/hypr/wallpaper_state`
- **Content**: Full path to the last active wallpaper
- **Created**: When wallpapers change
- **Cleared**: If the saved wallpaper no longer exists

## Manual Usage

### Direct Script Execution
```bash
# Change wallpaper every 30 minutes (default)
~/.config/hypr/scripts/wallpaper_rotate.sh

# Change wallpaper every 60 minutes
~/.config/hypr/scripts/wallpaper_rotate.sh 60

# Change wallpaper every 2 hours
~/.config/hypr/scripts/wallpaper_rotate.sh 120
```

### Cron Job Alternative
```bash
# Edit your crontab
crontab -e

# Add this line to change wallpaper every hour
0 * * * * ~/.config/hypr/scripts/wallpaper_cron.sh
```

### Manual Persistence Control
```bash
# Save current wallpaper
~/.config/hypr/scripts/wallpaper_persistence.sh save

# Restore saved wallpaper
~/.config/hypr/scripts/wallpaper_persistence.sh restore

# Set specific wallpaper with persistence
~/.config/hypr/scripts/wallpaper_persistence.sh set /path/to/wallpaper.png

# Show current state
~/.config/hypr/scripts/wallpaper_persistence.sh status

# Clear saved state
~/.config/hypr/scripts/wallpaper_persistence.sh clear
```

## Systemd Service Management

### Manual Service Control
```bash
# Start service
systemctl --user start wallpaper-rotate.service

# Stop service
systemctl --user stop wallpaper-rotate.service

# Check status
systemctl --user status wallpaper-rotate.service

# Enable on boot
systemctl --user enable wallpaper-rotate.service

# Disable on boot
systemctl --user disable wallpaper-rotate.service
```

### Service Logs
```bash
# View service logs
journalctl --user -u wallpaper-rotate.service -f
```

## Troubleshooting

### Service Not Found
```bash
# Reload systemd daemon
systemctl --user daemon-reload

# Check if service file exists
ls -la ~/.config/systemd/user/wallpaper-rotate.service
```

### Wallpaper Not Changing
- Make sure Hyprland is running
- Check that hyprctl is available
- Verify the wallpaper directory exists and contains images

### Permission Issues
```bash
# Make scripts executable
chmod +x ~/.config/hypr/scripts/*.sh
```

### Wallpaper Not Restoring
1. Check if the state file exists: `ls ~/.config/hypr/wallpaper_state`
2. Check if the saved wallpaper exists: `cat ~/.config/hypr/wallpaper_state`
3. Test manual restore: `~/.config/hypr/scripts/wallpaper_persistence.sh restore`

### Invalid State File
If the saved wallpaper no longer exists:
- The system clears the invalid state
- A random wallpaper is set as fallback
- The new wallpaper is saved as the new state

### Manual Reset
To reset the persistence system:
```bash
# Clear saved state
~/.config/hypr/scripts/wallpaper_persistence.sh clear

# Set a new wallpaper (saved on change)
~/.config/hypr/scripts/wallpaper_control.sh change
```

## Integration

### Hyprland Configuration
The system is part of the Hyprland startup sequence:

```bash
# In hyprland.lua (hyprland.start handler)
hl.exec_cmd("hyprpaper")
hl.exec_cmd(home .. "/.config/hypr/scripts/wallpaper_restore.sh")
```

### Wallpaper Scripts
Both wallpaper change scripts include persistence:
- `wallpaper_cron.sh` - Saves state on manual changes
- `wallpaper_rotate.sh` - Saves state on automatic changes

## Notes

### Rotation System
- The "wallpaper failed (not preloaded)" warning is normal and does not affect function
- Wallpapers change with the `hyprctl hyprpaper wallpaper` command
- The service restarts if it crashes
- Notifications need QuickShell to be running

### Persistence System
- Works with both manual and automatic wallpaper changes
- State is saved at once when wallpapers change
- Restoration runs early in the Hyprland startup process
- Handles missing or invalid state without user action

## Workflow

1. **System starts** → Wallpaper restore script runs → Last wallpaper is restored
2. **Rotation service starts** → Changes wallpaper every 30 minutes
3. **Each change** → Wallpaper path is saved for persistence
4. **Manual changes** → Also saved for persistence
5. **System restart** → Process repeats from step 1

On each boot, the last wallpaper is restored. Rotation then keeps the desktop wallpapers current.
