import Quickshell
import QtQuick
import QtQuick.Layouts
import "Widgets"
import "../" as App

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    // Reserve exactly the original bar height — curved corners bleed below
    implicitHeight: App.Constants.barHeight
    // Transparent so rounded corners show through to wallpaper
    color: "transparent"

    readonly property int barRadius: 12

    // ── Drop shadow behind bar body ────────────────────────────────────────
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 6
            leftMargin: 8
            rightMargin: 8
        }
        height: App.Constants.barHeight
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: bar.barRadius + 3
        bottomRightRadius: bar.barRadius + 3
        color: Qt.rgba(0, 0, 0, 0.50)
        layer.enabled: true
        z: 0
    }

    // ── Bar body with curved bottom corners ────────────────────────────────
    Rectangle {
        id: barBody
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        // Extend below the window so top corners are sharp,
        // and the bottom arc overflows into compositor (shows wallpaper)
        height: App.Constants.barHeight + bar.barRadius

        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: bar.barRadius
        bottomRightRadius: bar.barRadius

        color: App.Constants.background
        z: 1

        // Curved border — left + bottom arc + right, no top line
        Rectangle {
            anchors.fill: parent
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: bar.barRadius
            bottomRightRadius: bar.barRadius
            color: "transparent"
            border.width: 1
            border.color: App.Constants.barBorder

            // Mask the top border segment
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: App.Constants.background
            }
        }
    }

    // ── All content — constrained to original barHeight ───────────────────
    Item {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: App.Constants.barHeight
        z: 2

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 8
                rightMargin: 8
                topMargin: 4
                bottomMargin: 4
            }
            spacing: 0

            // ── LEFT ─────────────────────────────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: 6

                Rectangle {
                    width: App.Constants.normalWidth
                    height: App.Constants.normalWidth
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰣇"
                        color: App.Constants.primary
                        font.pixelSize: 14
                        font.family: App.Constants.fontFamily
                    }
                }

                Rectangle { width: 1; height: 14; color: App.Constants.secondary; opacity: 0.35 }

                Workspaces {
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle { width: 1; height: 14; color: App.Constants.secondary; opacity: 0.35 }

                ActiveWindow {
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Item { Layout.fillWidth: true }

            // ── CENTER spacer ─────────────────────────────────────────────────
            Item { Layout.fillWidth: true }

            // ── RIGHT — grouped pill containers ──────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 4

                // ── Network + Bluetooth pill ──────────────────────────────────
                Rectangle {
                    implicitHeight: 24
                    implicitWidth: netBtRow.implicitWidth + 16
                    radius: 6
                    color: App.Constants.surfaceMuted
                    border.width: 1
                    border.color: App.Constants.cardBorder

                    Row {
                        id: netBtRow
                        anchors.centerIn: parent
                        spacing: 6

                        Network { anchors.verticalCenter: parent.verticalCenter }

                        Rectangle {
                            width: 1; height: 12
                            color: App.Constants.secondary; opacity: 0.3
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Bluetooth { anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // ── Battery + Volume pill ─────────────────────────────────────
                Rectangle {
                    implicitHeight: 24
                    implicitWidth: batVolRow.implicitWidth + 16
                    radius: 6
                    color: App.Constants.surfaceMuted
                    border.width: 1
                    border.color: App.Constants.cardBorder

                    Row {
                        id: batVolRow
                        anchors.centerIn: parent
                        spacing: 6

                        Battery { anchors.verticalCenter: parent.verticalCenter }

                        Rectangle {
                            width: 1; height: 12
                            color: App.Constants.secondary; opacity: 0.3
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Volume { anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // ── Tray + Notification pill (when tray has items) ────────────
                Rectangle {
                    implicitHeight: 24
                    implicitWidth: trayNotifRow.implicitWidth + 10
                    radius: 6
                    color: App.Constants.surfaceMuted
                    border.width: 1
                    border.color: App.Constants.cardBorder
                    visible: trayWidget.hasTrayItems

                    Row {
                        id: trayNotifRow
                        anchors.centerIn: parent
                        spacing: 6

                        Tray {
                            id: trayWidget
                            anchors.verticalCenter: parent.verticalCenter
                            barWindow: bar
                        }

                        Rectangle {
                            width: 1; height: 12
                            color: App.Constants.secondary; opacity: 0.3
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        NotificationIndicator {
                            id: notifIndicator
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // ── Notification-only pill (no tray items) ────────────────────
                // Uses a Loader so only one NotificationIndicator is ever live.
                Rectangle {
                    id: notifOnlyPill
                    implicitHeight: 24
                    implicitWidth: (notifOnlyLoader.item ? notifOnlyLoader.item.implicitWidth : 0) + 10
                    radius: 6
                    color: App.Constants.surfaceMuted
                    border.width: 1
                    border.color: App.Constants.cardBorder
                    visible: !trayWidget.hasTrayItems

                    Loader {
                        id: notifOnlyLoader
                        anchors.centerIn: parent
                        active: !trayWidget.hasTrayItems
                        sourceComponent: NotificationIndicator {}
                    }
                }
            }
        }

        // ── CENTER CONTENT (absolute — prevents layout shift) ─────────────────
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            MediaPlayer { Layout.alignment: Qt.AlignVCenter }

            Rectangle { width: 1; height: 14; color: App.Constants.secondary; opacity: 0.35 }

            Clock { Layout.alignment: Qt.AlignVCenter }
        }
    }
}
