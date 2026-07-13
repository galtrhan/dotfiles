import QtQuick
import ".."

Item {
    id: root

    required property string appName
    required property var items

    readonly property int stackCount: Math.min(items.length, 3)
    readonly property int stackOffset: 3

    implicitWidth: Theme.notifWidth
    width: Theme.notifWidth
    implicitHeight: stackCount > 0
        ? frontCard.implicitHeight + (stackCount - 1) * stackOffset
        : 0

    NotificationCard {
        id: frontCard
        width: Theme.notifWidth
        x: 0
        y: 0
        z: stackCount
        visible: root.items.length > 0
        modelData: root.items.length > 0 ? root.items[0] : null
        showTimer: false
        compact: true
        fullDismiss: true
        badgeCount: root.items.length
        showGroupBadge: true
        stackedAppearance: true
        dismissAsGroup: true
        groupAppName: root.appName
        toggleExpandOnClick: true
    }

    Repeater {
        model: Math.max(0, root.stackCount - 1)

        delegate: NotificationCard {
            required property int index
            width: Theme.notifWidth
            x: 0
            y: (index + 1) * root.stackOffset
            z: root.stackCount - index - 1
            modelData: root.items[index + 1]
            showTimer: false
            compact: true
            fullDismiss: true
            stackedAppearance: true
            interactive: false
        }
    }
}
