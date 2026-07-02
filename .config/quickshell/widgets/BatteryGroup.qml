import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "."

RowLayout {
    id: root
    spacing: Theme.spacing
    property bool expanded: false

    readonly property var batteryIcons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property var extraBatteryPaths: ["BAT1", "BAT0"]

    function percent(device) {
        return Math.round(device.percentage * 100);
    }

    function formatBattery(device) {
        var pct = percent(device);
        var iconIdx = Math.min(Math.floor(pct / 10), 10);
        var icon = batteryIcons[iconIdx];
        if (device.state === UPowerDeviceState.Charging)
            icon = "";
        else if (device.state === UPowerDeviceState.FullyCharged)
            icon = "󱘖";
        return icon + " " + pct + "%";
    }

    function batteryColor(device) {
        var pct = percent(device);
        if (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged)
            return Theme.batteryGood;
        if (pct <= 15)
            return Theme.batteryCritical;
        if (pct <= 30)
            return Theme.batteryWarning;
        return Theme.fgBright;
    }

    function findBattery(path) {
        for (var i = 0; i < UPower.devices.count; i++) {
            var device = UPower.devices.get(i);
            if (device.nativePath === path)
                return device;
        }
        return null;
    }

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        visible: UPower.displayDevice.ready
        text: root.formatBattery(UPower.displayDevice)
        labelColor: root.batteryColor(UPower.displayDevice)
        tooltipText: "Click to expand battery details"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignVCenter
        visible: root.expanded
        spacing: Theme.spacing

        Separator {
            Layout.alignment: Qt.AlignVCenter
        }
        IdleInhibitorWidget {
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            Layout.alignment: Qt.AlignVCenter
        }
        PowerProfilesWidget {
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            Layout.alignment: Qt.AlignVCenter
        }
        BacklightWidget {
            Layout.alignment: Qt.AlignVCenter
        }
        Separator {
            Layout.alignment: Qt.AlignVCenter
        }

        Repeater {
            model: root.extraBatteryPaths

            BarLabel {
                required property string modelData
                Layout.alignment: Qt.AlignVCenter
                readonly property var device: root.findBattery(modelData)
                visible: device !== null
                text: device ? root.formatBattery(device) : ""
                labelColor: device ? root.batteryColor(device) : Theme.fgBright
            }
        }
    }
}
