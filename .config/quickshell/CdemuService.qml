pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string openOption: "Open"

    property bool loaded: false
    property string filename: ""
    property bool loaded2: false
    property string filename2: ""
    property string device: "0"
    property string device2: "1"
    property var recentImages: []
    property int pendingDevice: -1
    property int browseDevice: -1

    readonly property string cdemuDir: Quickshell.env("HOME") + "/.local/share/cdemu"

    signal statusChanged()

    FileView {
        id: recentFile
        path: Quickshell.statePath("cdemu-recent.json")
        onLoaded: {
            try {
                var data = JSON.parse(text());
                if (data && data.length !== undefined)
                    root.recentImages = data;
            } catch (e) {
                root.recentImages = [];
            }
        }
    }

    function saveRecent() {
        recentFile.setText(JSON.stringify(root.recentImages));
    }

    function loadDisc(path) {
        loadProc.command = ["cdemu", "load", "--unload", root.device, path];
        loadProc.running = true;
    }

    function unloadDisc() {
        unloadProc.command = ["cdemu", "unload", root.device];
        unloadProc.running = true;
    }

    function loadDisc2(path) {
        load2Proc.command = ["cdemu", "load", "--unload", root.device2, path];
        load2Proc.running = true;
    }

    function unloadDisc2() {
        unload2Proc.command = ["cdemu", "unload", root.device2];
        unload2Proc.running = true;
    }

    function loadOnDevice(device, path) {
        if (device === 0)
            root.loadDisc(path);
        else
            root.loadDisc2(path);
        root.addRecent(path);
    }

    function refreshStatus() {
        statusProc.running = true;
    }

    function addRecent(path) {
        var idx = root.recentImages.indexOf(path);
        if (idx >= 0)
            root.recentImages.splice(idx, 1);
        root.recentImages.unshift(path);
        if (root.recentImages.length > 10)
            root.recentImages.pop();
        root.recentImagesChanged();
        root.saveRecent();
    }

    function extractFilename(path) {
        if (!path)
            return "";
        var parts = path.split("/");
        return parts[parts.length - 1];
    }

    function resolveRecent(name) {
        for (var i = 0; i < root.recentImages.length; i++) {
            if (root.extractFilename(root.recentImages[i]) === name)
                return root.recentImages[i];
        }
        return "";
    }

    function showPicker(device) {
        var opts = [root.openOption];
        for (var i = 0; i < root.recentImages.length; i++)
            opts.push(root.extractFilename(root.recentImages[i]));
        LauncherService.openMenu("CDEmu " + (device + 1), opts, true, 1);
    }

    function openPicker(device) {
        root.pendingDevice = device;
        if (root.recentImages.length === 0) {
            root.pendingDevice = -1;
            root.browseDevice = device;
            browseProc.running = true;
            return;
        }
        recentCheckProc.command = ["sh", "-c",
            "for path do [ -e \"$path\" ] && printf '%s\\n' \"$path\"; done",
            "cdemu-recent-check"].concat(root.recentImages);
        recentCheckProc.running = true;
    }

    function applySelection(value) {
        if (root.pendingDevice < 0)
            return;
        var device = root.pendingDevice;
        root.pendingDevice = -1;
        if (value === root.openOption) {
            root.browseDevice = device;
            browseProc.running = true;
            return;
        }
        var path = root.resolveRecent(value);
        if (path.length > 0)
            root.loadOnDevice(device, path);
    }

    function parseStatus(text) {
        var lines = text.split("\n");
        var foundDev0 = false;
        var foundDev1 = false;
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.indexOf("DEV") === 0)
                continue;
            var parts = line.split(/\s+/);
            if (parts.length >= 3) {
                var devIdx = parts[0];
                var loaded = parts[1] === "True";
                var fname = loaded ? parts.slice(2).join(" ") : "";
                if (devIdx === "0") {
                    root.loaded = loaded;
                    root.filename = fname ? root.extractFilename(fname) : "";
                    foundDev0 = true;
                } else if (devIdx === "1") {
                    root.loaded2 = loaded;
                    root.filename2 = fname ? root.extractFilename(fname) : "";
                    foundDev1 = true;
                }
            }
        }
        if (!foundDev0) {
            root.loaded = false;
            root.filename = "";
        }
        if (!foundDev1) {
            root.loaded2 = false;
            root.filename2 = "";
        }
        root.statusChanged();
    }

    Connections {
        target: LauncherService
        function onMenuSelected(value) {
            root.applySelection(value);
        }
        function onMenuCancelled() {
            root.pendingDevice = -1;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.refreshStatus()
    }

    Component.onCompleted: refreshStatus()

    Process {
        id: browseProc
        command: ["zenity", "--file-selection", "--title=Select disc image (.cue recommended)"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var path = this.text.trim();
                var device = root.browseDevice;
                root.browseDevice = -1;
                if (path.length > 0 && device >= 0)
                    root.loadOnDevice(device, path);
            }
        }
    }

    Process {
        id: recentCheckProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var valid = this.text.trim().length > 0 ? this.text.trim().split("\n") : [];
                var changed = valid.length !== root.recentImages.length;
                if (!changed) {
                    for (var i = 0; i < valid.length; i++) {
                        if (valid[i] !== root.recentImages[i]) {
                            changed = true;
                            break;
                        }
                    }
                }
                root.recentImages = valid;
                if (changed)
                    root.saveRecent();

                var device = root.pendingDevice;
                if (device < 0)
                    return;
                if (valid.length === 0) {
                    root.pendingDevice = -1;
                    root.browseDevice = device;
                    browseProc.running = true;
                    return;
                }
                root.showPicker(device);
            }
        }
    }

    Process {
        id: statusProc
        command: ["cdemu", "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseStatus(this.text)
        }
    }

    Process {
        id: loadProc
        running: false
        onRunningChanged: {
            if (!running)
                root.refreshStatus();
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.log("cdemu load:", this.text);
            }
        }
    }

    Process {
        id: unloadProc
        running: false
        onRunningChanged: {
            if (!running)
                root.refreshStatus();
        }
    }

    Process {
        id: load2Proc
        running: false
        onRunningChanged: {
            if (!running)
                root.refreshStatus();
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.log("cdemu load2:", this.text);
            }
        }
    }

    Process {
        id: unload2Proc
        running: false
        onRunningChanged: {
            if (!running)
                root.refreshStatus();
        }
    }
}
