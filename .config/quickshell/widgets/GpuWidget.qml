import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../lib/GpuLogic.js" as GpuLogic

RowLayout {
    id: root

    spacing: Theme.spacing
    Layout.fillHeight: true

    property var prevSample: null
    property int gpuPct: 0
    property int vramPct: 0
    property bool showVram: false
    property string tooltipBody: ""
    property bool hasData: false

    visible: hasData

    function usageColor(pct) {
        var t = Math.min(Math.max(pct / 100, 0), 1);
        var low = Qt.color(Theme.batteryGood);
        var high = Qt.color(Theme.batteryCritical);
        return Qt.rgba(
            low.r + (high.r - low.r) * t,
            low.g + (high.g - low.g) * t,
            low.b + (high.b - low.b) * t,
            1
        );
    }

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        icon: "󰢮"
        text: root.gpuPct + "%"
        labelColor: root.usageColor(root.gpuPct)
        tooltipText: root.tooltipBody
        hoverEnabled: true
    }

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        visible: root.showVram
        icon: "󰍛"
        text: root.vramPct + "%"
        labelColor: root.usageColor(root.vramPct)
        tooltipText: root.tooltipBody
        hoverEnabled: true
    }

    ScriptPoll {
        command: ["bash", Paths.gpuPoll]
        interval: 2000
        onOutput: function (text) {
            var sample = GpuLogic.parsePoll(text);
            if (!sample) {
                root.hasData = false;
                root.tooltipBody = "";
                root.showVram = false;
                root.prevSample = null;
                return;
            }
            var snap = GpuLogic.diff(root.prevSample, sample);
            root.prevSample = sample;
            if (!snap)
                return;
            root.gpuPct = snap.pct;
            root.vramPct = snap.vramPct;
            root.showVram = snap.showVram;
            root.tooltipBody = snap.tooltip;
            root.hasData = true;
        }
    }
}
