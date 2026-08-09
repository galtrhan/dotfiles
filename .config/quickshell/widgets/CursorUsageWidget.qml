import Quickshell.Io
import QtQuick
import ".."
import "../components"
import "../lib/CursorUsageLogic.js" as CursorUsageLogic

Item {
    id: root

    property string usageClass: ""
    property string displayText: ""
    property string tooltipBody: ""

    implicitWidth: logo.width + 3 + label.implicitWidth
    implicitHeight: Theme.barHeight
    width: implicitWidth
    height: implicitHeight
    clip: true
    visible: displayText !== ""

    readonly property int logoSize: Theme.iconSize

    Image {
        id: logo
        width: root.logoSize
        height: root.logoSize
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Theme.barOpticalOffset
        source: Paths.cursorIcon
        sourceSize: Qt.size(root.logoSize * 2, root.logoSize * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    BarLabel {
        id: label
        anchors.left: logo.right
        anchors.leftMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        text: root.displayText
        labelColor: {
            if (usageClass === "cool")
                return Theme.tempCool;
            if (usageClass === "warning")
                return Theme.tempWarning;
            if (usageClass === "critical")
                return Theme.tempCritical;
            return Theme.fgBright;
        }
        tooltipText: root.tooltipBody
        hoverEnabled: true
    }

    ScriptPoll {
        command: ["python3", Paths.cursorUsageWidget]
        interval: 300000
        onOutput: function (text) {
            var snapshot = CursorUsageLogic.loadSnapshot(text);
            if (!snapshot || snapshot.status !== "ok" || !snapshot.meters || snapshot.meters.length === 0) {
                root.displayText = "";
                root.tooltipBody = "";
                root.usageClass = "";
                return;
            }

            var used = CursorUsageLogic.maxUsedPercent(snapshot.meters);
            root.displayText = used + "%";
            root.tooltipBody = CursorUsageLogic.buildTooltip(snapshot);
            root.usageClass = CursorUsageLogic.usageClass(used);
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.visible
        onClicked: openProc.running = true
    }

    Process {
        id: openProc
        command: ["xdg-open", "https://cursor.com/dashboard/usage"]
        running: false
    }
}
