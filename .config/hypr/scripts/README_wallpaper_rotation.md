# Wallpaper Rotation System for Hyprland

This system automatically rotates your wallpapers at specified intervals using hyprpaper and systemd.

## Features

- ✅ **Automatic Rotation**: Changes wallpapers every 30 minutes by default
- ✅ **Random Selection**: Picks random wallpapers from your collection
- ✅ **Desktop Notifications**: Shows notifications when wallpapers change
- ✅ **Easy Control**: Simple commands to start, stop, and manage
- ✅ **Boot Integration**: Automatically starts when you log in
- ✅ **Immediate Changes**: Change wallpaper on demand

## Files

- `wallpaper_rotate.sh` - Main rotation script (runs continuously)
- `wallpaper_cron.sh` - Single wallpaper change script (for cron jobs)
- `wallpaper_control.sh` - Control script for managing the service
- `wallpaper-rotate.service` - Systemd user service file

## Quick Start

### 1. Check Status
```bash
~/.config/hypr/scripts/wallpaper_control.sh status
```

### 2. Start Rotation
```bash
~/.config/hypr/scripts/wallpaper_control.sh start
```

### 3. Stop Rotation
```bash
~/.config/hypr/scripts/wallpaper_control.sh stop
```

### 4. Change Wallpaper Now
```bash
~/.config/hypr/scripts/wallpaper_control.sh change
```

## Control Commands

| Command | Description |
|---------|-------------|
| `start` | Start wallpaper rotation |
| `stop` | Stop wallpaper rotation |
| `restart` | Restart the service |
| `status` | Show service status |
| `change` | Change wallpaper immediately |
| `enable` | Enable auto-start on boot |
| `disable` | Disable auto-start on boot |
| `help` | Show help message |

## Configuration

### Wallpaper Directory
Wallpapers are loaded from: `~/Pictures/Wallpapers/`

### Supported Formats
- PNG, JPG, JPEG, BMP, WebP

### Rotation Interval
Default: 30 minutes
To change, edit the service file or modify the script arguments.

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

## Troubleshooting

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

## Notes

- The "wallpaper failed (not preloaded)" warning is normal and doesn't affect functionality
- Wallpapers are changed using `hyprctl hyprpaper wallpaper` command
- The service automatically restarts if it crashes
- Notifications require dunst to be running

## Customization

To modify the rotation interval, edit the service file:
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
