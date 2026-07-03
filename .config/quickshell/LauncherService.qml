pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
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

    readonly property bool visible: mode !== root.modeClosed

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

    function openApps(): void {
        root.mode = root.modeApps;
        root.query = "";
        root.selectedIndex = 0;
        root.menuWaiting = false;
    }

    function openEmoji(): void {
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
        root.title = title;
        root.menuOptions = options;
        root.query = "";
        root.selectedIndex = 0;
        root.menuSearchable = searchable === true;
        root.mode = root.modeMenu;
        root.menuWaiting = true;
    }

    function openPassword(prompt): void {
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

    function filteredApps(): var {
        const all = [...DesktopEntries.applications.values];
        const q = root.query.trim().toLowerCase();
        if (q === "")
            return all;

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
