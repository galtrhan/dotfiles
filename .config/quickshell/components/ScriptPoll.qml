import Quickshell.Io
import QtQuick
import ".."

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property var command: []
    property int interval: 5000
    property var onOutput: function (text) {}

    Component.onCompleted: proc.running = true

    Process {
        id: proc
        command: root.command
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.onOutput(this.text)
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        onTriggered: proc.running = true
    }
}
