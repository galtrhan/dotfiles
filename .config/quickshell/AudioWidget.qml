import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Row {
  id: root
  spacing: Theme.spacing

  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property PwNode source: Pipewire.defaultAudioSource

  PwObjectTracker {
    objects: [root.sink, root.source]
  }

  function volumePercent(node) {
    if (!node?.audio)
      return -1;
    var vol = node.audio.volume;
    if (vol === undefined || isNaN(vol))
      return -1;
    return Math.round(vol * 100);
  }

  function volumeIcon(vol) {
    if (vol <= 0) return "󰖁";
    if (vol < 33) return "";
    if (vol < 66) return "";
    return "󰕾";
  }

  function formatOutput() {
    var pct = volumePercent(sink);
    if (pct < 0) return "";
    var icon = sink.audio.muted ? "󰖁" : volumeIcon(pct);
    return icon + " " + pct + "%";
  }

  function formatMic() {
    var pct = volumePercent(source);
    if (pct < 0) return "";
    var icon = source.audio.muted ? "" : "";
    return icon + " " + pct + "%";
  }

  Text {
    text: formatOutput()
    color: root.sink?.audio?.muted ? Theme.micMuted : Theme.fgBright
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          pavuProc.command = ["pavucontrol", "-t", "3"];
          pavuProc.running = true;
          return;
        }
        volumeProc.command = ["/home/galtrhan/.config/hypr/scripts/volume.sh", "--toggle"];
        volumeProc.running = true;
      }
      onWheel: function(wheel) {
        volumeProc.command = wheel.angleDelta.y > 0
            ? ["/home/galtrhan/.config/hypr/scripts/volume.sh", "--inc"]
            : ["/home/galtrhan/.config/hypr/scripts/volume.sh", "--dec"];
        volumeProc.running = true;
      }
    }
  }

  Text {
    text: formatMic()
    color: root.source?.audio?.muted ? Theme.micMuted : Theme.fgBright
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    visible: root.source !== null

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          pavuProc.command = ["pavucontrol", "-t", "4"];
          pavuProc.running = true;
          return;
        }
        volumeProc.command = ["/home/galtrhan/.config/hypr/scripts/volume.sh", "--toggle-mic"];
        volumeProc.running = true;
      }
      onWheel: function(wheel) {
        volumeProc.command = wheel.angleDelta.y > 0
            ? ["/home/galtrhan/.config/hypr/scripts/volume.sh", "--mic-inc"]
            : ["/home/galtrhan/.config/hypr/scripts/volume.sh", "--mic-dec"];
        volumeProc.running = true;
      }
    }
  }

  Process {
    id: volumeProc
    running: false
  }

  Process {
    id: pavuProc
    running: false
  }
}
