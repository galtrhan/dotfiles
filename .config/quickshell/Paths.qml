pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string configDir: home + "/.config"
    readonly property string localBin: home + "/.local/bin"
    readonly property string hyprScripts: configDir + "/hypr/scripts"
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string screenCapturePid: runtimeDir + "/screen_capture.pid"
    readonly property string lnd: localBin + "/lnd"
}
