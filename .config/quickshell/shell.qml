//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  Process {
    id: namedaysProc
    command: ["/home/galtrhan/.config/waybar/namedays.sh"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(this.text);
          BarState.namedaysText = data.text;
          BarState.namedaysTooltip = data.tooltip || "";
        } catch (e) {
          BarState.namedaysText = this.text;
        }
      }
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: namedaysProc.running = true
  }

  Process {
    id: ipProc
    command: ["/home/galtrhan/.config/waybar/get_ip.sh"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(this.text);
          BarState.ipText = data.text || "";
        } catch (e) {
          BarState.ipText = this.text;
        }
      }
    }
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: ipProc.running = true
  }

  Process {
    id: tempsProc
    command: ["/home/galtrhan/.config/waybar/temps.py"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(this.text);
          BarState.tempsText = data.text || "";
          BarState.tempsTooltip = data.tooltip || "";
          BarState.tempsClass = data.class || "";
        } catch (e) {
          BarState.tempsText = this.text;
        }
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: tempsProc.running = true
  }

  Process {
    id: recProc
    command: ["/home/galtrhan/.config/waybar/screen_capture_indicator.sh"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(this.text);
          BarState.recText = data.text || "";
          BarState.recClass = data.class || "idle";
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: recProc.running = true
  }

  Process {
    id: backlightProc
    command: ["brightnessctl", "info"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var text = this.text;
        var match = text.match(/Current brightness: (\d+)/);
        var maxMatch = text.match(/Max brightness: (\d+)/);
        if (match && maxMatch) {
          var current = parseInt(match[1]);
          var max = parseInt(maxMatch[1]);
          BarState.brightnessPercent = Math.round((current / max) * 100);
        }
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: backlightProc.running = true
  }

  Process {
    id: ipCopyProc
    command: ["/home/galtrhan/.config/waybar/get_ip.sh", "--copy"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {}
    }
  }

  Connections {
    target: BarState
    function onCopyIpRequestedChanged() {
      ipCopyProc.running = true
    }
  }

  Variants {
    model: Quickshell.screens
    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { top: true; left: true; right: true }
      margins { top: Theme.margin; left: Theme.margin; right: Theme.margin }
      implicitHeight: Theme.barHeight
      color: "transparent"
      aboveWindows: true
      exclusiveZone: Theme.barHeight + Theme.margin * 2

      Rectangle {
        anchors.fill: parent
        radius: Theme.borderRadius
        color: Theme.bg
        border.width: 0
      }

      Bar {
        anchors.fill: parent
      }
    }
  }
}
