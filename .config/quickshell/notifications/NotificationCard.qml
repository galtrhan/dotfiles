import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property var modelData: null
    property bool showTimer: false
    property bool compact: false
    property bool fullDismiss: false
    property int badgeCount: 0
    property bool dismissAsGroup: false
    property string groupAppName: ""
    property bool toggleExpandOnClick: false
    property bool interactive: true
    property bool stackedAppearance: false
    property bool showGroupBadge: false

    readonly property int sidePadding: compact ? 8 : 12
    readonly property int headerHeight: compact ? 28 : 32
    readonly property color cardBorderColor: !modelData ? Theme.notifBorder
        : modelData.urgency === NotificationUrgency.Critical ? Theme.notifUrgencyCritical
        : modelData.urgency === NotificationUrgency.Low ? Theme.notifUrgencyLow
        : Theme.notifBorder

    readonly property bool shouldAnimateTimer: root.showTimer
            && root.modelData
            && !root.modelData.hasProgress
            && !root.modelData.isPersistent
            && root.modelData.effectiveTimeout > 0

    function restartTimerAnimation(): void {
        if (!root.shouldAnimateTimer) {
            timerAnim.stop();
            return;
        }
        timerAnim.stop();
        progressFill.width = progressFill.parent.width;
        timerAnim.restart();
    }

    visible: modelData !== null

    width: Theme.notifWidth
    implicitWidth: Theme.notifWidth
    implicitHeight: cardContent.implicitHeight + sidePadding * 2
    radius: Theme.borderRadius
    color: Theme.notifBg
    border.color: cardBorderColor
    border.width: stackedAppearance ? 0 : 1
    clip: true

    HoverHandler {
        id: cardHover
        enabled: root.interactive && root.modelData !== null
        onHoveredChanged: {
            if (root.modelData)
                root.modelData.hovered = hovered;
        }
    }

    ColumnLayout {
        id: cardContent
        anchors {
            fill: parent
            margins: sidePadding
        }
        spacing: 6

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: headerHeight

            Text {
                id: appNameText
                anchors {
                    left: iconSlot.visible ? iconSlot.right : parent.left
                    leftMargin: iconSlot.visible ? 8 : 0
                    right: groupBadge.visible ? groupBadge.left : closeArea.left
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                text: root.modelData.appName || "Notification"
                color: Theme.notifFg
                font.family: Theme.fontFamily
                font.pixelSize: compact ? 11 : 12
                font.bold: true
                elide: Text.ElideRight
            }

            Item {
                id: iconSlot
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: compact ? 20 : 24
                height: compact ? 20 : 24
                visible: root.modelData.appIcon !== "" || root.modelData.image !== ""

                IconImage {
                    anchors.fill: parent
                    visible: root.modelData.appIcon !== "" && root.modelData.image === ""
                    source: root.modelData.appIcon
                }

                Image {
                    anchors.fill: parent
                    visible: root.modelData.image !== ""
                    source: root.modelData.image
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: compact ? 20 : 24
                    sourceSize.height: compact ? 20 : 24
                }
            }

            Rectangle {
                id: groupBadge
                anchors {
                    right: closeArea.left
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                width: badgeLabel.implicitWidth + 10
                height: 18
                radius: 9
                color: Qt.rgba(255, 255, 255, 0.15)
                visible: root.showGroupBadge && root.badgeCount > 1

                Text {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: String(root.badgeCount)
                    color: Theme.notifFg
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            Rectangle {
                id: closeArea
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36
                radius: 18
                color: closeHover.containsMouse ? Theme.notifBorder : "transparent"
                visible: root.interactive

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: closeHover.containsMouse ? Theme.notifFg : Theme.notifFgMuted
                    font.pixelSize: 28
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.dismissAsGroup)
                            NotificationService.dismissGroup(root.groupAppName);
                        else
                            root.fullDismiss ? root.modelData.dismiss() : root.modelData.removePopup();
                    }
                }
            }
        }

        Text {
            text: root.modelData.summary
            color: Theme.notifFgMuted
            font.family: Theme.fontFamily
            font.pixelSize: compact ? 12 : 13
            elide: Text.ElideRight
            Layout.fillWidth: true
            visible: text !== ""
        }

        Text {
            text: root.modelData.body
            color: Theme.notifFgMuted
            font.family: Theme.fontFamily
            font.pixelSize: compact ? 11 : 12
            wrapMode: Text.Wrap
            maximumLineCount: compact ? 2 : 4
            elide: Text.ElideRight
            Layout.fillWidth: true
            visible: text !== ""
            textFormat: Text.PlainText
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.modelData.actions.length > 0

            Repeater {
                model: root.modelData.actions

                Rectangle {
                    id: actionBtn
                    required property var modelData

                    Layout.preferredHeight: 24
                    Layout.preferredWidth: actionText.width + 14
                    radius: 4
                    color: actionHover.containsMouse ? Theme.notifBorder : Qt.rgba(255, 255, 255, 0.06)

                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: actionBtn.modelData.text || ""
                        color: Theme.notifAccent
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: actionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modelData.invokeAction(actionBtn.modelData.identifier)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.modelData.hasProgress ? 8 : 2
            radius: 2
            color: Qt.rgba(255, 255, 255, 0.08)
            visible: root.showTimer || root.modelData.hasProgress

            Rectangle {
                id: progressFill
                height: parent.height
                radius: 2
                color: root.modelData.hasProgress ? Theme.notifProgress : Theme.notifAccent
                opacity: root.modelData.hasProgress ? 0.85 : 0.55
                width: root.modelData.hasProgress
                       ? parent.width * (root.modelData.progress / 100)
                       : parent.width

                SequentialAnimation {
                    id: timerAnim
                    PauseAnimation { duration: 50 }
                    NumberAnimation {
                        target: progressFill
                        property: "width"
                        from: progressFill.parent.width
                        to: 0
                        duration: root.modelData ? root.modelData.effectiveTimeout : 0
                    }
                }

                Connections {
                    target: root.modelData
                    function onTimerGenerationChanged(): void {
                        root.restartTimerAnimation();
                    }
                }

                Component.onCompleted: root.restartTimerAnimation()
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        radius: 0
        color: cardBorderColor
        visible: stackedAppearance
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        height: 1
        radius: 0
        color: cardBorderColor
        visible: stackedAppearance
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        radius: 0
        color: cardBorderColor
        visible: stackedAppearance
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 3
        radius: 0
        color: cardBorderColor
        visible: stackedAppearance
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                if (root.dismissAsGroup)
                    NotificationService.dismissGroup(root.groupAppName);
                else
                    root.modelData.dismiss();
                return;
            }
            if (root.toggleExpandOnClick) {
                NotificationService.toggleGroupExpanded(root.groupAppName);
                return;
            }
            if (mouse.y < 40)
                return;
            root.fullDismiss ? root.modelData.dismiss() : root.modelData.removePopup();
        }
    }
}
