import Quickshell
import QtQuick
import QtQuick.Layouts
import "Widgets"
import "../" as App

PanelWindow {
    id: bar
    anchors {
        top:   true
        left:  true
        right: true
    }

    // Reserve bar height + top margin so the compositor pushes windows down correctly
    implicitHeight: App.Constants.barHeight

    // Transparent — the pill Rectangle provides the visible background
    color: "transparent"

    // ── Floating Pill ─────────────────────────────────────────────────────────
    Rectangle {
        id: barPill

        anchors {
            top:         parent.top
            left:        parent.left
            right:       parent.right
        }

        height: App.Constants.barHeight   // 42 px
        radius: height / 2

        // No bar-level background — each component pill provides its own surface
        color: "transparent"
        border.width: 0

        // ── Left + Right via RowLayout ────────────────────────────────────────
        RowLayout {
            id: outerRow
            anchors {
                fill:          parent
                leftMargin:    12
                rightMargin:   12
            }
            spacing: 0

            // ── LEFT — every component wrapped in its own surface pill ────────
            RowLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: 5

                // ── Search pill ───────────────────────────────────────────────
                Rectangle {
                    height: 28; width: 28
                    radius: 8
                    color: searchArea.containsMouse ? App.Constants.surface1 : App.Constants.surface
                    border.width: 1
                    border.color: App.Constants.barBorder
                    Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

                    Text {
                        anchors.centerIn: parent
                        text:           "󰣇"   
                        color:          searchArea.containsMouse
                                            ? App.Constants.primary
                                            : App.Constants.sky
                        font.pixelSize: 12
                        font.family:    App.Constants.fontFamily
                        Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
                    }
                    MouseArea {
                        id: searchArea; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked:   App.AppLauncherService.toggle()
                    }
                }

                // ── Workspaces pill ───────────────────────────────────────────
                Rectangle {
                    height: 28
                    implicitWidth: wsWidget.implicitWidth + 6
                    radius: 8
                    color: App.Constants.surface
                    border.width: 1
                    border.color: App.Constants.barBorder

                    Workspaces {
                        id: wsWidget
                        anchors.centerIn: parent
                    }
                }

                // ── Active Window pill ────────────────────────────────────────
                Rectangle {
                    height: 28
                    implicitWidth: awWidget.implicitWidth + 10
                    radius: 8
                    color: App.Constants.surface
                    border.width: 1
                    border.color: App.Constants.barBorder
                    clip: true

                    ActiveWindow {
                        id: awWidget
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left:           parent.left
                        anchors.leftMargin:     5
                    }
                }
            }

            // Elastic spacers — push LEFT and RIGHT to their edges;
            // the CENTER is absolutely positioned inside barPill below.
            Item { Layout.fillWidth: true }
            Item { Layout.fillWidth: true }

            // ── RIGHT ─────────────────────────────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 8

                Tray {
                    id:           trayWidget
                    barWindow:    bar
                    Layout.alignment: Qt.AlignVCenter
                }

                Keyboard  { Layout.alignment: Qt.AlignVCenter }
                Network   { Layout.alignment: Qt.AlignVCenter }
                Bluetooth { Layout.alignment: Qt.AlignVCenter }
                Volume    { Layout.alignment: Qt.AlignVCenter }
                Battery   { Layout.alignment: Qt.AlignVCenter }

                // ── Notification pill ─────────────────────────────────────────
                Rectangle {
                    height: 28
                    implicitWidth: notifWidget.implicitWidth + 12
                    radius: 8
                    color: notifWidget.hovered ? App.Constants.surface1 : App.Constants.surface
                    border.width: 1
                    border.color: App.Constants.barBorder
                    Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

                    NotificationIndicator {
                        id: notifWidget
                        anchors.centerIn: parent
                    }
                }
            }
        }

        // ── CENTER — absolutely positioned so it never shifts with left/right content ──
        Rectangle {
            anchors.centerIn: parent
            height:       40
            implicitWidth: centerRow.implicitWidth + 24
            radius:        8
            color:         App.Constants.surface
            border.width:  1
            border.color:  App.Constants.barBorder

            RowLayout {
                id: centerRow
                anchors.centerIn: parent
                spacing: 10

                MediaPlayer { Layout.alignment: Qt.AlignVCenter }

                Rectangle {
                    width: 1; height: 16
                    color: App.Constants.separator
                    opacity: 0.6
                }

                Clock { Layout.alignment: Qt.AlignVCenter }
            }
        }
    }
}
