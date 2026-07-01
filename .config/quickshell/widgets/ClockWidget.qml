import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import "../components"
import "../lib/ClockLogic.js" as ClockLogic

BarLabel {
    id: root

    property bool verboseFormat: false
    property string namedaysTooltip: ""

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    FileView {
        id: verboseState
        path: Quickshell.statePath("clock-verbose")
        onLoadedChanged: {
            if (loaded)
                root.verboseFormat = text() === "1";
        }
    }

    text: ClockLogic.formatDateTime(clock.date, verboseFormat)
    tooltipText: namedaysTooltip

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.verboseFormat = !root.verboseFormat;
            verboseState.setText(root.verboseFormat ? "1" : "");
        }
    }

    ScriptPoll {
        command: [Paths.lnd]
        interval: 600000
        onOutput: function (text) {
            root.namedaysTooltip = text.trim();
        }
    }
}
