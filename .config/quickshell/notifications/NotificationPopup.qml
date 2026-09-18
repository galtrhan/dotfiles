import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

Scope {
    id: root

    property int _hyprlandWindowsRev: 0

    function isZenOnActiveWorkspace(): bool {
        root._hyprlandWindowsRev;

        const focused = Hyprland.focusedWorkspace;
        if (!focused)
            return false;

        const values = Hyprland.toplevels?.values;
        if (!values)
            return false;

        const focusedId = focused.id;

        for (let i = 0; i < values.length; i++) {
            const toplevel = values[i];
            const ipc = toplevel?.lastIpcObject;
            if (!ipc || ipc.class !== "zen")
                continue;
            if (ipc.hidden === true || ipc.mapped === false)
                continue;

            const wsId = toplevel.workspace?.id ?? ipc.workspace?.id;
            if (wsId === focusedId)
                return true;
        }
        return false;
    }

    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            root._hyprlandWindowsRev += 1;
        }

        function onRawEvent(event) {
            switch (event.name) {
            case "openwindow":
            case "closewindow":
            case "activewindow":
            case "movewindow":
            case "workspace":
                root._hyprlandWindowsRev += 1;
                break;
            }
        }
    }

    Timer {
        running: true
        repeat: false
        interval: 0
        onTriggered: {
            Hyprland.refreshToplevels();
            root._hyprlandWindowsRev += 1;
        }
    }

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

            readonly property bool topCenter: root.isZenOnActiveWorkspace()

            anchors {
                top: true
                right: !topCenter
            }

            margins {
                top: Theme.barHeight + Theme.margin * 2 + 15
                right: topCenter ? 0 : 15
                left: topCenter
                      ? Math.max(0, Math.round((modelData.width - implicitWidth) / 2))
                      : 0
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
