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
    property bool showKillButton: false

    signal itemClicked(string url)
    signal itemRightClicked(int pid)
    signal itemKillRequested(var pids)
    signal dismissed()

    readonly property var anchorScreen: anchorItem.QsWindow.window.screen
    readonly property int killGlyphWidth: 18

    function itemPids(data) {
        if (data.pids && data.pids.length > 0)
            return data.pids;
        if (data.pid)
            return [data.pid];
        return [];
    }

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

                        readonly property var pids: root.itemPids(row.modelData)
                        readonly property bool killable: root.showKillButton && row.pids.length > 0

                        implicitWidth: rowText.implicitWidth
                                       + (row.killable ? root.killGlyphWidth + Theme.barPadding : 0)
                                       + Theme.barPadding * 2
                        implicitHeight: Math.max(rowText.implicitHeight, killText.implicitHeight)
                                        + Theme.barPadding
                        width: Math.max(implicitWidth, column.width)
                        height: implicitHeight

                        property bool hovered: false

                        Rectangle {
                            anchors.fill: parent
                            color: row.hovered ? Theme.launcherHighlight : "transparent"
                            radius: 2
                        }

                        Text {
                            id: rowText
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.barPadding
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.label
                            color: row.hovered ? Theme.launcherTextActive : Theme.launcherTextDefault
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Text {
                            id: killText
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.barPadding
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.killable
                            text: ""
                            color: killHover.hovered ? Theme.batteryCritical : Theme.launcherTextInactive
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.hoverTransitionDuration
                                }
                            }

                            HoverHandler {
                                id: killHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.itemKillRequested(row.pids)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: row.killable ? root.killGlyphWidth + Theme.barPadding : 0
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function (mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    if (row.pids.length > 0)
                                        root.itemRightClicked(row.pids[0]);
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
