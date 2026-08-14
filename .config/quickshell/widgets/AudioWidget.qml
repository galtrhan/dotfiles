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
    property int selectedMicId: -1
    readonly property PwNode source: root.selectedMicId > 0 ? (findNode(root.selectedMicId) || Pipewire.defaultAudioSource) : Pipewire.defaultAudioSource
    readonly property int sinkPct: volumePercent(sink)
    readonly property int sourcePct: volumePercent(source)
    readonly property bool sinkSilent: sinkPct === 0 || !!(sink?.audio?.muted)
    readonly property bool sourceSilent: sourcePct === 0 || !!(source?.audio?.muted)

    property bool micMenuOpen: false
    property var micMenuItems: []

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

    function findNode(id) {
        var values = Pipewire.nodes.values;
        for (var i = 0; i < values.length; i++) {
            var node = values[i];
            if (node && node.id === id)
                return node;
        }
        return null;
    }

    function buildMicMenuItems(text) {
        var items = [];
        items.push({ label: "Toggle mute (all mics)", url: "__toggle__", pid: 0 });
        var lines = text.trim().split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            if (line.length === 0)
                continue;
            var parts = line.split("|");
            var label = parts[1] || ("Mic " + parts[0]);
            if (label.endsWith("*")) {
                label = "✓ " + label.slice(0, -1);
            }
            items.push({ label: label, url: parts[0], pid: 0 });
        }
        return items;
    }

    ScriptPoll {
        command: [Paths.hyprScripts + "/volume.sh", "--mic-selected"]
        interval: 2000
        onOutput: function (text) {
            var id = parseInt(text.trim(), 10);
            if (!isNaN(id) && id > 0)
                root.selectedMicId = id;
        }
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
        id: micLabel
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
        tooltipText: "Click: select mic · Scroll: mic volume · Right: pavucontrol"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton) {
                    pavuProc.command = ["pavucontrol", "-t", "4"];
                    pavuProc.running = true;
                    return;
                }
                if (mouse.button === Qt.MiddleButton) {
                    volumeProc.command = [Paths.hyprScripts + "/volume.sh", "--toggle-mic"];
                    volumeProc.running = true;
                    return;
                }
                micListProc.command = [Paths.hyprScripts + "/volume.sh", "--mic-list"];
                micListProc.running = true;
            }
            onWheel: function (wheel) {
                volumeProc.command = wheel.angleDelta.y > 0
                    ? [Paths.hyprScripts + "/volume.sh", "--mic-inc"]
                    : [Paths.hyprScripts + "/volume.sh", "--mic-dec"];
                volumeProc.running = true;
            }
        }
    }

    BarMenu {
        anchorItem: micLabel
        open: root.micMenuOpen && root.micMenuItems.length > 0
        items: root.micMenuItems
        onItemClicked: function (url) {
            root.micMenuOpen = false;
            if (url === "__toggle__") {
                volumeProc.command = [Paths.hyprScripts + "/volume.sh", "--toggle-mic"];
                volumeProc.running = true;
                return;
            }
            volumeProc.command = [Paths.hyprScripts + "/volume.sh", "--mic-select", url];
            volumeProc.running = true;
        }
        onDismissed: root.micMenuOpen = false
    }

    Process {
        id: volumeProc
        running: false
    }

    Process {
        id: pavuProc
        running: false
    }

    Process {
        id: micListProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.micMenuItems = root.buildMicMenuItems(this.text);
                root.micMenuOpen = true;
            }
        }
    }
}
