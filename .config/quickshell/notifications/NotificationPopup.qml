import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

Scope {
    id: root

    IpcHandler {
        target: "notifications"

        function dismiss_all(): void {
            NotificationService.dismissAll();
        }

        function dismiss_popups(): void {
            NotificationService.dismissPopups();
        }

        function dnd_toggle(): void {
            NotificationService.toggleDnd();
        }

        function center_toggle(): void {
            NotificationService.toggleCenter();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            visible: NotificationService.popups.length > 0
            focusable: false
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell-notifications"

            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                right: true
            }

            margins {
                top: Theme.barHeight + Theme.margin * 2 + 15
                right: 15
            }

            implicitWidth: Theme.notifWidth + 20
            implicitHeight: notifColumn.implicitHeight

            ColumnLayout {
                id: notifColumn
                width: Theme.notifWidth
                spacing: 8

                Repeater {
                    model: ScriptModel {
                        values: NotificationService.popups
                        objectProp: "seqId"
                    }

                    delegate: Item {
                        required property var modelData
                        width: card.implicitWidth
                        height: card.implicitHeight

                        NotificationCard {
                            id: card
                            width: Theme.notifWidth
                            modelData: parent.modelData
                            showTimer: true
                            compact: false
                            opacity: 0

                            Component.onCompleted: entryAnim.start()

                            NumberAnimation on opacity {
                                id: entryAnim
                                from: 0
                                to: 1
                                duration: 150
                            }
                        }
                    }
                }
            }
        }
    }
}
