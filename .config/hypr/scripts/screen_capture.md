# Screen Capture Script

A Wayland-native video recording tool for Hyprland with intuitive region selection, clipboard integration, and desktop notifications.

## Features

- **Region Selection**: Select recording area interactively with `slurp`
- **State Management**: Track recording state (active/inactive) with PID tracking
- **Audio Capture**: Optional audio recording support
- **Clipboard Integration**: Automatically copies recorded video to clipboard via `wl-copy`
- **Clipboard History**: Text and image clips are stored by `cliphist` (video/mp4 is not)
- **Thumbnail Fallback**: Generates video thumbnail when direct video copy fails
- **Desktop Notifications**: Real-time status updates via QuickShell (via `notify-send`)
- **Graceful Shutdown**: Properly finalizes video file on stop, with timeout handling

## Usage

```bash
~/.config/hypr/scripts/screen_capture.sh <command> [options]
```

### Commands

| Command | Description |
|---------|-------------|
| `start` | Start recording (opens region selector via slurp) |
| `stop` | Stop active recording and copy to clipboard |
| `status` | Show current recording state |
| `help` | Display usage information |

### Options

| Option | Description |
|--------|-------------|
| `-a`, `--audio` | Enable audio capture (default audio sink) |
| `--audio=DEVICE` | Capture audio from a specific PipeWire node |

## Examples

### Basic screen recording

```bash
~/.config/hypr/scripts/screen_capture.sh start
```

1. Click and drag to select recording region
2. Recording starts; a notification confirms the output file path
3. To stop: `~/.config/hypr/scripts/screen_capture.sh stop`

### Screen recording with audio

```bash
~/.config/hypr/scripts/screen_capture.sh start --audio
```

### Recording with mic input

```bash
~/.config/hypr/scripts/screen_capture.sh start --audio=alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source
```

### Check recording status

```bash
~/.config/hypr/scripts/screen_capture.sh status
```

## Audio Source Menu

`screen_capture_menu.sh` provides a QuickShell menu to pick an audio source before recording:

- **None (no audio)** — video only
- **System Audio (output)** — captures application/system sounds
- **Digital Microphone (internal)** — built-in laptop mic
- **Stereo Microphone (external)** — external mic jack

## Hyprland Keybinds

```
# Toggle recording with audio source picker
bind = $mainMod, Print, exec, ~/.config/hypr/scripts/screen_capture_menu.sh

# Stop recording
bind = $mainMod ALT, Print, exec, ~/.config/hypr/scripts/screen_capture.sh stop
```

## Output Location

Videos are saved to: `~/Videos/Capture/YYYY-MM-DD_HH-MM-SS.mp4`

The directory is created automatically on first use.

## Clipboard Handling

The script attempts to copy recorded videos to clipboard in this order:

1. **Direct video copy** (via `wl-copy --type=video/mp4`)
   - Works with paste-as-file functionality in compatible apps
   - Requires `wf-recorder` to finalize the file properly
   
2. **File path as text** (fallback)
   - Copies the file path so you can paste it as text
   
3. **Thumbnail generation** (secondary fallback)
   - Generates a PNG thumbnail from the first frame
   - Attempts to copy thumbnail as image data
   - Requires `ffmpeg`

4. **Plain text notification** (last resort)
   - Notifies with the file path if all clipboard methods fail

### Clipboard History Integration

Hyprland autostart runs `cliphist` watchers for **text** and **image** clipboard types only (configured in `.config/hypr/hyprland.lua`). Screen recordings copied as `video/mp4` are not stored in cliphist; the file is saved under `~/Videos/Capture/` and can be copied to the clipboard for immediate paste, but it will not appear in clipboard history (`Super+Shift+V`).

Text copied from a successful recording (for example the file path fallback) is stored in cliphist like any other text clip.

## Notifications

The script sends desktop notifications for:

- **Start**: Confirms recording with output file path and audio status
- **Stop (Success)**: Shows file location and clipboard copy method used
  - Includes a thumbnail preview image (if `ffmpeg` is available)
- **Stop (Error)**: Alerts if recording failed or file not found
- **Status**: Shows active recording PID or confirms no recording active
- **Requirements**: Alerts if required tools are missing

Notification styling (colors, timeouts, position) is configured in `.config/quickshell/`.

## Requirements

### Required

- `wf-recorder` — Wayland screen recorder
- `slurp` — Region selection tool
- `notify-send` — Desktop notifications (usually provided by `libnotify`)

### Recommended

- `wl-copy`, `wl-paste` (from `wl-clipboard`) — Clipboard integration
- `ffmpeg` — Thumbnail generation for notifications and clipboard fallback
- `cliphist` — Clipboard history management

### Optional

- Hyprland — Tested on Wayland; should work on other Wayland compositors

## State Files

The script maintains runtime state in `$XDG_RUNTIME_DIR` (or `/tmp`):

- `screen_capture.pid` — PID of active recording process
- `screen_capture.out` — Path to output video file

These are cleaned up automatically on successful stop. Manual cleanup (if needed):
```bash
rm -f "${XDG_RUNTIME_DIR:-/tmp}/screen_capture.{pid,out}"
```

## Troubleshooting

### Recording won't start

**Missing tools:**
```bash
# Check requirements
which wf-recorder slurp notify-send
```

**Installation (Arch Linux):**
```bash
pacman -S wf-recorder slurp libnotify wl-clipboard ffmpeg
```

### Clipboard copy fails

- Ensure `wl-copy` is installed: `which wl-copy`
- Check that your compositor is running in Wayland mode
- Verify you have write permissions to `XDG_RUNTIME_DIR`

### Recording stops unexpectedly

- Check available disk space: `df -h ~/Videos/`
- Review system logs for wf-recorder errors

## Performance Notes

- Video encoding happens in real-time; performance depends on system resources
- For smoother playback on slower systems, consider recording smaller regions
- Audio capture adds minimal overhead

## See Also

- `screenshot.sh` — Static screenshot utility
- `screenshot.py` — Python implementation with more options
- Hyprland documentation: https://wiki.hyprland.org/
