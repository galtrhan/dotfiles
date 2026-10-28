import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../lib/RamLogic.js" as RamLogic

RowLayout {
    id: root

    spacing: Theme.spacing
    Layout.fillHeight: true

    property int ramPct: 0
    property int swapPct: 0
    property int tmpPct: 0
    property bool showSwap: false
    property bool showTmp: false
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
        icon: ""
        text: root.ramPct + "%"
        labelColor: root.usageColor(root.ramPct)
        tooltipText: root.tooltipBody
        hoverEnabled: true
    }

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        visible: root.showSwap
        icon: ""
        text: root.swapPct + "%"
        labelColor: root.usageColor(root.swapPct)
        tooltipText: root.tooltipBody
        hoverEnabled: true
    }

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        visible: root.showTmp
        icon: ""
        text: root.tmpPct + "%"
        labelColor: root.usageColor(root.tmpPct)
        tooltipText: root.tooltipBody
        hoverEnabled: true
    }

    ScriptPoll {
        command: ["sh", "-c", "cat /proc/meminfo; echo ---; df -B1 /tmp"]
        interval: 5000
        onOutput: function (text) {
            var snap = RamLogic.snapshot(text);
            if (!snap) {
                root.hasData = false;
                root.tooltipBody = "";
                root.showSwap = false;
                root.showTmp = false;
                return;
            }
            root.ramPct = snap.ramPct;
            root.swapPct = snap.swapPct;
            root.tmpPct = snap.tmpPct;
            root.showSwap = snap.showSwap;
            root.showTmp = snap.showTmp;
            root.tooltipBody = snap.tooltip;
            root.hasData = true;
        }
    }
}
