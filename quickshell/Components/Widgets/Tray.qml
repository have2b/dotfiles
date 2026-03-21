import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../" as App

// System tray widget — shows StatusNotifierItem icons (fcitx5, etc.)
// barWindow must be set to the containing PanelWindow so menus anchor correctly.
Item {
    id: root

    property var barWindow

    // Collapse to zero width when no visible (non-fcitx) tray items are registered
    readonly property bool hasTrayItems: {
        const vals = SystemTray.items.values
        for (let i = 0; i < vals.length; i++) {
            if (!(vals[i].id ?? "").toLowerCase().includes("fcitx")) return true
        }
        return false
    }

    implicitWidth: trayRow.implicitWidth
    implicitHeight: App.Constants.barHeight

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayIcon
                required property var modelData

                readonly property var item: trayIcon.modelData

                // Hide fcitx5 — it has its own dedicated Keyboard.qml widget in the bar
                readonly property bool isFcitx: (item.id ?? "").toLowerCase().includes("fcitx")

                Layout.alignment: Qt.AlignVCenter
                implicitWidth:  isFcitx ? 0 : 16
                implicitHeight: isFcitx ? 0 : 16
                visible: !isFcitx

                // ── Hover background ─────────────────────────────────────────
                Rectangle {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    radius: 4
                    color: App.Constants.surfaceHover
                    opacity: iconMouse.containsMouse ? 0.9 : 0
                    z: -1
                    Behavior on opacity {
                        NumberAnimation { duration: App.Constants.animationFast }
                    }
                }

                // ── Tray icon ────────────────────────────────────────────────
                Image {
                    anchors.fill: parent
                    source: trayIcon.item.icon
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    sourceSize.width: 16
                    sourceSize.height: 16
                }

                // ── Context menu anchor (right-click / onlyMenu items) ───────
                QsMenuAnchor {
                    id: menuAnchor
                    menu: trayIcon.item.menu
                    anchor.window: root.barWindow
                    anchor.rect.x: trayIcon.mapToItem(null, 0, 0).x
                    anchor.rect.y: App.Constants.barHeight
                    anchor.rect.width: trayIcon.width
                    anchor.rect.height: 0
                }

                // ── Tooltip ──────────────────────────────────────────────────
                ToolTip {
                    id: iconTooltip
                    visible: iconMouse.containsMouse && text !== ""
                    delay: 600
                    timeout: 4000
                    text: {
                        const tt = trayIcon.item.tooltip
                        if (tt && tt.title && tt.title !== "") return tt.title
                        return trayIcon.item.id ?? ""
                    }
                }

                // ── Mouse handling ───────────────────────────────────────────
                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: mouse => {
                        const it = trayIcon.item
                        if (mouse.button === Qt.RightButton) {
                            if (it.hasMenu) menuAnchor.open()
                        } else if (mouse.button === Qt.MiddleButton) {
                            it.secondaryActivate()
                        } else {
                            // Left click: show menu if the item declares onlyMenu,
                            // otherwise call the primary activate action.
                            if (it.onlyMenu && it.hasMenu)
                                menuAnchor.open()
                            else
                                it.activate()
                        }
                    }

                    onWheel: wheel => {
                        trayIcon.item.scroll(
                            wheel.angleDelta.y / 120,
                            wheel.angleDelta.x !== 0
                        )
                    }
                }
            }
        }
    }
}
