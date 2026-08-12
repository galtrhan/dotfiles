pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var servers: []
    readonly property bool active: root.servers.length > 0

    function refresh() {
        pollProc.command = [Paths.devServers];
        pollProc.running = true;
    }

    function openUrl(url) {
        openProc.command = ["xdg-open", url];
        openProc.running = true;
    }

    function killServer(pid) {
        if (!pid)
            return;
        killProc.command = [Paths.devServers, "kill", String(pid)];
        killProc.running = true;
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    Process {
        id: killProc
        running: false
        onExited: root.refresh()
    }

    Process {
        id: openProc
        running: false
    }

    Process {
        id: pollProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n").filter(function (line) {
                    return line.length > 0;
                });
                var parsed = [];
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("|");
                    parsed.push({
                        label: parts[0] || "?",
                        ports: parts[1] || "",
                        pid: parseInt(parts[2], 10) || 0
                    });
                }
                root.servers = parsed;
            }
        }
    }
}
