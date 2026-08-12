pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string dockerHost: Quickshell.env("XDG_RUNTIME_DIR") !== ""
        ? "unix://" + Quickshell.env("XDG_RUNTIME_DIR") + "/docker.sock"
        : ""

    property var containers: []
    readonly property bool active: root.containers.length > 0

    function psCommand() {
        var base = "docker ps --format '{{.Names}}' 2>/dev/null";
        return root.dockerHost !== "" ? "DOCKER_HOST='" + root.dockerHost + "' " + base : base;
    }

    function refresh() {
        psProc.command = ["sh", "-c", root.psCommand()];
        psProc.running = true;
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    Process {
        id: psProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text.trim();
                root.containers = text.length > 0 ? text.split("\n") : [];
            }
        }
    }
}
