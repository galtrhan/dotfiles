import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import ".."
import "../components"

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
        if (vol <= 0)
            return "󰖁";
        if (vol < 33)
            return "";
        if (vol < 66)
            return "";
        return "󰕾";
    }

    function formatOutput() {
        var pct = volumePercent(sink);
        if (pct < 0)
            return "";
        var icon = sink.audio.muted ? "󰖁" : volumeIcon(pct);
        return icon + " " + pct + "%";
    }

    function formatMic() {
        var pct = volumePercent(source);
        if (pct < 0)
            return "";
        if (source.audio.muted)
            return "";
        return " " + pct + "%";
    }

    BarLabel {
        text: formatOutput()
        labelColor: root.sink?.audio?.muted ? Theme.micMuted : Theme.fgBright
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
        text: formatMic()
        labelColor: root.source?.audio?.muted ? Theme.micMuted : Theme.fgBright
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
