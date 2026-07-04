import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Scope {
    id: root

    property var ipcHandler: null

    function finishMenuSelection(value): void {
        if (root.ipcHandler)
            root.ipcHandler.selected(value);
        LauncherService.close();
    }

    function finishMenuCancel(): void {
        if (!root.ipcHandler)
            return LauncherService.close();

        if (LauncherService.mode === LauncherService.modePassword)
            root.ipcHandler.passwordEntered("");
        else if (LauncherService.menuWaiting)
            root.ipcHandler.cancelled();
        LauncherService.close();
    }

    function finishPassword(value): void {
        if (root.ipcHandler)
            root.ipcHandler.passwordEntered(value);
        LauncherService.close();
    }

    function copyEmoji(entry): void {
        if (!entry || !entry.emoji)
            return;
        copyProc.command = ["wl-copy", entry.emoji];
        copyProc.running = true;
        LauncherService.close();
    }

    Process {
        id: copyProc
        running: false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            // Only map the overlay on the monitor that was focused when the
            // launcher opened; mapping a full-screen surface per monitor is
            // slow and shows the launcher everywhere.
            visible: LauncherService.visible
                     && (LauncherService.activeScreenName === ""
                         || LauncherService.activeScreenName === modelData.name)
            focusable: true
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "quickshell-launcher"

            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.finishMenuCancel()
            }

            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: LauncherService.mode === LauncherService.modeApps
                       ? Theme.launcherAppWidth
                       : (LauncherService.mode === LauncherService.modeEmoji
                          ? Theme.launcherPickerWidth
                          : (LauncherService.mode === LauncherService.modeMenu
                             ? (LauncherService.menuSearchable
                                ? Theme.launcherPickerWidth
                                : Theme.launcherMenuWidth)
                             : Theme.launcherAppWidth))
                implicitHeight: panelContent.implicitHeight + Theme.barPadding * 2
                height: Math.min(implicitHeight, modelData.height * 0.75)
                radius: Theme.borderRadius
                color: Theme.bg
                border.width: 0
                clip: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: function (mouse) {
                        mouse.accepted = true;
                    }
                }

                ColumnLayout {
                    id: panelContent
                    anchors {
                        fill: parent
                        margins: Theme.barPadding
                    }
                    spacing: Theme.spacing

                    Text {
                        Layout.fillWidth: true
                        visible: LauncherService.mode !== LauncherService.modeApps
                                 && LauncherService.mode !== LauncherService.modeEmoji
                        text: LauncherService.title
                        color: Theme.launcherTextDefault
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.launcherFontSize
                        horizontalAlignment: LauncherService.mode === LauncherService.modeMenu
                                             && !LauncherService.menuSearchable
                                             ? Text.AlignHCenter : Text.AlignLeft
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.launcherFontSize + Theme.launcherInputPaddingV * 2
                        visible: LauncherService.mode === LauncherService.modeApps
                                 || LauncherService.mode === LauncherService.modeEmoji
                                 || (LauncherService.mode === LauncherService.modeMenu
                                     && LauncherService.menuSearchable)
                        radius: Theme.borderRadius
                        color: Theme.launcherInputBg
                        border.width: 1
                        border.color: Theme.launcherInputBorder

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                bottom: parent.bottom
                                leftMargin: Theme.launcherInputPaddingH
                                rightMargin: Theme.launcherInputPaddingH
                                topMargin: Theme.launcherInputPaddingV
                                bottomMargin: Theme.launcherInputPaddingV
                            }
                            verticalAlignment: Text.AlignVCenter
                            visible: searchInput.text.length === 0 && !searchInput.activeFocus
                            text: LauncherService.mode === LauncherService.modeApps
                                  ? "Search applications…"
                                  : (LauncherService.mode === LauncherService.modeEmoji
                                     ? "Search emojis…"
                                     : "Search…")
                            color: Theme.launcherTextInactive
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.launcherFontSize
                            elide: Text.ElideRight
                        }

                        TextInput {
                            id: searchInput
                            anchors {
                                fill: parent
                                leftMargin: Theme.launcherInputPaddingH
                                rightMargin: Theme.launcherInputPaddingH
                                topMargin: Theme.launcherInputPaddingV
                                bottomMargin: Theme.launcherInputPaddingV
                            }
                            text: LauncherService.query
                            color: Theme.launcherTextDefault
                            selectionColor: Theme.bgSolid
                            selectedTextColor: Theme.launcherTextActive
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.launcherFontSize
                            selectByMouse: true
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            focus: LauncherService.visible
                                    && (LauncherService.mode === LauncherService.modeApps
                                        || LauncherService.mode === LauncherService.modeEmoji
                                        || (LauncherService.mode === LauncherService.modeMenu
                                            && LauncherService.menuSearchable))

                            onTextChanged: {
                                LauncherService.query = text;
                                LauncherService.selectedIndex = 0;
                            }

                            Keys.onPressed: function (event) {
                                if (event.key === Qt.Key_Escape) {
                                    event.accepted = true;
                                    root.finishMenuCancel();
                                    return;
                                }

                                if (LauncherService.mode === LauncherService.modeApps) {
                                    if (event.key === Qt.Key_Down) {
                                        event.accepted = true;
                                        appList.incrementCurrentIndex();
                                    } else if (event.key === Qt.Key_Up) {
                                        event.accepted = true;
                                        appList.decrementCurrentIndex();
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        event.accepted = true;
                                        appList.launchCurrent();
                                    }
                                    return;
                                }

                                if (LauncherService.mode === LauncherService.modeEmoji) {
                                    if (event.key === Qt.Key_Down) {
                                        event.accepted = true;
                                        emojiList.incrementCurrentIndex();
                                    } else if (event.key === Qt.Key_Up) {
                                        event.accepted = true;
                                        emojiList.decrementCurrentIndex();
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        event.accepted = true;
                                        emojiList.copyCurrent();
                                    }
                                    return;
                                }

                                if (LauncherService.mode === LauncherService.modeMenu) {
                                    if (event.key === Qt.Key_Down) {
                                        event.accepted = true;
                                        menuList.incrementCurrentIndex();
                                    } else if (event.key === Qt.Key_Up) {
                                        event.accepted = true;
                                        menuList.decrementCurrentIndex();
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        event.accepted = true;
                                        menuList.activateCurrent();
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.launcherFontSize + Theme.launcherInputPaddingV * 2
                        visible: LauncherService.mode === LauncherService.modePassword
                        radius: Theme.borderRadius
                        color: Theme.launcherInputBg
                        border.width: 1
                        border.color: passwordInput.activeFocus ? Theme.fg : Theme.launcherInputBorder

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                bottom: parent.bottom
                                leftMargin: Theme.launcherInputPaddingH
                                rightMargin: Theme.launcherInputPaddingH
                                topMargin: Theme.launcherInputPaddingV
                                bottomMargin: Theme.launcherInputPaddingV
                            }
                            verticalAlignment: Text.AlignVCenter
                            visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                            text: "Password"
                            color: Theme.launcherTextInactive
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.launcherFontSize
                            elide: Text.ElideRight
                        }

                        TextInput {
                            id: passwordInput
                            anchors {
                                fill: parent
                                leftMargin: Theme.launcherInputPaddingH
                                rightMargin: Theme.launcherInputPaddingH
                                topMargin: Theme.launcherInputPaddingV
                                bottomMargin: Theme.launcherInputPaddingV
                            }
                            text: LauncherService.query
                            color: Theme.launcherTextDefault
                            selectionColor: Theme.bgSolid
                            selectedTextColor: Theme.launcherTextActive
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.launcherFontSize
                            echoMode: TextInput.Password
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            focus: LauncherService.visible
                                    && LauncherService.mode === LauncherService.modePassword

                            onTextChanged: LauncherService.query = text

                            Keys.onPressed: function (event) {
                                if (event.key === Qt.Key_Escape) {
                                    event.accepted = true;
                                    root.finishMenuCancel();
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    event.accepted = true;
                                    root.finishPassword(passwordInput.text);
                                }
                            }
                        }
                    }

                    ScrollView {
                        id: appScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: Theme.barHeight * 10
                        visible: LauncherService.mode === LauncherService.modeApps
                        clip: true

                        ListView {
                            id: appList
                            model: ScriptModel {
                                // Gated by mode so typing in other modes
                                // doesn't re-filter this list too.
                                values: LauncherService.mode === LauncherService.modeApps
                                        ? LauncherService.filteredApps() : []
                            }
                            reuseItems: true
                            currentIndex: LauncherService.selectedIndex
                            boundsBehavior: Flickable.StopAtBounds
                            keyNavigationWraps: true
                            highlightMoveDuration: 80

                            onCurrentIndexChanged: LauncherService.selectedIndex = currentIndex

                            onModelChanged: LauncherService.clampSelectedIndex(count)

                            highlight: Rectangle {
                                radius: Theme.borderRadius
                                color: Theme.bgSolid
                            }

                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: appList.width
                                height: Theme.barHeight

                                RowLayout {
                                    anchors {
                                        fill: parent
                                        leftMargin: Theme.barPadding
                                        rightMargin: Theme.barPadding
                                    }
                                    spacing: Theme.spacing

                                    // IconImage {
                                    //     Layout.preferredWidth: Theme.launcherFontSize + 4
                                    //     Layout.preferredHeight: Theme.launcherFontSize + 4
                                    //     visible: modelData.icon !== ""
                                    //     source: modelData.icon
                                    // }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: appList.currentIndex === index ? Theme.launcherTextActive : Theme.launcherTextDefault
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.launcherFontSize
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: modelData.genericName !== ""
                                        text: modelData.genericName
                                        color: Theme.launcherTextInactive
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.launcherFontSize
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 140
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: appList.launchEntry(modelData)
                                    onEntered: appList.currentIndex = index
                                }
                            }

                            function launchCurrent(): void {
                                const values = LauncherService.filteredApps();
                                if (currentIndex < 0 || currentIndex >= values.length)
                                    return;
                                launchEntry(values[currentIndex]);
                            }

                            function launchEntry(entry): void {
                                if (!entry)
                                    return;
                                entry.execute();
                                LauncherService.close();
                            }

                            function incrementCurrentIndex(): void {
                                if (count === 0)
                                    return;
                                currentIndex = (currentIndex + 1) % count;
                            }

                            function decrementCurrentIndex(): void {
                                if (count === 0)
                                    return;
                                currentIndex = currentIndex <= 0 ? count - 1 : currentIndex - 1;
                            }
                        }
                    }

                    ScrollView {
                        id: emojiScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: Theme.barHeight * 10
                        visible: LauncherService.mode === LauncherService.modeEmoji
                        clip: true

                        ListView {
                            id: emojiList
                            model: ScriptModel {
                                values: LauncherService.mode === LauncherService.modeEmoji
                                        ? LauncherService.filteredEmojis() : []
                            }
                            reuseItems: true
                            currentIndex: LauncherService.selectedIndex
                            boundsBehavior: Flickable.StopAtBounds
                            keyNavigationWraps: true
                            highlightMoveDuration: 80

                            onCurrentIndexChanged: LauncherService.selectedIndex = currentIndex

                            onModelChanged: LauncherService.clampSelectedIndex(count)

                            highlight: Rectangle {
                                radius: Theme.borderRadius
                                color: Theme.bgSolid
                            }

                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: emojiList.width
                                height: Theme.barHeight

                                RowLayout {
                                    anchors {
                                        fill: parent
                                        leftMargin: Theme.barPadding
                                        rightMargin: Theme.barPadding
                                    }
                                    spacing: Theme.spacing

                                    Text {
                                        text: modelData.emoji
                                        color: emojiList.currentIndex === index ? Theme.launcherTextActive : Theme.launcherTextDefault
                                        font.pixelSize: Theme.launcherFontSize + 4
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.description
                                        color: emojiList.currentIndex === index ? Theme.launcherTextActive : Theme.launcherTextDefault
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.launcherFontSize
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.copyEmoji(modelData)
                                    onEntered: emojiList.currentIndex = index
                                }
                            }

                            function copyCurrent(): void {
                                const values = LauncherService.filteredEmojis();
                                if (currentIndex < 0 || currentIndex >= values.length)
                                    return;
                                root.copyEmoji(values[currentIndex]);
                            }

                            function incrementCurrentIndex(): void {
                                if (count === 0)
                                    return;
                                currentIndex = (currentIndex + 1) % count;
                            }

                            function decrementCurrentIndex(): void {
                                if (count === 0)
                                    return;
                                currentIndex = currentIndex <= 0 ? count - 1 : currentIndex - 1;
                            }
                        }
                    }

                    ScrollView {
                        id: menuScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: Math.min(
                            Math.max(menuList.count, 1) * Theme.barHeight + Theme.spacing,
                            Theme.barHeight * 8
                        )
                        visible: LauncherService.mode === LauncherService.modeMenu
                        clip: true

                        ListView {
                            id: menuList
                            model: ScriptModel {
                                values: LauncherService.mode === LauncherService.modeMenu
                                        ? LauncherService.filteredMenuOptions() : []
                            }
                            reuseItems: true
                            currentIndex: LauncherService.selectedIndex
                            boundsBehavior: Flickable.StopAtBounds
                            keyNavigationWraps: true
                            highlightMoveDuration: 80
                            focus: LauncherService.visible
                                   && LauncherService.mode === LauncherService.modeMenu
                                   && !LauncherService.menuSearchable

                            Keys.onPressed: function (event) {
                                if (event.key === Qt.Key_Escape) {
                                    event.accepted = true;
                                    root.finishMenuCancel();
                                } else if (event.key === Qt.Key_Down) {
                                    event.accepted = true;
                                    menuList.incrementCurrentIndex();
                                } else if (event.key === Qt.Key_Up) {
                                    event.accepted = true;
                                    menuList.decrementCurrentIndex();
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    event.accepted = true;
                                    menuList.activateCurrent();
                                }
                            }

                            onCurrentIndexChanged: LauncherService.selectedIndex = currentIndex

                            onModelChanged: LauncherService.clampSelectedIndex(count)

                            highlight: Rectangle {
                                radius: Theme.borderRadius
                                color: Theme.bgSolid
                            }

                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: menuList.width
                                height: Theme.barHeight

                                Text {
                                    anchors {
                                        fill: parent
                                        leftMargin: LauncherService.menuSearchable ? Theme.barPadding : 0
                                        rightMargin: LauncherService.menuSearchable ? Theme.barPadding : 0
                                    }
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: LauncherService.menuSearchable
                                                     ? Text.AlignLeft : Text.AlignHCenter
                                    text: modelData
                                    color: menuList.currentIndex === index ? Theme.launcherTextActive : Theme.launcherTextDefault
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.launcherFontSize
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: menuList.activateEntry(modelData)
                                    onEntered: menuList.currentIndex = index
                                }
                            }

                            function activateCurrent(): void {
                                const values = LauncherService.filteredMenuOptions();
                                if (currentIndex < 0 || currentIndex >= values.length)
                                    return;
                                activateEntry(values[currentIndex]);
                            }

                            function activateEntry(value): void {
                                if (!value)
                                    return;
                                root.finishMenuSelection(value);
                            }

                            function incrementCurrentIndex(): void {
                                if (count === 0)
                                    return;
                                currentIndex = (currentIndex + 1) % count;
                            }

                            function decrementCurrentIndex(): void {
                                if (count === 0)
                                    return;
                                currentIndex = currentIndex <= 0 ? count - 1 : currentIndex - 1;
                            }
                        }
                    }
                }
            }

            onVisibleChanged: {
                if (!visible)
                    return;
                appList.currentIndex = 0;
                menuList.currentIndex = 0;
                emojiList.currentIndex = 0;
                appList.positionViewAtBeginning();
                menuList.positionViewAtBeginning();
                emojiList.positionViewAtBeginning();
                if (LauncherService.mode === LauncherService.modePassword)
                    passwordInput.forceActiveFocus();
                else if (LauncherService.mode === LauncherService.modeApps)
                    searchInput.forceActiveFocus();
                else if (LauncherService.mode === LauncherService.modeEmoji)
                    searchInput.forceActiveFocus();
                else if (LauncherService.mode === LauncherService.modeMenu && LauncherService.menuSearchable)
                    searchInput.forceActiveFocus();
                else if (LauncherService.mode === LauncherService.modeMenu)
                    menuList.forceActiveFocus();
            }
        }
    }
}
