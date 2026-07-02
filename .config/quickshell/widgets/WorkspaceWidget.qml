import Quickshell
import Quickshell.Hyprland
import QtQuick
import ".."

Row {
    id: root
    spacing: Theme.spacing

    readonly property int maxWorkspaceId: 10

    function focusWorkspace(id) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })");
    }

    Repeater {
        model: root.maxWorkspaceId

        delegate: Text {
            required property int index
            readonly property int wsId: index + 1
            readonly property var ws: Hyprland.workspaces.values.find(function (w) {
                return w.id === wsId;
            })
            readonly property bool isVisible: wsId <= 4 || ws !== undefined
            readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
            readonly property bool isUrgent: ws ? ws.urgent : false

            visible: isVisible
            text: isActive ? "" : ""
            font.family: Theme.fontFamily
            font.pixelSize: 16
            color: {
                if (isActive)
                    return Theme.workspaceActive;
                if (isUrgent)
                    return Theme.workspaceUrgent;
                return Theme.workspaceDefault;
            }
            font.weight: isActive ? 700 : 400

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.focusWorkspace(wsId)
                onWheel: function (wheel) {
                    Hyprland.dispatch(wheel.angleDelta.y > 0 ? 'hl.dsp.focus({ workspace = "e-1" })' : 'hl.dsp.focus({ workspace = "e+1" })');
                }
            }
        }
    }
}
