import QtQuick
import ".."
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    required property Item anchorItem
    property var items: []
    property bool open: false

    signal itemClicked(string url)
    signal itemRightClicked(int pid)
    signal dismissed()

    readonly property var anchorScreen: anchorItem.QsWindow.window.screen

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            visible: root.open
                     && root.anchorScreen
                     && modelData.name === root.anchorScreen.name
            focusable: false
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell-bar-menu-dismiss"

            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.dismissed()
            }
        }
    }

    PopupWindow {
        id: menuPopup

        visible: root.open && root.items.length > 0
        color: "transparent"

        anchor {
            window: anchorItem.QsWindow.window
            onAnchoring: {
                var pos = anchorItem.QsWindow.contentItem.mapFromItem(
                    anchorItem,
                    anchorItem.width / 2 - menuPopup.implicitWidth / 2,
                    anchorItem.height + 4
                );
                anchor.rect.x = pos.x;
                anchor.rect.y = pos.y;
            }
        }

        implicitWidth: frame.implicitWidth
        implicitHeight: frame.implicitHeight

        WrapperRectangle {
            id: frame
            color: Theme.tooltipBg
            border.color: Theme.tooltipBorder
            margin: 6
            radius: 4

            Column {
                id: column
                spacing: 2

                Repeater {
                    model: root.items

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index

                        implicitWidth: rowText.implicitWidth + Theme.barPadding * 2
                        implicitHeight: rowText.implicitHeight + Theme.barPadding
                        width: implicitWidth
                        height: implicitHeight

                        property bool hovered: false

                        Rectangle {
                            anchors.fill: parent
                            color: row.hovered ? Theme.launcherHighlight : "transparent"
                            radius: 2
                        }

                        Text {
                            id: rowText
                            anchors.centerIn: parent
                            text: row.modelData.label
                            color: row.hovered ? Theme.launcherTextActive : Theme.launcherTextDefault
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function (mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    root.itemRightClicked(row.modelData.pid);
                                    return;
                                }
                                if (row.modelData.url)
                                    root.itemClicked(row.modelData.url);
                            }
                            onEntered: row.hovered = true
                            onExited: row.hovered = false
                        }
                    }
                }
            }
        }
    }
}
