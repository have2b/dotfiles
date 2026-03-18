import QtQuick
import Quickshell
import "../../" as App

Rectangle {
    id: root
    height: 20
    color: "transparent"
    implicitWidth: bellRow.implicitWidth + 8

    property int notifCount: App.NotificationService.unreadCount

    Row {
        id: bellRow
        anchors.centerIn: parent
        spacing: 2

        Item {
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: bellIcon
                anchors.centerIn: parent
                text: root.notifCount > 0 ? "\udb80\ude5c" : "\udb80\ude5a" // 󰅜 / 󰅚
                color: root.notifCount > 0 ? App.Constants.accent : App.Constants.light
                font.pixelSize: App.Constants.iconSize
                font.family: App.Constants.fontFamily

                Behavior on color {
                    ColorAnimation { duration: App.Constants.animationNormal }
                }

                // Subtle bounce on new notification
                scale: 1.0
                SequentialAnimation on scale {
                    id: bounceAnim
                    running: false
                    NumberAnimation { to: 1.2; duration: 100; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 1.0; duration: 150; easing.type: Easing.InOutQuad }
                }
            }

            // Unread count badge
            Rectangle {
                visible: root.notifCount > 0
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -2
                anchors.rightMargin: -2
                width: Math.max(12, badgeText.implicitWidth + 4)
                height: 12
                radius: 6
                color: App.Constants.error

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.notifCount > 9 ? "9+" : root.notifCount
                    color: App.Constants.light
                    font.pixelSize: 7
                    font.bold: true
                    font.family: App.Constants.fontFamily
                }
            }
        }
    }

    // Trigger bounce animation on count increase
    onNotifCountChanged: {
        if (notifCount > 0) bounceAnim.running = true
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            // Close the other panels before toggling this one
            App.NetworkService.closePanel()
            App.BluetoothService.closePanel()
            App.NotificationService.togglePanel()
        }
    }
}
