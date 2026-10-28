import QtQuick
import ".."
import "../components"
import "../lib/CpuLogic.js" as CpuLogic

BarLabel {
    id: root

    property var prevSample: null
    property int fillPct: 0
    property string displayText: ""
    property string tooltipBody: ""

    icon: "󰻠"
    text: displayText
    labelColor: usageColor(fillPct)
    visible: displayText !== ""
    tooltipText: tooltipBody
    hoverEnabled: true

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

    ScriptPoll {
        command: [
            "sh", "-c",
            "cat /proc/stat; echo ---; " +
            "awk -F': ' '/^model name/{gsub(/^ +/,\"\",$2); print $2; exit}' /proc/cpuinfo; echo ---; " +
            "awk '/^cpu cores/{c=$4} /^siblings/{s=$3} END{print c+0, s+0}' /proc/cpuinfo"
        ]
        interval: 2000
        onOutput: function (text) {
            var sample = CpuLogic.parsePoll(text);
            if (!sample) {
                root.displayText = "";
                root.tooltipBody = "";
                root.fillPct = 0;
                root.prevSample = null;
                return;
            }
            if (root.prevSample) {
                var snap = CpuLogic.diff(root.prevSample, sample);
                if (snap) {
                    root.displayText = snap.text;
                    root.tooltipBody = snap.tooltip;
                    root.fillPct = snap.pct;
                }
            }
            root.prevSample = sample;
        }
    }
}
