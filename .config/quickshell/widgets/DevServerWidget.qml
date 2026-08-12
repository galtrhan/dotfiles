import QtQuick
import ".."
import "../components"

Item {
    id: root

    visible: DevServerService.active
    implicitWidth: label.implicitWidth
    implicitHeight: Theme.barHeight
    width: implicitWidth
    height: implicitHeight

    property bool menuOpen: false

    onVisibleChanged: if (!visible)
        menuOpen = false

    function buildTooltip() {
        if (!DevServerService.active)
            return "Dev servers: none";
        var lines = ["Dev servers:"];
        for (var i = 0; i < DevServerService.servers.length; i++) {
            var server = DevServerService.servers[i];
            var portText = server.ports.length > 0
                ? " " + server.ports.split(",").map(function (p) {
                    return ":" + p;
                }).join(", ")
                : " (starting)";
            lines.push(server.label + portText);
        }
        lines.push("Left click: menu");
        lines.push("Open: browser · Right: kill");
        return lines.join("\n");
    }

    function buildMenuItems() {
        var items = [];
        for (var i = 0; i < DevServerService.servers.length; i++) {
            var server = DevServerService.servers[i];
            var ports = server.ports.length > 0
                ? server.ports.split(",").map(function (p) {
                    return p.trim();
                }).filter(function (p) {
                    return p.length > 0;
                })
                : [];
            var portText = ports.length > 0
                ? " " + ports.map(function (p) {
                    return ":" + p;
                }).join(", ")
                : " (starting)";
            items.push({
                label: server.label + portText,
                url: ports.length > 0 ? "http://localhost:" + ports[0] : "",
                pid: server.pid
            });
        }
        return items;
    }

    BarLabel {
        id: label
        icon: ""
        labelColor: Theme.workspaceActive
        hoverEnabled: true
        tooltipText: root.menuOpen ? "" : root.buildTooltip()
    }

    BarMenu {
        anchorItem: label
        open: root.menuOpen
        items: root.buildMenuItems()
        onItemClicked: function (url) {
            DevServerService.openUrl(url);
            root.menuOpen = false;
        }
        onItemRightClicked: function (pid) {
            DevServerService.killServer(pid);
            root.menuOpen = false;
        }
        onDismissed: root.menuOpen = false
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.buildMenuItems().length === 0)
                return;
            root.menuOpen = !root.menuOpen;
        }
    }
}
