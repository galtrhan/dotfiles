import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../lib/RamLogic.js" as RamLogic

RowLayout {
    id: root

    spacing: Theme.spacing
    Layout.fillHeight: true

    property int fillPct: 0
    property int tmpPct: 0
    property string memText: ""
    property bool showMem: false
    property bool showTmp: false
    property string tooltipBody: ""

    visible: showMem || showTmp

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        visible: root.showMem
        icon: ""
        text: root.memText
        labelColor: Theme.usageColor(root.fillPct)
        tooltipText: root.tooltipBody
        hoverEnabled: true
    }

    BarLabel {
        Layout.alignment: Qt.AlignVCenter
        visible: root.showTmp
        icon: ""
        text: root.tmpPct + "%"
        labelColor: Theme.usageColor(root.tmpPct)
        tooltipText: root.tooltipBody
        hoverEnabled: true
    }

    ScriptPoll {
        command: ["sh", "-c", "cat /proc/meminfo; echo ---; df -B1 /tmp"]
        interval: 5000
        onOutput: function (text) {
            var snap = RamLogic.snapshot(text);
            if (!snap) {
                root.tooltipBody = "";
                root.memText = "";
                root.showMem = false;
                root.showTmp = false;
                root.fillPct = 0;
                return;
            }
            root.fillPct = snap.fillPct;
            root.tmpPct = snap.tmpPct;
            root.memText = snap.text;
            root.showMem = snap.showMem;
            root.showTmp = snap.showTmp;
            root.tooltipBody = snap.tooltip;
        }
    }
}
