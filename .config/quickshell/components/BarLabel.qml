import QtQuick
import ".."
import "."

Text {
    id: root

    property string tooltipText: ""
    property color labelColor: Theme.fgBright
    property int labelSize: Theme.fontSize
    property int labelWeight: Font.Normal
    property bool tooltipVisible: false

    font.family: Theme.fontFamily
    font.pixelSize: labelSize
    font.weight: labelWeight
    color: labelColor

    HoverHandler {
        id: hover
        enabled: root.tooltipText !== ""
        onHoveredChanged: root.tooltipVisible = hovered
    }

    BarTooltip {
        anchorItem: root
        text: root.tooltipText
        visible: root.tooltipVisible
    }
}
