import Quickshell.Io
import QtQuick
import ".."
import "../components"

BarLabel {
    id: root

    property int brightnessPercent: -1

    icon: {
        if (brightnessPercent < 0)
            return "";
        if (brightnessPercent < 34)
            return "";
        if (brightnessPercent < 67)
            return "";
        return "";
    }
    visible: brightnessPercent >= 0
    tooltipText: brightnessPercent >= 0 ? "Scroll: brightness · " + brightnessPercent + "%" : ""
    hoverEnabled: true

    readonly property int step: 10

    ScriptPoll {
        command: ["brightnessctl", "info"]
        interval: 2000
        onOutput: function (text) {
            var match = text.match(/Current brightness: (\d+)/);
            var maxMatch = text.match(/Max brightness: (\d+)/);
            if (match && maxMatch) {
                var current = parseInt(match[1]);
                var max = parseInt(maxMatch[1]);
                root.brightnessPercent = Math.round((current / max) * 100);
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onWheel: function (wheel) {
            if (wheel.angleDelta.y > 0)
                root.brightnessPercent = Math.min(100, root.brightnessPercent + root.step);
            else
                root.brightnessPercent = Math.max(0, root.brightnessPercent - root.step);

            brightnessProc.command = wheel.angleDelta.y > 0
                ? [Paths.hyprScripts + "/brightness.sh", "up"]
                : [Paths.hyprScripts + "/brightness.sh", "down"];
            brightnessProc.running = true;
        }
    }

    Process {
        id: brightnessProc
        running: false
    }
}
