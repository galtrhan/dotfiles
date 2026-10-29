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
    property string gpuText: ""
    property int vramPct: 0
    property bool showVram: false
    property string tooltipBody: ""

    visible: gpuText !== ""

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        icon: "󰢮"
        text: root.gpuText
        labelColor: Theme.usageColor(root.gpuPct)
        tooltipText: root.tooltipBody
        hoverEnabled: true
    }

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        visible: root.showVram
        icon: "󰍛"
        text: root.vramPct + "%"
        labelColor: Theme.usageColor(root.vramPct)
        tooltipText: root.tooltipBody
        hoverEnabled: true
    }

    ScriptPoll {
        command: ["bash", Paths.gpuPoll]
        interval: 2000
        onOutput: function (text) {
            var sample = GpuLogic.parsePoll(text);
            if (!sample) {
                root.gpuText = "";
                root.tooltipBody = "";
                root.showVram = false;
                root.gpuPct = 0;
                root.prevSample = null;
                return;
            }
            var snap = GpuLogic.diff(root.prevSample, sample);
            root.prevSample = sample;
            if (!snap)
                return;
            root.gpuText = snap.text;
            root.tooltipBody = snap.tooltip;
            root.showVram = snap.showVram;
            if (!snap.text) {
                root.gpuPct = 0;
                return;
            }
            root.gpuPct = snap.pct;
            root.vramPct = snap.vramPct;
        }
    }
}
