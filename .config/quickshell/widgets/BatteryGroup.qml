import Quickshell.Services.UPower
import QtQuick
import ".."
import "../components"
import "."

Row {
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

    Row {
        visible: root.expanded
        spacing: Theme.spacing

        Separator {}
        IdleInhibitorWidget {}
        Separator {}
        PowerProfilesWidget {}
        Separator {}
        BacklightWidget {}
        Separator {}

        Repeater {
            model: root.extraBatteryPaths

            BarLabel {
                required property string modelData
                readonly property var device: root.findBattery(modelData)
                visible: device !== null
                text: device ? root.formatBattery(device) : ""
                labelColor: device ? root.batteryColor(device) : Theme.fgBright
            }
        }
    }
}
