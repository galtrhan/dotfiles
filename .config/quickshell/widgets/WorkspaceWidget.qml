import Quickshell.Hyprland
import QtQuick
import ".."

Row {
    id: root
    spacing: Theme.spacing

    function workspaceForId(id) {
        for (var i = 0; i < Hyprland.workspaces.count; i++) {
            var ws = Hyprland.workspaces.get(i);
            if (ws.id === id)
                return ws;
        }
        return null;
    }

    function focusWorkspace(id) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })");
    }

    Repeater {
        model: 4

        delegate: Text {
            required property int index
            readonly property int wsId: index + 1
            readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
            readonly property bool isUrgent: {
                var ws = root.workspaceForId(wsId);
                return ws ? ws.urgent : false;
            }

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
