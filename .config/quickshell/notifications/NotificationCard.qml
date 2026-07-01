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

    visible: modelData !== null

    implicitWidth: Theme.notifWidth
    implicitHeight: cardContent.implicitHeight + (compact ? 16 : 24)
    radius: Theme.borderRadius
    color: Theme.notifBg
    border.color: modelData.urgency === NotificationUrgency.Critical ? Theme.notifUrgencyCritical
        : modelData.urgency === NotificationUrgency.Low ? Theme.notifUrgencyLow
        : Theme.notifBorder
    border.width: 1
    clip: true

    HoverHandler {
        id: cardHover
        onHoveredChanged: root.modelData.hovered = hovered
    }

    ColumnLayout {
        id: cardContent
        anchors {
            fill: parent
            margins: compact ? 8 : 12
        }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: compact ? 20 : 24
                Layout.preferredHeight: compact ? 20 : 24
                radius: 4
                color: "transparent"
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

            Text {
                text: root.modelData.appName || "Notification"
                color: "#ffffff"
                font.family: Theme.fontFamily
                font.pixelSize: compact ? 20 : 22
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: compact ? 36 : 36
                Layout.preferredHeight: compact ? 36 : 36
                radius: 18
                color: closeHover.containsMouse ? Theme.notifBorder : "transparent"
                Layout.alignment: Qt.AlignVCenter

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
                    onClicked: root.fullDismiss ? root.modelData.dismiss() : root.modelData.removePopup()
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
                    running: root.showTimer
                             && !root.modelData.hasProgress
                             && root.modelData.urgency !== NotificationUrgency.Critical
                             && root.modelData.effectiveTimeout > 0
                    PauseAnimation { duration: 50 }
                    NumberAnimation {
                        target: progressFill
                        property: "width"
                        from: progressFill.parent.width
                        to: 0
                        duration: root.modelData.effectiveTimeout
                    }
                }

                Connections {
                    target: root.modelData
                    function onTimerGenerationChanged(): void {
                        if (root.showTimer && !root.modelData.hasProgress)
                            progressFill.width = progressFill.parent.width;
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                root.modelData.dismiss()
                return
            }
            if (mouse.y < 40)
                return
            root.fullDismiss ? root.modelData.dismiss() : root.modelData.removePopup()
        }
    }
}
