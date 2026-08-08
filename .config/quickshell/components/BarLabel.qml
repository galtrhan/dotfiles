import QtQuick
import ".."
import "."

Item {
    id: root

    property string text: ""
    property string icon: ""
    property string tooltipText: ""
    property int tooltipFormat: Text.PlainText
    property color labelColor: Theme.fgBright
    property color hoverColor: Theme.hoverColor
    property int labelSize: Theme.fontSize
    property int iconSize: Theme.iconSize
    property int labelWeight: Font.Normal
    property bool tooltipVisible: false
    property bool hoverEnabled: false

    // One Text so icon+label share a baseline; iconSize when an icon is set.
    readonly property string displayText: {
        if (icon !== "" && text !== "")
            return icon + " " + text;
        if (icon !== "")
            return icon;
        return text;
    }
    readonly property int displaySize: icon !== "" ? iconSize : labelSize

    implicitWidth: label.implicitWidth
    implicitHeight: Theme.barHeight
    width: implicitWidth
    height: implicitHeight

    Text {
        id: label
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Theme.barOpticalOffset
        text: root.displayText
        font.family: Theme.fontFamily
        font.pixelSize: root.displaySize
        font.weight: root.labelWeight
        color: root.hoverEnabled && hover.hovered ? root.hoverColor : root.labelColor

        Behavior on color {
            ColorAnimation {
                duration: Theme.hoverTransitionDuration
            }
        }
    }

    HoverHandler {
        id: hover
        enabled: root.hoverEnabled || root.tooltipText !== ""
    onHoveredChanged: root.tooltipVisible = hovered && root.tooltipText !== ""
    }

    BarTooltip {
        anchorItem: root
        text: root.tooltipText
        textFormat: root.tooltipFormat
        visible: root.tooltipVisible
    }
}
