import QtQuick
import Quickshell
import "../../" as App

// Minimal notification indicator:
//   - Bell icon always shown
//   - When unread: bell turns accent color + a small colored dot appears below
//   - Background / hover styling is handled by the pill wrapper in Bar.qml
Item {
    id: root
    implicitWidth: 20
    implicitHeight: 20

    property int notifCount: App.NotificationService.unreadCount
    readonly property bool hasUnread: notifCount > 0

    // Expose hover state so the parent pill can react to it
    readonly property bool hovered: notifMouse.containsMouse

    // Bell icon
    Text {
        id: bellIcon
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.hasUnread ? -2 : 0
        text:  root.hasUnread ? "\udb80\ude5c" : "\udb80\ude5a"   // 󰅜 / 󰅚
        color: root.hasUnread ? App.Constants.accent : App.Constants.textDim
        font.pixelSize: App.Constants.iconSize
        font.family: App.Constants.fontFamily

        Behavior on color { ColorAnimation { duration: App.Constants.animationNormal } }
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation { duration: App.Constants.animationFast; easing.type: Easing.OutQuad }
        }

        // Bounce on new notification
        scale: 1.0
        SequentialAnimation on scale {
            id: bounceAnim
            running: false
            NumberAnimation { to: 1.25; duration: 100; easing.type: Easing.OutQuad }
            NumberAnimation { to: 1.0;  duration: 150; easing.type: Easing.InOutQuad }
        }
    }

    // Unread dot — small, centered below bell
    Rectangle {
        id: unreadDot
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        width: root.hasUnread ? (root.notifCount > 1 ? 14 : 5) : 0
        height: 5
        radius: 3
        color: App.Constants.error

        Behavior on width {
            NumberAnimation { duration: App.Constants.animationFast; easing.type: Easing.OutQuad }
        }

        // Count label — only shown when > 1 unread
        Text {
            anchors.centerIn: parent
            text: root.notifCount > 9 ? "9+" : root.notifCount
            color: App.Constants.light
            font.pixelSize: 7
            font.bold: true
            font.family: App.Constants.fontFamily
            visible: root.notifCount > 1
            opacity: root.notifCount > 1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: App.Constants.animationFast } }
        }
    }

    onNotifCountChanged: {
        if (notifCount > 0) bounceAnim.running = true
    }

    MouseArea {
        id: notifMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            App.NetworkService.closePanel()
            App.BluetoothService.closePanel()
            App.NotificationService.togglePanel()
        }
    }
}
