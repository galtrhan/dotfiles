import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import "../components"
import "../lib/TempsLogic.js" as TempsLogic

BarLabel {
    id: root

    readonly property int historySize: 12

    property string tempsClass: ""
    property string tooltipBody: ""
    property string displayText: ""

    FileView {
        id: historyFile
        path: Quickshell.statePath("temps-history.json")
    }

    icon: ""
    text: displayText
    labelColor: {
        if (tempsClass === "cool")
            return Theme.tempCool;
        if (tempsClass === "warning")
            return Theme.tempWarning;
        if (tempsClass === "critical")
            return Theme.tempCritical;
        return Theme.fgBright;
    }
    visible: displayText !== ""
    tooltipText: tooltipBody
    hoverEnabled: true

    ScriptPoll {
        command: ["sensors", "-j"]
        interval: 5000
        onOutput: function (text) {
            try {
                var data = JSON.parse(text);
                var temps = TempsLogic.parseTemps(data);
                if (temps.length === 0) {
                    root.displayText = "??°C";
                    root.tooltipBody = "No temperature data";
                    root.tempsClass = "";
                    return;
                }

                var cpuTemp = TempsLogic.findCpuTemp(temps);
                var history = TempsLogic.loadHistory(historyFile.text());
                var rolling = TempsLogic.rollingAverage(history, cpuTemp, root.historySize);
                historyFile.setText(JSON.stringify(rolling.history));

                root.displayText = rolling.average + "°C";
                root.tooltipBody = TempsLogic.buildTooltip(temps);
                root.tempsClass = TempsLogic.tempClass(rolling.average);
            } catch (e) {
                root.displayText = "";
                root.tooltipBody = "";
                root.tempsClass = "";
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.visible && root.tooltipBody !== ""
        onClicked: {
            notifyProc.command = ["notify-send", "-a", "quickshell", "Temperatures", root.tooltipBody];
            notifyProc.running = true;
        }
    }

    Process {
        id: notifyProc
        running: false
    }
}
