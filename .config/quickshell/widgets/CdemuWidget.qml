import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    // Verified against JetBrainsMono Nerd Font glyph names
    readonly property string iconEmpty: "󰉉"  // md-floppy
    readonly property string iconIso: "󰋊"    // md-harddisk
    readonly property string iconCd: "󰗮"     // md-disc
    readonly property string iconDvd: "󰿎"    // md-movie_open

    function mediaIcon(loaded, filename) {
        if (!loaded)
            return iconEmpty;
        var name = (filename || "").toLowerCase();
        var dot = name.lastIndexOf(".");
        var ext = dot >= 0 ? name.slice(dot + 1) : "";
        if (ext === "iso" || ext === "img")
            return iconIso;
        if (ext === "mds" || ext === "mdf" || ext === "nrg" || ext === "dvd")
            return iconDvd;
        // .cue / .bin / .toc / .ccd and anything else → CD
        return iconCd;
    }

    function driveText(loaded, filename) {
        return mediaIcon(loaded, filename);
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Theme.spacing

        BarLabel {
            Layout.alignment: Qt.AlignVCenter
            text: root.driveText(CdemuService.loaded, CdemuService.filename)
            labelSize: Theme.fontSize + 6
            labelColor: CdemuService.loaded ? Theme.workspaceActive : Theme.fgMuted
            tooltipText: CdemuService.loaded
                ? "CDEmu 1: " + CdemuService.filename + "\nLeft: open · Right: eject"
                : "CDEmu 1: no disc loaded\nLeft: open"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function (mouse) {
                    if (mouse.button === Qt.RightButton) {
                        if (CdemuService.loaded)
                            CdemuService.unloadDisc();
                        return;
                    }
                    CdemuService.openPicker(0);
                }
            }
        }

        BarLabel {
            Layout.alignment: Qt.AlignVCenter
            visible: CdemuService.loaded || CdemuService.loaded2
            text: root.driveText(CdemuService.loaded2, CdemuService.filename2)
            labelSize: Theme.fontSize + 6
            labelColor: CdemuService.loaded2 ? Theme.workspaceActive : Theme.fgMuted
            tooltipText: CdemuService.loaded2
                ? "CDEmu 2: " + CdemuService.filename2 + "\nLeft: open · Right: eject"
                : "CDEmu 2: no disc loaded\nLeft: open"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function (mouse) {
                    if (mouse.button === Qt.RightButton) {
                        if (CdemuService.loaded2)
                            CdemuService.unloadDisc2();
                        return;
                    }
                    CdemuService.openPicker(1);
                }
            }
        }
    }
}
