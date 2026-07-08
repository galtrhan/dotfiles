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
        bodyMarkupSupported: true
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

            const data = notifDataComp.createObject(root, {
                notification: notification,
                seqId: String(root._seqCounter++),
                timestamp: Date.now()
            });

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
}
