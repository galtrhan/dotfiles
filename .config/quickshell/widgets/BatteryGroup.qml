import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../lib/BatteryLogic.js" as BatteryLogic
import "."

RowLayout {
    id: root
    spacing: Theme.spacing
    Layout.fillHeight: true
    property bool expanded: false
    // Sysfs pack stats: { BAT0: { cycles, fullWh, designWh, health } }
    property var packStats: ({})

    // MD outline batteries — FA solid batteries read too heavy in the bar
    readonly property var batteryIcons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property var extraBatteryPaths: ["BAT1", "BAT0"]

    function percent(device) {
        return Math.round(device.percentage * 100);
    }

    function batteryGlyph(device) {
        if (device.state === UPowerDeviceState.Charging)
            return "󰢟";  // md-battery-charging-outline
        if (device.state === UPowerDeviceState.FullyCharged)
            return batteryIcons[10];  // md-battery (full)
        return batteryIcons[Math.min(Math.floor(percent(device) / 10), 10)];
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

    // Snapshot UPower fields in QML so the tooltip binding tracks live updates.
    function tooltipFor(device) {
        if (!device || !device.ready)
            return "";
        return BatteryLogic.buildTooltip({
            ready: device.ready,
            percentage: device.percentage,
            energy: device.energy,
            energyCapacity: device.energyCapacity,
            changeRate: device.changeRate,
            timeToEmpty: device.timeToEmpty,
            timeToFull: device.timeToFull,
            state: device.state,
            healthPercentage: device.healthPercentage,
            model: device.model,
            nativePath: device.nativePath
        }, root.packStats);
    }

    ScriptPoll {
        // One line per pack: "BAT0 <cycles> <energy_full> <energy_full_design>"
        command: [
            "sh", "-c",
            "for b in /sys/class/power_supply/BAT*; do"
            + " [ -r \"$b/cycle_count\" ] && [ -r \"$b/energy_full\" ] && [ -r \"$b/energy_full_design\" ] || continue;"
            + " printf '%s %s %s %s\\n' \"$(basename \"$b\")\" \"$(cat \"$b/cycle_count\")\""
            + " \"$(cat \"$b/energy_full\")\" \"$(cat \"$b/energy_full_design\")\";"
            + " done"
        ]
        interval: 30000
        onOutput: function (text) {
            root.packStats = BatteryLogic.parsePackStats(text);
        }
    }

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        visible: UPower.displayDevice.ready
        icon: root.batteryGlyph(UPower.displayDevice)
        text: root.percent(UPower.displayDevice) + "%"
        labelColor: root.batteryColor(UPower.displayDevice)
        hoverEnabled: true
        tooltipText: root.tooltipFor(UPower.displayDevice)

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
                icon: device ? root.batteryGlyph(device) : ""
                text: device ? (root.percent(device) + "%") : ""
                labelColor: device ? root.batteryColor(device) : Theme.fgBright
                hoverEnabled: device !== null
                tooltipText: device ? root.tooltipFor(device) : ""
            }
        }
    }
}
