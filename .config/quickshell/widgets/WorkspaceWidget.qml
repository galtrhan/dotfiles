import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root
    spacing: Theme.spacing
    Layout.fillHeight: true

    readonly property int maxWorkspaceId: 10

    function focusWorkspace(id) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })");
    }

    Repeater {
        model: root.maxWorkspaceId

        delegate: Item {
            required property int index
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            Layout.preferredWidth: wsLabel.implicitWidth
            width: wsLabel.implicitWidth
            height: Theme.barHeight
            visible: isVisible

            readonly property int wsId: index + 1
            readonly property var ws: Hyprland.workspaces.values.find(function (w) {
                return w.id === wsId;
            })
            readonly property bool isVisible: wsId <= 4 || ws !== undefined
            readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
            readonly property bool isUrgent: ws ? ws.urgent : false
            property bool hovered: false

            Text {
                id: wsLabel
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.barOpticalOffset
                text: isActive ? "" : ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.iconSize
                color: {
                    if (hovered)
                        return Theme.hoverColor;
                    if (isActive)
                        return Theme.workspaceActive;
                    if (isUrgent)
                        return Theme.workspaceUrgent;
                    return Theme.workspaceDefault;
                }
                font.weight: isActive ? 700 : 400

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.hoverTransitionDuration
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.focusWorkspace(wsId)
                onEntered: parent.hovered = true
                onExited: parent.hovered = false
                onWheel: function (wheel) {
                    Hyprland.dispatch(wheel.angleDelta.y > 0 ? 'hl.dsp.focus({ workspace = "e-1" })' : 'hl.dsp.focus({ workspace = "e+1" })');
                }
            }
        }
    }
}
