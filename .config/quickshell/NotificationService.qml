pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "notifications"

Singleton {
    id: root

    property list<var> popups: []
    property list<var> history: []
    property bool doNotDisturb: false
    property bool centerOpen: false
    property int unreadCount: 0
    property int _seqCounter: 0

    Component {
        id: notifDataComp
        NotificationData {}
    }

    readonly property var osdApps: ["Volume", "Brightness", "Keyboard", "Battery", "Wallpaper"]
    readonly property var historyExcludedApps: ["Volume", "Brightness", "Keyboard"]
    readonly property var badgeExcludedApps: ["blueman", "NetworkManager Applet"]
    readonly property var groupedApps: ["blueman", "NetworkManager Applet"]
    property var expandedGroups: ({})

    function isGroupedApp(appName): bool {
        return root.groupedApps.indexOf(appName || "") !== -1;
    }

    function groupItems(appName): var {
        return root.history.filter(function (n) {
            return !n.closed && (n.appName || "") === appName;
        });
    }

    function isGroupRepresentative(notifData): bool {
        if (!notifData || notifData.closed)
            return false;
        const app = notifData.appName || "";
        if (!root.isGroupedApp(app) || root.isGroupExpanded(app))
            return false;
        const items = root.groupItems(app);
        return items.length > 0 && items[0] === notifData;
    }

    function hasDisplayText(notifData): bool {
        if (!notifData)
            return false;
        return (notifData.appName || "").length > 0
            || (notifData.summary || "").length > 0
            || (notifData.body || "").length > 0;
    }

    function isCenterEntryVisible(notifData): bool {
        if (!notifData || notifData.closed || !root.hasDisplayText(notifData))
            return false;
        const app = notifData.appName || "";
        if (!root.isGroupedApp(app) || root.isGroupExpanded(app))
            return true;
        return root.isGroupRepresentative(notifData);
    }

    function isHistoryExcluded(notification): bool {
        const app = notification.appName || "";
        return root.historyExcludedApps.indexOf(app) !== -1;
    }

    function isBadgeExcluded(notification): bool {
        const app = notification.appName || "";
        return root.badgeExcludedApps.indexOf(app) !== -1;
    }

    function isBatteryMeltdown(notification): bool {
        const app = notification.appName || "";
        if (app !== "Battery")
            return false;
        return (notification.summary || "").startsWith("REACTOR");
    }

    function isPersistent(notification): bool {
        const app = notification.appName || "";
        if (app !== "Battery")
            return false;
        const summary = (notification.summary || "").trim();
        return summary === "Battery Low" || summary === "Battery Critical";
    }

    function isPersistentFromData(notifData): bool {
        if (!notifData)
            return false;
        const app = notifData.appName || "";
        if (app !== "Battery")
            return false;
        const summary = (notifData.summary || "").trim();
        return summary === "Battery Low" || summary === "Battery Critical";
    }

    function isHistoryExcludedFromData(notifData): bool {
        const app = notifData.appName || "";
        return root.historyExcludedApps.indexOf(app) !== -1;
    }

    function volumeGroupKey(summary): string {
        const text = (summary || "").trim();
        if (text.startsWith("Mic-Level") || text.startsWith("Microphone"))
            return "mic";
        if (text.startsWith("Volume"))
            return "sink";
        return text.split(":")[0].trim();
    }

    function osdGroupKey(notification): string {
        const app = notification.appName || "";
        if (root.osdApps.indexOf(app) === -1)
            return "";

        if (app === "Volume")
            return app + "|" + root.volumeGroupKey(notification.summary);

        const summary = notification.summary || "";
        const prefix = summary.split(":")[0].trim();
        return app + "|" + prefix;
    }

    function osdGroupKeyFromData(notifData): string {
        const app = notifData.appName || "";
        if (root.osdApps.indexOf(app) === -1)
            return "";

        if (app === "Volume")
            return app + "|" + root.volumeGroupKey(notifData.summary);

        const summary = notifData.summary || "";
        const prefix = summary.split(":")[0].trim();
        return app + "|" + prefix;
    }

    function findExistingEntry(notification): var {
        const idStr = String(notification.id || "");
        if (idStr !== "") {
            const byId = root.popups.find(function (n) {
                return n.notifId === idStr && !n.closed && !n.archived;
            }) || root.history.find(function (n) {
                return n.notifId === idStr && !n.closed && !n.archived;
            });
            if (byId)
                return byId;
        }

        const groupKey = root.osdGroupKey(notification);
        if (groupKey === "")
            return null;

        return root.popups.find(function (n) {
            return !n.closed && !n.archived && root.osdGroupKeyFromData(n) === groupKey;
        }) || root.history.find(function (n) {
            return !n.closed && !n.archived && root.osdGroupKeyFromData(n) === groupKey;
        });
    }

    function _promotePopup(notifData): void {
        notifData.popupVisible = true;
        root.popups = [notifData, ...root.popups.filter(function (n) {
            return n !== notifData;
        })];
    }

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        persistenceSupported: true
        keepOnReload: false

        onNotification: function (notification) {
            if (!notification.appName && !notification.summary
                && !notification.body && !notification.image && !notification.appIcon)
                return;

            notification.tracked = true;

            const meltdown = root.isBatteryMeltdown(notification);
            if (meltdown) {
                const cap = root.parseProgress(notification.hints);
                BatteryMeltdownService.activate(cap);
            }

            const saveToHistory = !root.isHistoryExcluded(notification);
            const existing = root.findExistingEntry(notification);
            if (existing) {
                existing.rebind(notification);
                if (saveToHistory) {
                    root.history = [existing, ...root.history.filter(function (n) {
                        return n !== existing;
                    })];
                } else {
                    root._removeFromHistory(existing);
                }
                if (!root.doNotDisturb && !meltdown)
                    root._promotePopup(existing);
                return;
            }

            const data = notifDataComp.createObject(root, Object.assign({
                seqId: String(root._seqCounter++),
                timestamp: Date.now()
            }, root.snapshotNotification(notification)));
            data.syncFrom(notification);

            if (saveToHistory) {
                root.history = [data, ...root.history];
                if (root.history.length > Theme.notifMaxHistory) {
                    const removed = root.history.pop();
                    if (removed && !removed.closed)
                        removed.destroy();
                }
            }

            if (!root.doNotDisturb && !meltdown) {
                data.popupVisible = true;
                root._promotePopup(data);
                if (root.popups.length > Theme.notifMaxPopups) {
                    const oldest = root.popups.pop();
                    if (oldest)
                        oldest.popupVisible = false;
                }
            }

            if (!root.centerOpen && saveToHistory && !root.isBadgeExcluded(notification))
                root.unreadCount += 1;
        }
    }

    function snapshotNotification(notification): object {
        const rawTimeout = notification.expireTimeout;
        let expireTimeout = rawTimeout;
        if (expireTimeout <= 0) {
            if (notification.urgency === NotificationUrgency.Critical)
                expireTimeout = Theme.notifTimeoutCritical;
            else if (notification.urgency === NotificationUrgency.Low)
                expireTimeout = Theme.notifTimeoutLow;
            else
                expireTimeout = Theme.notifTimeoutNormal;
        }

        return {
            notification: notification,
            notifId: String(notification.id || ""),
            summary: notification.summary || "",
            body: root.stripMarkup(notification.body || ""),
            appIcon: notification.appIcon || "",
            appName: notification.appName || "",
            image: notification.image || "",
            urgency: notification.urgency,
            expireTimeout: expireTimeout
        };
    }

    function stripMarkup(text): string {
        if (!text)
            return "";
        return String(text)
            .replace(/<[^>]+>/g, "")
            .replace(/&nbsp;/g, " ")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"")
            .replace(/&amp;/g, "&")
            .trim();
    }

    function parseProgress(hints): int {
        if (!hints)
            return -1;

        const value = hints.value;
        if (value === undefined || value === null)
            return -1;

        const parsed = Number(value);
        if (Number.isNaN(parsed))
            return -1;

        return Math.max(0, Math.min(100, Math.round(parsed)));
    }

    function _removeFromPopups(notifData): void {
        notifData.popupVisible = false;
        root.popups = root.popups.filter(function (n) {
            return n !== notifData;
        });
    }

    function _removeFromHistory(notifData): void {
        root.history = root.history.filter(function (n) {
            return n !== notifData;
        });
    }

    function dismiss(notifData): void {
        if (notifData)
            notifData.dismiss();
    }

    function dismissPopups(): void {
        const active = [...root.popups];
        for (const n of active) {
            if (!n.closed)
                n.dismiss();
        }
    }

    function dismissAll(): void {
        const active = [...root.history];
        root.popups = [];
        root.history = [];
        for (const n of active) {
            if (!n.closed) {
                n.closed = true;
                if (n.notification) {
                    try {
                        n.notification.dismiss();
                    } catch (e) {}
                }
                n.destroy();
            }
        }
        root.unreadCount = 0;
    }

    function toggleCenter(): void {
        root.centerOpen = !root.centerOpen;
        if (root.centerOpen)
            markAllRead();
    }

    function markAllRead(): void {
        root.unreadCount = 0;
    }

    function toggleDnd(): void {
        root.doNotDisturb = !root.doNotDisturb;
    }

    function toggleGroupExpanded(appName): void {
        const next = Object.assign({}, root.expandedGroups);
        next[appName] = !(next[appName] || false);
        root.expandedGroups = next;
    }

    function isGroupExpanded(appName): bool {
        return root.expandedGroups[appName] || false;
    }

    function dismissGroup(appName): void {
        const items = root.history.filter(function (n) {
            return !n.closed && (n.appName || "") === appName;
        });
        for (const n of items)
            n.dismiss();

        const next = Object.assign({}, root.expandedGroups);
        delete next[appName];
        root.expandedGroups = next;
    }
}
