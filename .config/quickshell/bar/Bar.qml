import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../widgets"

Item {
    anchors.fill: parent
    clip: true

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.barPadding
        anchors.rightMargin: Theme.barPadding
        spacing: Theme.spacing

        WorkspaceWidget {
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            Layout.alignment: Qt.AlignVCenter
        }
        CdemuWidget {
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            Layout.alignment: Qt.AlignVCenter
        }
        SystemTrayWidget {
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            Layout.fillWidth: true
        }

        ClockWidget {
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            variant: "line"
            Layout.alignment: Qt.AlignVCenter
        }
        IpWidget {
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            Layout.fillWidth: true
        }

        RecIndicator {
            Layout.alignment: Qt.AlignVCenter
        }
        TempsWidget {
            Layout.alignment: Qt.AlignVCenter
        }
        AudioWidget {
            Layout.alignment: Qt.AlignVCenter
        }
        BatteryGroup {
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            variant: "line"
            Layout.alignment: Qt.AlignVCenter
        }
        NotificationWidget {
            Layout.alignment: Qt.AlignVCenter
        }
        PowerWidget {
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
