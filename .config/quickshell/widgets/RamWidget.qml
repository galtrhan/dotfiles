import QtQuick
import ".."
import "../components"
import "../lib/RamLogic.js" as RamLogic

BarLabel {
    id: root

    property int fillPct: 0
    property string displayText: ""
    property string tooltipBody: ""

    icon: ""
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
        command: ["sh", "-c", "cat /proc/meminfo; echo ---; df -B1 /tmp"]
        interval: 5000
        onOutput: function (text) {
            var snap = RamLogic.snapshot(text);
            if (!snap) {
                root.displayText = "";
                root.tooltipBody = "";
                root.fillPct = 0;
                return;
            }
            root.displayText = snap.text;
            root.tooltipBody = snap.tooltip;
            root.fillPct = snap.pct;
        }
    }
}
