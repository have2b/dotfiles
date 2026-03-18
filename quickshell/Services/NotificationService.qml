pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    property var server: NotificationServer {
        id: notifServer
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true
        }
    }

    readonly property var notifications: notifServer.trackedNotifications
    readonly property int count: notifications ? notifications.values.length : 0

    // Track which notifications have been "seen" (panel was opened)
    property int _lastSeenCount: 0
    readonly property int unreadCount: Math.max(0, count - _lastSeenCount)

    function markAllRead() {
        _lastSeenCount = count
    }

    function dismiss(notification) {
        if (notification) {
            notification.dismiss()
            // Keep _lastSeenCount consistent: if it now exceeds the remaining
            // count, clamp it down so the unread badge stays accurate.
            if (_lastSeenCount > count - 1)
                _lastSeenCount = Math.max(0, count - 1)
        }
    }

    function dismissAll() {
        if (!notifications) return
        const list = notifications.values
        for (let i = list.length - 1; i >= 0; i--) {
            list[i].dismiss()
        }
        _lastSeenCount = 0
    }

    // Panel visibility state
    property bool panelVisible: false

    function togglePanel() {
        panelVisible = !panelVisible
        if (panelVisible) markAllRead()
    }

    function closePanel() {
        panelVisible = false
    }
}
