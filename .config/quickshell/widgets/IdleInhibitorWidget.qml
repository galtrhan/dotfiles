import QtQuick
import ".."
import "../components"

BarLabel {
    icon: IdleInhibitorService.enabled ? "" : ""
    labelColor: IdleInhibitorService.enabled ? Theme.idleActive : Theme.fgMuted
    tooltipText: IdleInhibitorService.enabled ? "Idle inhibitor on" : "Idle inhibitor off"
    hoverEnabled: true

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: IdleInhibitorService.toggle()
    }
}
