import Quickshell.Services.UPower
import QtQuick
import ".."
import "../components"

BarLabel {
    readonly property var profileIcons: ({
        "PowerSaver": "",
        "Balanced": "",
        "Performance": ""
    })

    icon: {
        var name = PowerProfile.toString(PowerProfiles.profile);
        return profileIcons[name] || "";
    }
    visible: PowerProfiles.profile !== PowerProfile.PowerSaver || PowerProfiles.hasPerformanceProfile
    tooltipText: "Click to cycle power profile"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var profiles = [PowerProfile.PowerSaver, PowerProfile.Balanced];
            if (PowerProfiles.hasPerformanceProfile)
                profiles.push(PowerProfile.Performance);
            var idx = profiles.indexOf(PowerProfiles.profile);
            if (idx < 0)
                return;
            PowerProfiles.profile = profiles[(idx + 1) % profiles.length];
        }
    }
}
