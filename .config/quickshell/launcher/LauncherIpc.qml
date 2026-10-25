import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Scope {
    id: root

    LauncherPanel {
        ipcHandler: menuIpc
    }

    // Options for `show_search_file`. `qs ipc call` mangles arguments larger
    // than roughly 22 KB, so long lists (clipboard history) go through a file.
    FileView {
        id: menuOptionsFile
        property string pendingTitle
        property bool pendingSearchable: true
        path: ""

        onLoaded: {
            const opts = menuOptionsFile.text().split("\n").filter(function (line) {
                return line.length > 0;
            });
            LauncherService.openMenu(menuOptionsFile.pendingTitle, opts, menuOptionsFile.pendingSearchable);
        }
    }

    IpcHandler {
        id: launcherIpc
        target: "launcher"

        function toggle(): void {
            if (LauncherService.mode === LauncherService.modeApps)
                LauncherService.close();
            else
                LauncherService.openApps();
        }

        function open(): void {
            LauncherService.openApps();
        }

        function close(): void {
            if (LauncherService.mode === LauncherService.modePassword)
                menuIpc.passwordEntered("");
            else if (LauncherService.menuWaiting) {
                menuIpc.cancelled();
                menuIpc.selected("");
            }
            LauncherService.close();
        }

        function emoji_toggle(): void {
            LauncherService.toggleEmoji();
        }
    }

    IpcHandler {
        id: menuIpc
        target: "menu"

        signal selected(value: string)
        signal cancelled()
        signal passwordEntered(value: string)

        function show(title: string, options: string): void {
            const opts = options.split("\n").filter(function (line) {
                return line.length > 0;
            });
            LauncherService.openMenu(title, opts, false);
        }

        function show_search(title: string, options: string): void {
            const opts = options.split("\n").filter(function (line) {
                return line.length > 0;
            });
            LauncherService.openMenu(title, opts, true);
        }

        function show_search_file(title: string, path: string): void {
            menuOptionsFile.pendingTitle = title;
            menuOptionsFile.pendingSearchable = true;
            menuOptionsFile.path = path;
        }

        function show_password(prompt: string): void {
            LauncherService.openPassword(prompt);
        }
    }
}
