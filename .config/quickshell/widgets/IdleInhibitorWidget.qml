import Quickshell.Wayland._IdleInhibitor
import QtQuick
import ".."
import "../components"

BarLabel {
    text: IdleInhibitor.enabled ? " " : " "
    labelColor: IdleInhibitor.enabled ? Theme.idleActive : Theme.fgMuted
    tooltipText: IdleInhibitor.enabled ? "Idle inhibitor on" : "Idle inhibitor off"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: IdleInhibitor.enabled = !IdleInhibitor.enabled
    }
}
