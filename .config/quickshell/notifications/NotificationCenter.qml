import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            readonly property int panelPadding: 24
            readonly property int chromeHeight: headerRow.implicitHeight + 1 + centerColumn.spacing + panelPadding
            readonly property int maxBodyHeight: Math.max(80, modelData.height * 0.75 - chromeHeight)
            readonly property int bodyHeight: NotificationService.history.length === 0
                ? 80
                : Math.min(historyList.implicitHeight, maxBodyHeight)

            visible: NotificationService.centerOpen
            focusable: true
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "quickshell-notification-center"

            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                right: true
            }

            margins {
                top: Theme.barHeight + Theme.margin * 2 + 8
                right: Theme.margin
            }

            implicitWidth: Theme.notifWidth + panelPadding
            implicitHeight: chromeHeight + bodyHeight

            Rectangle {
                id: centerPanel
                anchors.fill: parent
                radius: Theme.borderRadius
                color: Theme.notifBg
                border.color: Theme.notifBorder
                border.width: 1
                clip: true

                ColumnLayout {
                    id: centerColumn
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        id: headerRow
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Notifications"
                            color: Theme.notifFg
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.preferredWidth: dndLabel.width + 16
                            Layout.preferredHeight: 24
                            radius: 4
                            color: dndHover.containsMouse || NotificationService.doNotDisturb
                                   ? Theme.notifBorder : Qt.rgba(255, 255, 255, 0.06)

                            Text {
                                id: dndLabel
                                anchors.centerIn: parent
                                text: NotificationService.doNotDisturb ? "DND on" : "DND off"
                                color: NotificationService.doNotDisturb ? Theme.notifUrgencyCritical : Theme.notifFgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: dndHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.toggleDnd()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: clearLabel.width + 16
                            Layout.preferredHeight: 24
                            radius: 4
                            color: clearHover.containsMouse ? Theme.notifBorder : Qt.rgba(255, 255, 255, 0.06)
                            visible: NotificationService.history.length > 0

                            Text {
                                id: clearLabel
                                anchors.centerIn: parent
                                text: "Clear all"
                                color: Theme.notifFgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: clearHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.dismissAll()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            radius: 12
                            color: closeCenterHover.containsMouse ? Theme.notifBorder : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: Theme.notifFgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: closeCenterHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.centerOpen = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.notifBorder
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: bodyHeight
                        visible: NotificationService.history.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: NotificationService.doNotDisturb
                                  ? "Do not disturb is on"
                                  : "No notifications"
                            color: Theme.notifFgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: bodyHeight
                        visible: NotificationService.history.length > 0
                        clip: true

                        ColumnLayout {
                            id: historyList
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: ScriptModel {
                                    values: NotificationService.history
                                    objectProp: "seqId"
                                }

                                delegate: Item {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitWidth: card.implicitWidth
                                    implicitHeight: card.implicitHeight

                                    NotificationCard {
                                        id: card
                                        width: parent.width
                                        modelData: parent.modelData
                                        showTimer: false
                                        compact: true
                                        fullDismiss: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                propagateComposedEvents: true
                onClicked: function (mouse) {
                    if (mouse.button !== Qt.LeftButton)
                        return;
                    var pos = mapToItem(centerPanel, mouse.x, mouse.y);
                    if (pos.x < 0 || pos.y < 0 || pos.x > centerPanel.width || pos.y > centerPanel.height)
                        NotificationService.centerOpen = false;
                }
            }
        }
    }
}
