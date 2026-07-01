import Quickshell
import QtQuick
import ".."
import "../components"
import "../widgets"

Item {
    anchors.fill: parent
    clip: true

    Row {
        id: leftSection
        spacing: Theme.spacing
        anchors {
            left: parent.left
            leftMargin: Theme.barPadding
            verticalCenter: parent.verticalCenter
        }

        WorkspaceWidget {}
        Separator {}
        SystemTrayWidget {}
    }

    Row {
        id: centerSection
        spacing: Theme.spacing
        anchors.centerIn: parent

        ClockWidget {}
    }

    Row {
        id: rightSection
        spacing: Theme.spacing
        anchors {
            right: parent.right
            rightMargin: Theme.barPadding
            verticalCenter: parent.verticalCenter
        }

        RecIndicator {}
        NotificationWidget {}
        IpWidget {}
        TempsWidget {}
        AudioWidget {}
        BatteryGroup {}
        Separator {
            variant: "line"
        }
        PowerWidget {}
    }
}
