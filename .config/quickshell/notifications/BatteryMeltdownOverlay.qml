import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            visible: BatteryMeltdownService.visible
            focusable: false
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell-battery-meltdown"

            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: "#cc000000"

                SequentialAnimation on color {
                    running: BatteryMeltdownService.visible
                    loops: Animation.Infinite
                    ColorAnimation {
                        to: "#cc1a0000"
                        duration: 1000
                        easing.type: Easing.InOutQuad
                    }
                    ColorAnimation {
                        to: "#cc000000"
                        duration: 1000
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Rectangle {
                id: vignette
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: "#880000" }
                    GradientStop { position: 0.35; color: "transparent" }
                    GradientStop { position: 0.65; color: "transparent" }
                    GradientStop { position: 1; color: "#880000" }
                }
                opacity: flashState.on ? 0.55 : 0.25

                SequentialAnimation on opacity {
                    running: BatteryMeltdownService.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.7; duration: 250; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.2; duration: 250; easing.type: Easing.InOutQuad }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: BatteryMeltdownService.dismiss()
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 18
                width: Math.min(modelData.width * 0.85, 720)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: alertColumn.implicitHeight + 48
                    radius: Theme.borderRadius
                    color: Qt.rgba(0, 0, 0, 0.82)
                    border.width: 3
                    border.color: flashState.on ? "#ff2222" : "#aa1111"

                    SequentialAnimation on border.color {
                        running: BatteryMeltdownService.visible
                        loops: Animation.Infinite
                        ColorAnimation { to: "#ff4444"; duration: 300 }
                        ColorAnimation { to: "#880000"; duration: 300 }
                    }

                    ColumnLayout {
                        id: alertColumn
                        anchors {
                            fill: parent
                            margins: 24
                        }
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "  BATTERY CRITICAL  "
                            font.family: Theme.fontFamily
                            font.pixelSize: 36
                            font.bold: true
                            color: flashState.on ? "#ff3333" : "#ff6666"
                            style: Text.Outline
                            styleColor: "#440000"

                            SequentialAnimation on color {
                                running: BatteryMeltdownService.visible
                                loops: Animation.Infinite
                                ColorAnimation { to: "#ff1111"; duration: 300 }
                                ColorAnimation { to: "#ff8888"; duration: 300 }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "CURRENT LEVEL AT " + BatteryMeltdownService.batteryLevel + "%"
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            font.letterSpacing: 2
                            color: flashState.on ? "#ff5555" : "#cc3333"

                            SequentialAnimation on opacity {
                                running: BatteryMeltdownService.visible
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.35; duration: 200 }
                                NumberAnimation { to: 1.0; duration: 200 }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 2
                            color: "#ff3333"
                            opacity: 0.6
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "SUSPENDING IN " + BatteryMeltdownService.formatCountdown(BatteryMeltdownService.secondsRemaining)
                            font.family: Theme.fontFamily
                            font.pixelSize: 28
                            font.bold: true
                            color: "#ffffff"
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "PLUG IN POWER NOW"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.letterSpacing: 1
                            wrapMode: Text.Wrap
                            color: "#ffaaaa"
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "click anywhere to dismiss"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.notifFgMuted
                            opacity: 0.7
                        }
                    }
                }
            }

            QtObject {
                id: flashState
                property bool on: false
            }

            Timer {
                running: BatteryMeltdownService.visible
                interval: 300
                repeat: true
                onTriggered: flashState.on = !flashState.on
            }
        }
    }
}
