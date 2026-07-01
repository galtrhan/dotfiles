import Quickshell.Io
import QtQuick
import ".."
import "../components"

BarLabel {
    id: root

    text: "⏻ "
    labelColor: powerColor
    tooltipText: "Left: power menu · Right: lock"

    property color powerColor: Theme.powerColor

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (mouse) {
            powerProc.command = mouse.button === Qt.RightButton
                ? [Paths.hyprScripts + "/power.sh", "lock"]
                : [Paths.hyprScripts + "/power.sh"];
            powerProc.running = true;
        }
        onEntered: root.powerColor = Theme.powerHover
        onExited: root.powerColor = Theme.powerColor
    }

    Process {
        id: powerProc
        running: false
    }
}
