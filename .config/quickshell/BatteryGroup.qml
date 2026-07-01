import Quickshell.Services.UPower
import QtQuick

Row {
  id: root
  spacing: Theme.spacing
  property bool expanded: false

  readonly property var batteryIcons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

  function percent(device) {
    return Math.round(device.percentage * 100);
  }

  function formatBattery(device) {
    var pct = percent(device);
    var iconIdx = Math.min(Math.floor(pct / 10), 10);
    var icon = batteryIcons[iconIdx];
    if (device.state === UPowerDeviceState.Charging) icon = "";
    else if (device.state === UPowerDeviceState.FullyCharged) icon = "󱘖";
    return icon + " " + pct + "%";
  }

  function batteryColor(device) {
    var pct = percent(device);
    if (device.state === UPowerDeviceState.Charging) return Theme.batteryGood;
    if (device.state === UPowerDeviceState.FullyCharged) return Theme.batteryGood;
    if (pct <= 15) return Theme.batteryCritical;
    if (pct <= 30) return Theme.batteryWarning;
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

  Text {
    visible: UPower.displayDevice.ready
    text: root.formatBattery(UPower.displayDevice)
    color: root.batteryColor(UPower.displayDevice)
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.expanded = !root.expanded
    }
  }

  Row {
    visible: root.expanded
    spacing: Theme.spacing

    SeparatorDot {}
    IdleInhibitorWidget {}
    SeparatorDot {}
    PowerProfilesWidget {}
    SeparatorDot {}
    BacklightWidget {}
    SeparatorDot {}

    Text {
      readonly property var device: root.findBattery("BAT1")
      visible: device !== null
      text: device ? root.formatBattery(device) : ""
      color: device ? root.batteryColor(device) : Theme.fgBright
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSize
    }

    Text {
      readonly property var device: root.findBattery("BAT0")
      visible: device !== null
      text: device ? root.formatBattery(device) : ""
      color: device ? root.batteryColor(device) : Theme.fgBright
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSize
    }
  }
}
