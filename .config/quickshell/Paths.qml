pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string configDir: home + "/.config"
    readonly property string localBin: home + "/.local/bin"
    readonly property string hyprScripts: configDir + "/hypr/scripts"
    readonly property string qsMenu: hyprScripts + "/qs-menu.sh"
    readonly property string ipWidget: hyprScripts + "/ip_widget.sh"
    readonly property string cursorUsageWidget: hyprScripts + "/cursor_usage_widget.py"
    readonly property string cursorIcon: "file://" + configDir + "/quickshell/icons/cursor.png"
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string screenCapturePid: runtimeDir + "/screen_capture.pid"
    readonly property string lnd: localBin + "/lnd"
    readonly property string soundsDir: configDir + "/quickshell/sounds"
    readonly property string batteryMeltdownSound: soundsDir + "/meltdown.mp3"
}
