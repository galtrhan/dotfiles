import Quickshell.Io
import QtQuick

Text {
  text: BarState.tempsText
  color: {
    if (BarState.tempsClass === "cool") return Theme.tempCool;
    if (BarState.tempsClass === "warning") return Theme.tempWarning;
    if (BarState.tempsClass === "critical") return Theme.tempCritical;
    return Theme.fgBright;
  }
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontSize
  visible: BarState.tempsText !== ""

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: tempsNotifyProc.running = true
  }

  Process {
    id: tempsNotifyProc
    command: ["/home/galtrhan/.config/waybar/temps.py", "--notify"]
    running: false
  }
}
