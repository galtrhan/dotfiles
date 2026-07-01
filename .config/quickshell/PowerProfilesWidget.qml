import Quickshell.Services.UPower
import QtQuick

Text {
  text: {
    var icons = {
      "PowerSaver": "",
      "Balanced": "",
      "Performance": ""
    };
    var name = PowerProfile.toString(PowerProfiles.profile);
    return icons[name] || "";
  }
  color: Theme.fgBright
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontSize
  visible: PowerProfiles.profile !== PowerProfile.PowerSaver
           || PowerProfiles.hasPerformanceProfile

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      var profiles = [PowerProfile.PowerSaver, PowerProfile.Balanced];
      if (PowerProfiles.hasPerformanceProfile)
        profiles.push(PowerProfile.Performance);
      var idx = profiles.indexOf(PowerProfiles.profile);
      if (idx < 0) return;
      PowerProfiles.profile = profiles[(idx + 1) % profiles.length];
    }
  }
}
