pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12

    readonly property color bg: Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0.75)
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
    readonly property color tooltipFg: "#ffd700"

    readonly property int borderRadius: 8
    readonly property int barPadding: 8
    readonly property int spacing: 8
    readonly property int margin: 4
    readonly property int barHeight: 28
}
