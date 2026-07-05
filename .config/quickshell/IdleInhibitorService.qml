pragma Singleton

import Quickshell
import Quickshell.Wayland
import QtQuick

Singleton {
    id: root

    property bool enabled: false

    function toggle(): void {
        root.enabled = !root.enabled;
    }

    IdleInhibitor {
        enabled: root.enabled
        window: inhibitorWindow
    }

    PanelWindow {
        id: inhibitorWindow
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        visible: true
        implicitWidth: 0
        implicitHeight: 0
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "quickshell-idle-inhibitor"
    }
}
