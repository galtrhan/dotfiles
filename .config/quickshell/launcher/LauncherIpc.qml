import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Scope {
    id: root

    LauncherPanel {
        ipcHandler: menuIpc
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
            else if (LauncherService.menuWaiting)
                menuIpc.cancelled();
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

        function show_password(prompt: string): void {
            LauncherService.openPassword(prompt);
        }
    }
}
