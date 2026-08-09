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
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        CdemuWidget {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        SystemTrayWidget {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            Layout.fillWidth: true
        }

        ClockWidget {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        IpWidget {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        CursorUsageWidget {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            Layout.fillWidth: true
        }

        RecIndicator {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        TempsWidget {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        AudioWidget {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        BatteryGroup {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        NotificationWidget {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
        PowerWidget {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
