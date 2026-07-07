pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "lib/AppUsageLogic.js" as AppUsageLogic
import "lib/EmojiLogic.js" as EmojiLogic

Singleton {
    id: root

    readonly property int modeClosed: 0
    readonly property int modeApps: 1
    readonly property int modeMenu: 2
    readonly property int modePassword: 3
    readonly property int modeEmoji: 4

    property int mode: root.modeClosed
    property string query: ""
    property string title: ""
    property var menuOptions: []
    property var emojis: []
    property int selectedIndex: 0
    property bool menuWaiting: false
    property bool menuSearchable: false
    property var appUsage: ({})
    property var emojiUsage: ({})

    // Connector name of the monitor that was focused when the launcher was
    // opened; the panel only maps on that screen. Empty means all screens.
    property string activeScreenName: ""

    readonly property bool visible: mode !== root.modeClosed

    function captureFocusedScreen(): void {
        const focused = Hyprland.focusedMonitor?.name ?? "";
        if (focused !== "") {
            root.activeScreenName = focused;
            return;
        }
        if (Quickshell.screens.length > 0)
            root.activeScreenName = Quickshell.screens[0].name;
        else
            root.activeScreenName = "";
    }

    FileView {
        id: emojiFile
        path: Paths.configDir + "/quickshell/emoji/emojis.json"

        onLoaded: {
            try {
                root.emojis = EmojiLogic.parseEmojiFile(emojiFile.text());
            } catch (e) {
                root.emojis = [];
            }
        }
    }

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")

        onLoaded: root.appUsage = AppUsageLogic.loadUsage(usageFile.text())
    }

    FileView {
        id: emojiUsageFile
        path: Quickshell.statePath("launcher-emoji-usage.json")

        onLoaded: root.emojiUsage = AppUsageLogic.loadUsage(emojiUsageFile.text())
    }

    function openApps(): void {
        root.captureFocusedScreen();
        root.mode = root.modeApps;
        root.query = "";
        root.selectedIndex = 0;
        root.menuWaiting = false;
    }

    function openEmoji(): void {
        root.captureFocusedScreen();
        root.title = "Emoji";
        root.query = "";
        root.selectedIndex = 0;
        root.menuWaiting = false;
        root.mode = root.modeEmoji;
    }

    function toggleEmoji(): void {
        if (root.mode === root.modeEmoji)
            root.close();
        else
            root.openEmoji();
    }

    function openMenu(title, options, searchable): void {
        root.captureFocusedScreen();
        root.title = title;
        root.menuOptions = options;
        root.query = "";
        root.selectedIndex = 0;
        root.menuSearchable = searchable === true;
        root.mode = root.modeMenu;
        root.menuWaiting = true;
    }

    function openPassword(prompt): void {
        root.captureFocusedScreen();
        root.title = prompt;
        root.query = "";
        root.mode = root.modePassword;
        root.menuWaiting = true;
    }

    function close(): void {
        root.mode = root.modeClosed;
        root.query = "";
        root.selectedIndex = 0;
        root.menuWaiting = false;
        root.menuSearchable = false;
    }

    function recordAppLaunch(entry): void {
        if (!entry || !entry.id)
            return;

        root.appUsage = AppUsageLogic.recordLaunch(root.appUsage, entry.id);
        usageFile.setText(JSON.stringify(root.appUsage));
    }

    function recordEmojiSelection(entry): void {
        if (!entry || !entry.emoji)
            return;

        root.emojiUsage = AppUsageLogic.recordLaunch(root.emojiUsage, entry.emoji);
        emojiUsageFile.setText(JSON.stringify(root.emojiUsage));
    }

    function filteredApps(): var {
        const all = DesktopEntries.applications.values;
        const q = root.query.trim().toLowerCase();
        if (q === "")
            return AppUsageLogic.sortApps(all, root.appUsage);

        return all.filter(function (entry) {
            const name = (entry.name || "").toLowerCase();
            const generic = (entry.genericName || "").toLowerCase();
            if (name.includes(q) || generic.includes(q))
                return true;

            const keywords = entry.keywords || [];
            for (var i = 0; i < keywords.length; i++) {
                if (keywords[i].toLowerCase().includes(q))
                    return true;
            }
            return false;
        });
    }

    function filteredMenuOptions(): var {
        const q = root.query.trim().toLowerCase();
        if (q === "")
            return root.menuOptions;

        return root.menuOptions.filter(function (option) {
            return option.toLowerCase().includes(q);
        });
    }

    function filteredEmojis(): var {
        const q = root.query.trim();
        if (q === "")
            return EmojiLogic.sortEmojis(root.emojis, root.emojiUsage);

        return EmojiLogic.filterEmojis(root.emojis, root.query);
    }

    function clampSelectedIndex(count): void {
        if (count <= 0)
            root.selectedIndex = -1;
        else if (root.selectedIndex < 0)
            root.selectedIndex = 0;
        else if (root.selectedIndex >= count)
            root.selectedIndex = count - 1;
    }
}
