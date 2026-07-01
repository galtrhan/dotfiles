import Quickshell.Io
import QtQuick

Text {
  text: "⏻ "
  color: Theme.powerColor
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontSize

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      powerProc.command = mouse.button === Qt.RightButton
          ? ["/home/galtrhan/.config/hypr/scripts/power.sh", "lock"]
          : ["/home/galtrhan/.config/hypr/scripts/power.sh"];
      powerProc.running = true;
    }
    onEntered: parent.color = Theme.powerHover
    onExited: parent.color = Theme.powerColor
  }

  Process {
    id: powerProc
    running: false
  }
}
