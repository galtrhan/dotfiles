import QtQuick
import QtQuick.Layouts
import "."
import ".."

// Truncated Text that shows the full string in BarTooltip on hover.
Text {
    id: root

    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    color: Theme.launcherTextDefault
    font.family: Theme.fontFamily
    font.pixelSize: Theme.launcherFontSize
    wrapMode: Text.WordWrap
    elide: Text.ElideRight
    maximumLineCount: 2

    HoverHandler {
        id: tipHover
        enabled: root.truncated
    }

    BarTooltip {
        anchorItem: root
        text: root.text
        visible: tipHover.hovered && root.truncated
    }
}
