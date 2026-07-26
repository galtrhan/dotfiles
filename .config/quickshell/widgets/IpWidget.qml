import Quickshell.Io
import QtQuick
import ".."
import "../components"

BarLabel {
    id: root

    property string ip: ""
    readonly property bool hasIp: ip !== ""

    text: "󰖟"
    labelColor: hasIp ? "white" : Theme.fgMuted
    tooltipText: hasIp ? ip : "No IP"

    ScriptPoll {
        command: ["curl", "-s", "--max-time", "3", "https://api.ipify.org"]
        interval: 30000
        onOutput: function (text) {
            root.ip = text.trim();
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.hasIp ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.hasIp
        onClicked: {
            copyProc.command = ["sh", "-c", "printf '%s' '" + root.ip.replace(/'/g, "'\\''") + "' | wl-copy && notify-send 'IP address copied!'"];
            copyProc.running = true;
        }
    }

    Process {
        id: copyProc
        running: false
    }
}
