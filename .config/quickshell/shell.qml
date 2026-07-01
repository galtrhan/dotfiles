//@ pragma UseQApplication
import Quickshell
import QtQuick
import "bar"
import "launcher"
import "notifications"

Scope {
    LauncherIpc {}
    NotificationPopup {}
    NotificationCenter {}

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            margins {
                top: Theme.margin
                left: Theme.margin
                right: Theme.margin
            }
            implicitHeight: Theme.barHeight
            color: "transparent"
            aboveWindows: true
            exclusiveZone: Theme.barHeight

            Rectangle {
                anchors.fill: parent
                radius: Theme.borderRadius
                color: Theme.bg
                border.width: 0
            }

            Bar {
                anchors.fill: parent
            }
        }
    }
}
