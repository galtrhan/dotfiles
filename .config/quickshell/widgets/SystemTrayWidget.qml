import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    spacing: Theme.spacing
    Layout.fillHeight: true

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayIcon
            required property SystemTrayItem modelData
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Theme.iconSize
            width: Theme.iconSize
            height: Theme.barHeight

            IconImage {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Theme.barOpticalOffset
                width: Theme.iconSize
                height: Theme.iconSize
                source: modelData.icon
            }

            function showMenu() {
                if (!modelData.hasMenu)
                    return;
                var win = QsWindow.window;
                if (!win)
                    return;
                var pos = win.contentItem.mapFromItem(trayIcon, 0, trayIcon.height);
                modelData.display(win, pos.x, pos.y);
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: function (mouse) {
                    if (mouse.button === Qt.RightButton) {
                        trayIcon.showMenu();
                        return;
                    }
                    if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate();
                        return;
                    }
                    if (modelData.onlyMenu)
                        trayIcon.showMenu();
                    else
                        modelData.activate();
                }
                onWheel: function (wheel) {
                    modelData.scroll(wheel.angleDelta.y, Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y));
                }
            }
        }
    }
}
