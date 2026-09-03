import Quickshell.Io
import QtQuick
import ".."
import "../components"
import "../lib/CursorUsageLogic.js" as CursorUsageLogic

Item {
    id: root

    property int includedPct: -1
    property int apiPct: -1
    property string includedClass: ""
    property string apiClass: ""
    property string tooltipBody: ""
    property bool tooltipVisible: false

    readonly property bool hasData: includedPct >= 0 && apiPct >= 0
    readonly property int logoSize: Theme.iconSize

    function colorFor(usageClass) {
        if (usageClass === "cool")
            return Theme.tempCool;
        if (usageClass === "warning")
            return Theme.tempWarning;
        if (usageClass === "critical")
            return Theme.tempCritical;
        return Theme.fgBright;
    }

    implicitWidth: logo.width + 3 + labelRow.implicitWidth
    implicitHeight: Theme.barHeight
    width: implicitWidth
    height: implicitHeight
    clip: true
    visible: hasData

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

    Row {
        id: labelRow
        anchors.left: logo.right
        anchors.leftMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Theme.barOpticalOffset
        spacing: 0

        Text {
            text: root.includedPct + "%"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: hover.hovered ? Theme.hoverColor : root.colorFor(root.includedClass)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.hoverTransitionDuration
                }
            }
        }

        Text {
            text: "/"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: hover.hovered ? Theme.hoverColor : Theme.fgMuted

            Behavior on color {
                ColorAnimation {
                    duration: Theme.hoverTransitionDuration
                }
            }
        }

        Text {
            text: root.apiPct + "%"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: hover.hovered ? Theme.hoverColor : root.colorFor(root.apiClass)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.hoverTransitionDuration
                }
            }
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: root.tooltipVisible = hovered && root.tooltipBody !== ""
    }

    BarTooltip {
        anchorItem: root
        text: root.tooltipBody
        visible: root.tooltipVisible
    }

    ScriptPoll {
        command: ["python3", Paths.cursorUsageWidget]
        interval: 300000
        onOutput: function (text) {
            var snapshot = CursorUsageLogic.loadSnapshot(text);
            if (!snapshot || snapshot.status !== "ok" || !snapshot.meters || snapshot.meters.length === 0) {
                root.includedPct = -1;
                root.apiPct = -1;
                root.includedClass = "";
                root.apiClass = "";
                root.tooltipBody = "";
                return;
            }

            var included = CursorUsageLogic.meterPercentById(snapshot.meters, "included");
            var api = CursorUsageLogic.meterPercentById(snapshot.meters, "api");
            if (included === null && api === null) {
                root.includedPct = -1;
                root.apiPct = -1;
                root.includedClass = "";
                root.apiClass = "";
                root.tooltipBody = "";
                return;
            }
            if (included === null)
                included = 0;
            if (api === null)
                api = 0;

            root.includedPct = included;
            root.apiPct = api;
            root.includedClass = CursorUsageLogic.usageClass(included);
            root.apiClass = CursorUsageLogic.usageClass(api);
            root.tooltipBody = CursorUsageLogic.buildTooltip(snapshot);
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
