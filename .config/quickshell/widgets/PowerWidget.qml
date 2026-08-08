import Quickshell.Io
import QtQuick
import ".."
import "../components"

BarLabel {
    id: root

    icon: ""
    labelColor: powerColor
    tooltipText: "Left: power menu · Right: lock"

    property color powerColor: Theme.powerColor
    hoverEnabled: true
    hoverColor: Theme.powerHover

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (mouse) {
            powerProc.command = mouse.button === Qt.RightButton
                ? [Paths.hyprScripts + "/power.sh", "lock"]
                : [Paths.hyprScripts + "/power.sh"];
            powerProc.running = true;
        }
    }

    Process {
        id: powerProc
        running: false
    }
}
