import QtQuick
import Quickshell.Services.Notifications
import ".."

QtObject {
    id: notificationData

    property Notification notification: null
    property bool closed: false
    property bool archived: false
    property bool popupVisible: false

    property string seqId: ""
    property string notifId: ""
    property string summary: ""
    property string body: ""
    property string appIcon: ""
    property string appName: ""
    property string image: ""
    property var actions: []
    property int urgency: NotificationUrgency.Normal
    property real expireTimeout: defaultTimeout
    property int progress: -1
    property int timestamp: Date.now()

    property bool hovered: false
    property int timerGeneration: 0

    readonly property int defaultTimeout: {
        if (urgency === NotificationUrgency.Critical)
            return Theme.notifTimeoutCritical;
        if (urgency === NotificationUrgency.Low)
            return Theme.notifTimeoutLow;
        return Theme.notifTimeoutNormal;
    }

    readonly property int effectiveTimeout: {
        if (expireTimeout > 0)
            return expireTimeout;
        return defaultTimeout;
    }

    readonly property bool hasProgress: progress >= 0 && progress <= 100
    readonly property bool isOsd: NotificationService.osdApps.indexOf(appName) !== -1
    readonly property bool isPopupOnly: NotificationService.isHistoryExcludedFromData(notificationData)

    readonly property Connections _conn: Connections {
        target: notificationData.notification

        function onClosed(): void {
            if (notificationData.closed || notificationData.archived)
                return;

            NotificationService._removeFromPopups(notificationData);

            if (notificationData.isPopupOnly) {
                notificationData.closed = true;
                NotificationService._removeFromHistory(notificationData);
                notificationData.notification = null;
                notificationData.destroy();
                return;
            }

            notificationData.archived = true;
            notificationData.popupVisible = false;
            notificationData.actions = [];
            notificationData.notification = null;
        }

        function onSummaryChanged(): void {
            if (notificationData.notification)
                notificationData.summary = notificationData.notification.summary || "";
        }

        function onBodyChanged(): void {
            if (notificationData.notification)
                notificationData.body = notificationData.notification.body || "";
        }

        function onAppIconChanged(): void {
            if (notificationData.notification)
                notificationData.appIcon = notificationData.notification.appIcon || "";
        }

        function onAppNameChanged(): void {
            if (notificationData.notification)
                notificationData.appName = notificationData.notification.appName || "";
        }

        function onImageChanged(): void {
            if (notificationData.notification)
                notificationData.image = notificationData.notification.image || "";
        }

        function onUrgencyChanged(): void {
            if (notificationData.notification)
                notificationData.urgency = notificationData.notification.urgency;
        }

        function onExpireTimeoutChanged(): void {
            if (notificationData.notification)
                notificationData.expireTimeout = notificationData.notification.expireTimeout;
        }

        function onActionsChanged(): void {
            if (!notificationData.notification)
                return;
            notificationData.actions = notificationData.notification.actions.map(function (a) {
                return { identifier: a.identifier, text: a.text };
            });
        }

        function onHintsChanged(): void {
            if (notificationData.notification)
                notificationData.progress = NotificationService.parseProgress(notificationData.notification.hints);
        }
    }

    readonly property Timer _timer: Timer {
        id: popupTimer
        running: !notificationData.closed
                 && !notificationData.archived
                 && notificationData.popupVisible
                 && !notificationData.hovered
                 && notificationData.urgency !== NotificationUrgency.Critical
                 && notificationData.effectiveTimeout > 0
        interval: notificationData.effectiveTimeout
        onTriggered: notificationData.expirePopup()
    }

    function syncFrom(notification): void {
        if (!notification)
            return;

        notifId = String(notification.id || "");
        summary = notification.summary || "";
        body = notification.body || "";
        appIcon = notification.appIcon || "";
        appName = notification.appName || "";
        image = notification.image || "";
        urgency = notification.urgency;
        progress = NotificationService.parseProgress(notification.hints);

        const rawTimeout = notification.expireTimeout;
        expireTimeout = rawTimeout > 0 ? rawTimeout : defaultTimeout;
        actions = notification.actions.map(function (a) {
            return { identifier: a.identifier, text: a.text };
        });
        timestamp = Date.now();
        timerGeneration += 1;
        popupTimer.restart();
    }

    function rebind(notification): void {
        notification.tracked = true;
        notificationData.notification = notification;
        syncFrom(notification);
    }

    Component.onCompleted: {
        if (!notification)
            return;
        syncFrom(notification);
    }

    function removePopup(): void {
        if (closed)
            return;
        popupVisible = false;
        NotificationService._removeFromPopups(this);
    }

    function dismiss(): void {
        if (closed)
            return;
        closed = true;
        NotificationService._removeFromPopups(this);
        NotificationService._removeFromHistory(this);
        if (notification) {
            try {
                notification.dismiss();
            } catch (e) {}
        }
        destroy();
    }

    function expirePopup(): void {
        if (closed || archived)
            return;
        popupVisible = false;
        NotificationService._removeFromPopups(this);
        if (!isPopupOnly)
            return;
        closed = true;
        NotificationService._removeFromHistory(this);
        if (notification) {
            try {
                notification.expire();
            } catch (e) {}
            notification = null;
        }
        destroy();
    }

    function invokeAction(identifier): void {
        if (!identifier || closed)
            return;
        closed = true;
        NotificationService._removeFromPopups(this);
        NotificationService._removeFromHistory(this);
        if (notification) {
            const action = notification.actions.find(function (a) {
                return a.identifier === identifier;
            });
            if (action) {
                try {
                    action.invoke();
                } catch (e) {}
            }
        }
        destroy();
    }
}
