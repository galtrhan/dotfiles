pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    property bool active: false
    property int capacity: 0
    readonly property int batteryLevel: root.capacity
    property bool userDismissed: false
    property int secondsRemaining: root.suspendDelaySec

    readonly property int suspendDelaySec: 60
    readonly property bool visible: root.active && !root.userDismissed

    function formatCountdown(seconds): string {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    function resetCountdown(): void {
        root.secondsRemaining = root.suspendDelaySec;
    }

    function triggerSuspend(): void {
        if (!root.visible)
            return;
        root.stopSound();
        suspendProc.command = ["systemctl", "suspend"];
        suspendProc.running = true;
    }

    function startSound(): void {
        if (soundProc.running)
            return;
        soundProc.command = [
            "ffplay",
            "-nodisp",
            "-loglevel", "quiet",
            "-loop", "0",
            Paths.batteryMeltdownSound
        ];
        soundProc.running = true;
    }

    function stopSound(): void {
        soundProc.running = false;
    }

    function activate(capacityPercent): void {
        const wasVisible = root.visible;
        root.capacity = capacityPercent >= 0 ? capacityPercent : root.capacity;
        root.userDismissed = false;
        root.active = true;
        if (!wasVisible)
            root.resetCountdown();
        root.startSound();
    }

    function dismiss(): void {
        root.userDismissed = true;
        root.stopSound();
        root.resetCountdown();
        countdownTimer.stop();
    }

    function deactivate(): void {
        root.active = false;
        root.userDismissed = false;
        root.stopSound();
        root.resetCountdown();
        countdownTimer.stop();
    }

    Process {
        id: soundProc
        running: false
    }

    Process {
        id: suspendProc
        running: false
    }

    Timer {
        id: countdownTimer
        running: root.visible
        interval: 1000
        repeat: true
        onTriggered: {
            if (!root.visible)
                return;
            if (root.secondsRemaining <= 1) {
                root.triggerSuspend();
                return;
            }
            root.secondsRemaining -= 1;
        }
    }

    readonly property Connections _powerConn: Connections {
        target: UPower.displayDevice.ready ? UPower.displayDevice : null

        function onStateChanged(): void {
            if (!UPower.displayDevice.ready)
                return;

            const state = UPower.displayDevice.state;
            if (state === UPowerDeviceState.Charging
                || state === UPowerDeviceState.FullyCharged) {
                root.deactivate();
            }
        }

        function onPercentageChanged(): void {
            if (!root.active || !UPower.displayDevice.ready)
                return;

            const pct = Math.round(UPower.displayDevice.percentage * 100);
            root.capacity = pct;

            if (UPower.displayDevice.state !== UPowerDeviceState.Discharging
                && UPower.displayDevice.state !== UPowerDeviceState.Empty) {
                root.deactivate();
            }
        }
    }
}
