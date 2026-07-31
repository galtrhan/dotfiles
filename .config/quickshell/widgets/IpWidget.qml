import Quickshell.Io
import QtQuick
import ".."
import "../components"

BarLabel {
    id: root

    property string ip: ""
    property string mac: ""
    property var macHistory: []

    readonly property bool hasIp: ip !== ""
    readonly property bool hasMac: mac !== ""

    icon: ""
    labelColor: hasIp ? "white" : Theme.fgMuted
    tooltipFormat: Text.RichText
    tooltipText: buildTooltipText()

    function dimmedColor(opacity) {
        var c = Qt.color(Theme.tooltipFg);
        return Qt.rgba(c.r, c.g, c.b, opacity);
    }

    function escapeHtml(value) {
        return value.replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;");
    }

    function buildTooltipText() {
        var lines = [];
        lines.push("IP: " + escapeHtml(hasIp ? ip : "unavailable"));

        if (hasMac) {
            lines.push("MAC: " + escapeHtml(mac));

            for (var i = 0; i < macHistory.length && i < 3; i++) {
                var opacity = 1 - (i + 1) * 0.2;
                var color = dimmedColor(opacity);
                lines.push('<font color="' + color + '">' + escapeHtml(macHistory[i]) + "</font>");
            }
        }

        return lines.join("<br>");
    }

    function applyMacStatus(text) {
        try {
            var data = JSON.parse(text.trim());
            root.mac = data.mac || "";
            root.macHistory = Array.isArray(data.history) ? data.history : [];
        } catch (e) {
            root.mac = "";
            root.macHistory = [];
        }
    }

    ScriptPoll {
        command: ["curl", "-s", "--max-time", "3", "https://api.ipify.org"]
        interval: 30000
        onOutput: function (text) {
            root.ip = text.trim();
        }
    }

    ScriptPoll {
        command: [Paths.ipWidget, "status"]
        interval: 10000
        onOutput: function (text) {
            root.applyMacStatus(text);
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.hasIp || root.hasMac ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        enabled: root.hasIp || root.hasMac
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                randomizeProc.running = true;
                return;
            }

            if (!root.hasIp)
                return;

            copyProc.command = ["sh", "-c", "printf '%s' '" + root.ip.replace(/'/g, "'\\''") + "' | wl-copy && notify-send 'IP address copied!'"];
            copyProc.running = true;
        }
    }

    Process {
        id: copyProc
        running: false
    }

    Process {
        id: randomizeProc
        command: [Paths.ipWidget, "randomize"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.applyMacStatus(this.text)
        }
    }
}
