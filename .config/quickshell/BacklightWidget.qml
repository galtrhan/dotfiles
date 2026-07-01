import Quickshell.Io
import QtQuick

Text {
  text: {
    var icons = ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""];
    if (BarState.brightnessPercent < 0) return "";
    var idx = Math.min(Math.floor(BarState.brightnessPercent / 7), icons.length - 1);
    return icons[idx];
  }
  color: Theme.fgBright
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontSize
  visible: BarState.brightnessPercent >= 0

  MouseArea {
    anchors.fill: parent
    onWheel: function(wheel) {
      brightnessProc.command = wheel.angleDelta.y > 0
          ? ["/home/galtrhan/.config/hypr/scripts/brightness.sh", "--inc"]
          : ["/home/galtrhan/.config/hypr/scripts/brightness.sh", "--dec"];
      brightnessProc.running = true;
    }
  }

  Process {
    id: brightnessProc
    running: false
  }
}
