pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14
    readonly property int launcherFontSize: 16
    readonly property int launcherAppWidth: 560
    readonly property int launcherMenuWidth: 240
    readonly property int launcherPickerWidth: 480
    readonly property int launcherInputPaddingV: 15
    readonly property int launcherInputPaddingH: 15

    readonly property color bg: Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0.75)
    readonly property color launcherHighlight: "#2185a6"
    readonly property color launcherInputBg: Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0.9)
    readonly property color launcherInputBorder: Qt.rgba(200 / 255, 200 / 255, 200 / 255, .5)
    readonly property color launcherTextActive: "#ffffff"
    readonly property color launcherTextDefault: Qt.rgba(1, 1, 1, 0.85)
    readonly property color launcherTextInactive: Qt.rgba(1, 1, 1, 0.5)
    readonly property color fg: "#cba6f7"
    readonly property color fgMuted: "#6e6a86"
    readonly property color fgBright: "#e5d9f5"

    readonly property color workspaceActive: "#33ccff"
    readonly property color workspaceDefault: "#6e6a86"
    readonly property color workspaceUrgent: "#ff0000"

    readonly property color batteryGood: "#39ff14"
    readonly property color batteryWarning: "orange"
    readonly property color batteryCritical: "#f53c3c"

    readonly property color micMuted: "#ff5555"
    readonly property color recording: "#ff4444"
    readonly property color ipColor: "teal"
    readonly property color tempCool: "#89b4fa"
    readonly property color tempWarning: "orange"
    readonly property color tempCritical: "#f53c3c"
    readonly property color powerColor: "white"
    readonly property color powerHover: "orange"
    readonly property color idleActive: "#39ff14"

    readonly property color tooltipBg: "#1e1e2e"
    readonly property color tooltipBorder: "#11111b"
    readonly property color tooltipFg: "#40e0d0"

    readonly property int borderRadius: 8
    readonly property int barPadding: 8
    readonly property int spacing: 8
    readonly property int margin: 4
    readonly property int barHeight: 28

    readonly property color notifBg: Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0.92)
    readonly property color notifBorder: "#323232"
    readonly property color notifFg: "#ffffff"
    readonly property color notifFgMuted: "#aaaaaa"
    readonly property color notifAccent: fg
    readonly property color notifUrgencyLow: fgMuted
    readonly property color notifUrgencyNormal: fgBright
    readonly property color notifUrgencyCritical: batteryCritical
    readonly property color notifProgress: workspaceActive

    readonly property int notifWidth: 360
    readonly property int notifMaxPopups: 5
    readonly property int notifMaxHistory: 50
    readonly property int notifTimeoutLow: 10000
    readonly property int notifTimeoutNormal: 10000
    readonly property int notifTimeoutCritical: 0
}
