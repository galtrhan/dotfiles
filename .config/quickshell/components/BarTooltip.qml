import QtQuick
import ".."
import Quickshell
import Quickshell.Widgets

PopupWindow {
    id: root

    required property Item anchorItem
    property string text: ""
    property int textFormat: Text.PlainText

    visible: text !== ""
    color: "transparent"

    anchor {
        window: anchorItem.QsWindow.window
        onAnchoring: {
            var pos = anchorItem.QsWindow.contentItem.mapFromItem(
                anchorItem,
                anchorItem.width / 2 - root.implicitWidth / 2,
                anchorItem.height + 4
            );
            anchor.rect.x = pos.x;
            anchor.rect.y = pos.y;
        }
    }

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    WrapperRectangle {
        id: frame
        color: Theme.tooltipBg
        border.color: Theme.tooltipBorder
        margin: 6
        radius: 4

        Text {
            text: root.text
            textFormat: root.textFormat
            color: Theme.tooltipFg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
}
