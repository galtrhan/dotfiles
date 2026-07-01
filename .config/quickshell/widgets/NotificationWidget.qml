import QtQuick
import ".."
import "../components"

Item {
    id: root

    implicitWidth: bellLabel.width + badge.width
    implicitHeight: Math.max(bellLabel.height, badge.height)

    property color iconColor: Theme.fgBright
    property string tooltipText: {
        if (NotificationService.doNotDisturb)
            return "Notifications (DND on) · click to open";
        if (NotificationService.unreadCount > 0)
            return NotificationService.unreadCount + " unread · click to open";
        return "Notifications · click to open";
    }

    BarLabel {
        id: bellLabel
        anchors.verticalCenter: parent.verticalCenter
        text: NotificationService.doNotDisturb ? "󰂛" : "󰂚"
        labelColor: root.iconColor
        tooltipText: root.tooltipText
    }

    Rectangle {
        id: badge
        anchors {
            top: bellLabel.top
            right: bellLabel.right
            topMargin: -2
            rightMargin: -4
        }
        width: Math.max(14, badgeText.implicitWidth + 6)
        height: 14
        radius: 7
        color: Theme.notifUrgencyCritical
        visible: NotificationService.unreadCount > 0 && !NotificationService.doNotDisturb

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: NotificationService.unreadCount > 99 ? "99+" : String(NotificationService.unreadCount)
            color: Theme.notifFg
            font.family: Theme.fontFamily
            font.pixelSize: 8
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: NotificationService.toggleCenter()
        onEntered: root.iconColor = Theme.notifAccent
        onExited: root.iconColor = Theme.fgBright
    }
}
