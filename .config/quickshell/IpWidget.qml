import Quickshell.Io
import QtQuick

Text {
  text: BarState.ipText !== "" ? "[" + BarState.ipText + "]" : ""
  color: Theme.ipColor
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontSize
  visible: BarState.ipText !== ""

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: BarState.copyIpRequested = !BarState.copyIpRequested
  }
}
