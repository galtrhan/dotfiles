import Quickshell.Io
import QtQuick
import ".."
import "../components"

BarLabel {
    id: root

    property string ip: ""

    text: ip !== "" ? "[" + ip + "]" : ""
    labelColor: Theme.ipColor
    visible: ip !== ""
    tooltipText: ip !== "" ? "Click to copy IP" : ""

    ScriptPoll {
        command: ["curl", "-s", "--max-time", "3", "https://api.ipify.org"]
        interval: 30000
        onOutput: function (text) {
            root.ip = text.trim() || "N/A";
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.visible
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
