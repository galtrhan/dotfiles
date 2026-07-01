import Quickshell.Io
import QtQuick
import ".."
import "../components"

BarLabel {
    id: root

    property int brightnessPercent: -1

    text: {
        var icons = ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""];
        if (brightnessPercent < 0)
            return "";
        var idx = Math.min(Math.floor(brightnessPercent / 7), icons.length - 1);
        return icons[idx];
    }
    visible: brightnessPercent >= 0
    tooltipText: brightnessPercent >= 0 ? "Brightness " + brightnessPercent + "%" : ""

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
        onWheel: function (wheel) {
            brightnessProc.command = wheel.angleDelta.y > 0
                ? [Paths.hyprScripts + "/brightness.sh", "--inc"]
                : [Paths.hyprScripts + "/brightness.sh", "--dec"];
            brightnessProc.running = true;
        }
    }

    Process {
        id: brightnessProc
        running: false
    }
}
