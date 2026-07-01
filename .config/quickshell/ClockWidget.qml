import Quickshell.Io
import QtQuick

Text {
  text: BarState.namedaysText !== ""
        ? BarState.namedaysText
        : Qt.formatDateTime(Services.clock.date, "HH:mm  yyyy.MM.dd")
  color: Theme.fgBright
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontSize

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      namedaysToggleProc.running = true;
      namedaysRefreshProc.running = true;
    }
  }

  Process {
    id: namedaysToggleProc
    command: ["/home/galtrhan/.config/waybar/namedays.sh", "--toggle"]
    running: false
  }

  Process {
    id: namedaysRefreshProc
    command: ["/home/galtrhan/.config/waybar/namedays.sh"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(this.text);
          BarState.namedaysText = data.text;
          BarState.namedaysTooltip = data.tooltip || "";
        } catch (e) {}
      }
    }
  }
}
