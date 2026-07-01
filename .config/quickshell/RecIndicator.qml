import QtQuick

Text {
  text: BarState.recText
  color: BarState.recClass === "recording" ? Theme.recording : "transparent"
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontSize
  font.weight: Font.Bold
  visible: BarState.recClass === "recording"
}
