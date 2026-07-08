# Battery Notifications

Low-battery warnings are sent by `battery.sh` on a systemd timer and displayed by QuickShell.

## Thresholds

While discharging, notifications fire once per threshold (state resets when charging starts):

| Level | Type | Delivery |
|-------|------|----------|
| 20% | Warning | Corner popup + notification history |
| 15% | Critical | Corner popup + notification history |
| 10% | Critical | Corner popup + notification history |
| 5% | **Meltdown** | Full-screen overlay (see below) |

Thresholds are configured in [`battery.sh`](battery.sh) (`THRESHOLDS` array).

## Battery Meltdown (5%)

At 5%, `battery.sh` sends a dbus notification with summary `REACTOR CRITICAL`. QuickShell detects this (`NotificationService.isBatteryMeltdown`) and shows a dedicated full-screen overlay instead of the normal corner popup.

**Behavior:**
- Full-screen red flashing overlay on all monitors
- Looping alarm sound (`~/.config/quickshell/sounds/meltdown.mp3` via `ffplay`)
- 60-second suspend countdown (`SUSPENDING IN M:SS`)
- **Click anywhere** to dismiss overlay and alarm; countdown resets
- **Plug in charger** — overlay, sound, and countdown cancel immediately
- **Countdown reaches zero** — `systemctl suspend` is run

Meltdown bypasses Do Not Disturb. The notification is still saved to history.

### Files

| File | Role |
|------|------|
| [`battery.sh`](battery.sh) | Reads sysfs, sends `notify-send` at thresholds |
| [`battery-notify.service`](../../systemd/user/battery-notify.service) | Systemd oneshot unit |
| [`battery-notify.timer`](../../systemd/user/battery-notify.timer) | Runs every minute |
| [`.config/quickshell/BatteryMeltdownService.qml`](../../quickshell/BatteryMeltdownService.qml) | Countdown, sound, suspend trigger |
| [`.config/quickshell/notifications/BatteryMeltdownOverlay.qml`](../../quickshell/notifications/BatteryMeltdownOverlay.qml) | Full-screen UI |
| [`.config/quickshell/NotificationService.qml`](../../quickshell/NotificationService.qml) | Routes `REACTOR CRITICAL` to meltdown |
| `~/.config/quickshell/sounds/meltdown.mp3` | Alarm audio (user-provided, not in repo) |

### Setup

Enable the timer after stowing configs:

```bash
systemctl --user enable --now battery-notify.timer
```

Place alarm audio at `~/.config/quickshell/sounds/meltdown.mp3`. Requires `ffmpeg` (`ffplay`) — installed by `install.sh`.

### Customization

| Setting | File | Property |
|---------|------|----------|
| Suspend countdown (seconds) | `BatteryMeltdownService.qml` | `suspendDelaySec` |
| Alarm file path | `Paths.qml` | `batteryMeltdownSound` |
| Meltdown trigger prefix | `NotificationService.qml` | `isBatteryMeltdown()` (summary starts with `REACTOR`) |
| 5% notification text | `battery.sh` | `REACTOR CRITICAL` branch |

### Testing

Preview the meltdown overlay without draining the battery:

```bash
notify-send -a "Battery" -u critical -h int:value:4 \
  "REACTOR CRITICAL" "POWER CORE AT 4% — IMMEDIATE SHUTDOWN REQUIRED"
```

QuickShell must be running. Use a short `suspendDelaySec` while testing if you do not want to wait a full minute.
