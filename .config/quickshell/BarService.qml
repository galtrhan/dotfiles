pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property bool visible: true

    function toggle(): void {
        root.visible = !root.visible;
    }
}
