import Quickshell.Wayland._IdleInhibitor
import QtQuick

Text {
  text: IdleInhibitor.enabled ? " " : " "
  color: IdleInhibitor.enabled ? Theme.idleActive : Theme.fgMuted
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontSize

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: IdleInhibitor.enabled = !IdleInhibitor.enabled
  }
}
