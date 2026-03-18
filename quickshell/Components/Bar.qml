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
    implicitHeight: App.Constants.barHeight
    color: App.Constants.background

    RowLayout {
        anchors {
            fill: parent
            margins: 6
        }
        spacing: 0

        // ── LEFT ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            spacing: 8

            Rectangle {
                width: App.Constants.normalWidth
                height: App.Constants.normalWidth
                color: "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰣇"
                    color: App.Constants.accent
                    font.pixelSize: 14
                    font.family: App.Constants.fontFamily
                }
            }

            Rectangle { width: 1; height: 16; color: App.Constants.secondary; opacity: 0.4 }

            Workspaces {
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle { width: 1; height: 16; color: App.Constants.secondary; opacity: 0.4 }

            ActiveWindow {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Item { Layout.fillWidth: true }

        // ── CENTER ───────────────────────────────────────────────────────
        Item { Layout.fillWidth: true }

        // ── RIGHT ────────────────────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 8

            Network {
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle { width: 1; height: 16; color: App.Constants.secondary; opacity: 0.4 }

            Bluetooth {
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle { width: 1; height: 16; color: App.Constants.secondary; opacity: 0.4 }

            Battery {
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle { width: 1; height: 16; color: App.Constants.secondary; opacity: 0.4 }

            Volume {
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                width: 1; height: 16
                color: App.Constants.secondary; opacity: 0.4
                visible: trayWidget.hasTrayItems
            }

            // ── System tray (StatusNotifierItem — fcitx5, etc.) ──────────
            Tray {
                id: trayWidget
                Layout.alignment: Qt.AlignVCenter
                barWindow: bar
                visible: hasTrayItems
            }

            Rectangle {
                width: 1; height: 16
                color: App.Constants.secondary; opacity: 0.4
                visible: trayWidget.hasTrayItems
            }

            NotificationIndicator {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // ── CENTER CONTENT (Outside RowLayout to prevent shifting) ────────────
    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        MediaPlayer {
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle { width: 1; height: 16; color: App.Constants.secondary; opacity: 0.4 }

        Clock {
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // ── Bottom border ───────────────────────────────────────────────────────
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: App.Constants.barBorder
    }
}
