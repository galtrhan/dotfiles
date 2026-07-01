import QtQuick
import ".."
import "../components"

Item {
    id: root

    property bool recording: false

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    ScriptPoll {
        command: ["sh", "-c", "pid=$(cat '" + Paths.screenCapturePid + "' 2>/dev/null) && kill -0 \"$pid\" 2>/dev/null && echo recording || echo idle"]
        interval: 1000
        onOutput: function (text) {
            root.recording = text.trim() === "recording";
        }
    }

    BarLabel {
        id: label
        text: "● REC"
        labelColor: Theme.recording
        labelWeight: Font.Bold
        visible: root.recording
    }
}
