# Complete Wallpaper System for Hyprland

A comprehensive wallpaper management system that provides automatic rotation, persistence across restarts, and full control over your desktop wallpapers using hyprpaper.

## 🎯 System Overview

This system combines two powerful features:
- **Automatic Rotation**: Changes wallpapers at specified intervals
- **Persistence**: Remembers and restores your wallpaper across restarts

## ✨ Features

### Rotation System
- ✅ **Automatic Rotation**: Changes wallpapers every 30 minutes by default
- ✅ **Random Selection**: Picks random wallpapers from your collection
- ✅ **Desktop Notifications**: Shows notifications when wallpapers change
- ✅ **Easy Control**: Simple commands to start, stop, and manage
- ✅ **Boot Integration**: Automatically starts when you log in
- ✅ **Immediate Changes**: Change wallpaper on demand with `SUPER + SHIFT + B`

### Persistence System
- ✅ **Automatic Tracking**: Saves wallpaper state whenever it changes
- ✅ **Startup Restoration**: Automatically restores wallpaper on Hyprland startup
- ✅ **Manual Control**: Save and restore wallpapers on demand
- ✅ **Fallback System**: Sets random wallpaper if saved state is invalid
- ✅ **State Management**: Easy commands to manage wallpaper persistence

## 📁 Files

### Core Scripts
- `wallpaper_rotate.sh` - Main rotation script (runs continuously)
- `wallpaper_cron.sh` - Single wallpaper change script (for cron jobs)
- `wallpaper_control.sh` - Control script for managing the service
- `wallpaper_persistence.sh` - Core persistence management script
- `wallpaper_restore.sh` - Startup restoration script

### Configuration
- `wallpaper-rotate.service` - Systemd user service file
- `wallpaper_state` - State file (created automatically)
- `hyprland.conf` - Updated with startup restoration

## 🚀 Quick Start

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

## 🎮 Control Commands

### Wallpaper Control Script
| Command | Description |
|---------|-------------|
| `start` | Start wallpaper rotation |
| `stop` | Stop wallpaper rotation |
| `restart` | Restart the service |
| `status` | Show service status |
| `change` | Change wallpaper immediately |
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
| `set <path>` | Set specific wallpaper with persistence |
| `status` | Show current state |
| `clear` | Clear saved state |
| `help` | Show help message |

## ⚙️ Configuration

### Wallpaper Directory
Wallpapers are loaded from: `~/Pictures/Wallpapers/`

### Supported Formats
- PNG, JPG, JPEG, BMP, WebP

### Rotation Interval
Default: 30 minutes
To change, edit the service file:
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
- **Action**: Change wallpaper immediately
- **Location**: Added to `~/.config/hypr/configs/keybinds.conf`

## 🔄 How Persistence Works

### Automatic Persistence
1. **Every wallpaper change** automatically saves the new wallpaper path
2. **On Hyprland startup**, the restore script runs after hyprpaper starts
3. **If saved wallpaper exists**, it's restored; otherwise, a random one is set

### State File
- **Location**: `~/.config/hypr/wallpaper_state`
- **Content**: Full path to the last active wallpaper
- **Auto-created**: When wallpapers change
- **Auto-cleaned**: If saved wallpaper no longer exists

## 📖 Manual Usage

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

## 🔧 Systemd Service Management

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

## 🛠️ Troubleshooting

### Service Not Found
```bash
# Reload systemd daemon
systemctl --user daemon-reload

# Check if service file exists
ls -la ~/.config/systemd/user/wallpaper-rotate.service
```

### Wallpaper Not Changing
- Ensure hyprland is running
- Check if hyprctl is available
- Verify wallpaper directory exists and contains images

### Permission Issues
```bash
# Make scripts executable
chmod +x ~/.config/hypr/scripts/*.sh
```

### Wallpaper Not Restoring
1. Check if state file exists: `ls ~/.config/hypr/wallpaper_state`
2. Check if saved wallpaper exists: `cat ~/.config/hypr/wallpaper_state`
3. Test manual restore: `~/.config/hypr/scripts/wallpaper_persistence.sh restore`

### Invalid State File
If the saved wallpaper no longer exists:
- The system will automatically clear the invalid state
- A random wallpaper will be set as fallback
- The new wallpaper will be saved as the new state

### Manual Reset
To reset the persistence system:
```bash
# Clear saved state
~/.config/hypr/scripts/wallpaper_persistence.sh clear

# Set a new wallpaper (will be saved automatically)
~/.config/hypr/scripts/wallpaper_control.sh change
```

## 🎯 Integration

### Hyprland Configuration
The system is integrated into your Hyprland startup sequence:

```bash
# In hyprland.conf
exec-once = hyprpaper
exec-once = ~/.config/hypr/scripts/wallpaper_restore.sh    # Restore wallpaper on startup
```

### Wallpaper Scripts
Both wallpaper change scripts now include persistence:
- `wallpaper_cron.sh` - Saves state on manual changes
- `wallpaper_rotate.sh` - Saves state on automatic changes

## 📝 Notes

### Rotation System
- The "wallpaper failed (not preloaded)" warning is normal and doesn't affect functionality
- Wallpapers are changed using `hyprctl hyprpaper wallpaper` command
- The service automatically restarts if it crashes
- Notifications require QuickShell to be running

### Persistence System
- The system works with both manual and automatic wallpaper changes
- State is saved immediately when wallpapers change
- Restoration happens early in the Hyprland startup process
- The system is designed to be robust and handle edge cases gracefully

## 🎉 Benefits

### Rotation Benefits
- **Dynamic Desktop**: Never get bored with the same wallpaper
- **Automatic Management**: No manual intervention required
- **Flexible Timing**: Customizable rotation intervals
- **Easy Control**: Simple commands and keyboard shortcuts

### Persistence Benefits
- **No Lost Wallpapers**: Your current wallpaper persists across restarts
- **Seamless Experience**: Works automatically without user intervention
- **Fallback Safety**: Always has a wallpaper, even if state is invalid
- **Manual Control**: Can save/restore wallpapers on demand
- **Memory Efficient**: Only saves the current wallpaper path

## 🔄 Complete Workflow

1. **System starts** → Wallpaper restore script runs → Last wallpaper is restored
2. **Rotation service starts** → Changes wallpaper every 30 minutes
3. **Each change** → Wallpaper is saved for persistence
4. **Manual changes** → Also saved for persistence
5. **System restart** → Process repeats from step 1

This creates a seamless, persistent wallpaper experience that remembers your preferences and keeps your desktop fresh with automatic rotation! 🖼️✨
