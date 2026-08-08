import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

RowLayout {
    id: root
    spacing: Theme.spacing
    Layout.fillHeight: true

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property int sinkPct: volumePercent(sink)
    readonly property int sourcePct: volumePercent(source)
    readonly property bool sinkSilent: sinkPct === 0 || !!(sink?.audio?.muted)
    readonly property bool sourceSilent: sourcePct === 0 || !!(source?.audio?.muted)

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
        if (vol < 33)
            return "";
        if (vol < 66)
            return "";
        return "";
    }

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        icon: root.sinkPct < 0 ? "" : (root.sinkSilent ? "" : root.volumeIcon(root.sinkPct))
        text: root.sinkPct < 0 ? "" : (root.sinkPct + "%")
        labelColor: root.sinkSilent ? Theme.micMuted : Theme.fgBright
        hoverEnabled: true
        tooltipText: "Scroll: volume · Right-click: pavucontrol"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton) {
                    pavuProc.command = ["pavucontrol", "-t", "3"];
                    pavuProc.running = true;
                    return;
                }
                volumeProc.command = [Paths.hyprScripts + "/volume.sh", "--toggle"];
                volumeProc.running = true;
            }
            onWheel: function (wheel) {
                volumeProc.command = wheel.angleDelta.y > 0
                    ? [Paths.hyprScripts + "/volume.sh", "--inc"]
                    : [Paths.hyprScripts + "/volume.sh", "--dec"];
                volumeProc.running = true;
            }
        }
    }

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        icon: {
            if (root.sourcePct < 0)
                return "";
            return root.sourceSilent ? "" : "";
        }
        text: (root.sourcePct < 0 || root.sourceSilent) ? "" : (root.sourcePct + "%")
        labelColor: root.sourceSilent ? Theme.micMuted : Theme.fgBright
        hoverEnabled: true
        visible: root.source !== null
        tooltipText: "Scroll: mic volume · Right-click: pavucontrol"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton) {
                    pavuProc.command = ["pavucontrol", "-t", "4"];
                    pavuProc.running = true;
                    return;
                }
                volumeProc.command = [Paths.hyprScripts + "/volume.sh", "--toggle-mic"];
                volumeProc.running = true;
            }
            onWheel: function (wheel) {
                volumeProc.command = wheel.angleDelta.y > 0
                    ? [Paths.hyprScripts + "/volume.sh", "--mic-inc"]
                    : [Paths.hyprScripts + "/volume.sh", "--mic-dec"];
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
