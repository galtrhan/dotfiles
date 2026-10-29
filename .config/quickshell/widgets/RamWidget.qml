import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."
import "../components"
import "../lib/RamLogic.js" as RamLogic

Item {
    id: root

    property int fillPct: 0
    property int tmpPct: 0
    property string memText: ""
    property bool showMem: false
    property bool showTmp: false
    property string tooltipBody: ""
    property bool menuOpen: false
    property var menuItems: []

    visible: showMem || showTmp
    implicitWidth: layout.implicitWidth
    implicitHeight: Theme.barHeight
    width: implicitWidth
    height: implicitHeight

    onVisibleChanged: if (!visible)
        menuOpen = false

    function openMenu() {
        if (root.menuOpen) {
            root.menuOpen = false;
            return;
        }
        if (topProc.running)
            return;
        topProc.running = true;
    }

    RowLayout {
        id: layout
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing

        BarLabel {
            id: memLabel
            Layout.alignment: Qt.AlignVCenter
            visible: root.showMem
            icon: ""
            text: root.memText
            labelColor: Theme.usageColor(root.fillPct)
            tooltipText: root.menuOpen ? "" : root.tooltipBody
            hoverEnabled: true
        }

        BarLabel {
            Layout.alignment: Qt.AlignVCenter
            visible: root.showTmp
            icon: ""
            text: root.tmpPct + "%"
            labelColor: Theme.usageColor(root.tmpPct)
            tooltipText: root.menuOpen ? "" : root.tooltipBody
            hoverEnabled: true
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: root.openMenu()
    }

    BarMenu {
        anchorItem: memLabel.visible ? memLabel : root
        open: root.menuOpen
        items: root.menuItems
        showKillButton: true
        onItemKillRequested: function (pids) {
            var args = ["kill", "--"];
            for (var i = 0; i < pids.length; i++)
                args.push(String(pids[i]));
            killProc.command = args;
            killProc.running = true;
            root.menuOpen = false;
        }
        onDismissed: root.menuOpen = false
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

    Process {
        id: topProc
        command: [Paths.ramTop]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.menuItems = RamLogic.parseTopConsumers(this.text);
                root.menuOpen = root.menuItems.length > 0;
            }
        }
    }

    Process {
        id: killProc
        running: false
    }
}
