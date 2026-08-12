import QtQuick
import ".."
import "../components"

BarLabel {
    id: root

    visible: DockerService.active
    icon: ""
    labelColor: Theme.cdemuLoaded
    hoverEnabled: true
    tooltipText: root.buildTooltip()

    function buildTooltip() {
        if (!DockerService.active)
            return "Docker: no containers";
        var lines = ["Docker containers:"];
        for (var i = 0; i < DockerService.containers.length; i++)
            lines.push(DockerService.containers[i]);
        return lines.join("\n");
    }
}
