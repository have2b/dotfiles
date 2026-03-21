import Quickshell.Hyprland
import QtQuick
import "../../" as App

Row {
    id: workspaces
    spacing: 4
    height: 22
    leftPadding:  2
    rightPadding: 2

    Repeater {
        model: {
            const ws  = Hyprland.workspaces.values
            const arr = []
            for (let i = 0; i < ws.length; i++) arr.push(ws[i])
            arr.sort((a, b) => a.id - b.id)
            return arr
        }

        Item {
            id: wsWrapper
            required property var modelData

            property bool active:  Hyprland.focusedWorkspace?.id === modelData.id
            property bool hovered: wsMouseArea.containsMouse

            // Extra horizontal space lets the glow bleed at the sides
            width:  wsItem.width + 8
            height: workspaces.height

            // ── Soft glow behind active pill ─────────────────────────────────
            Rectangle {
                anchors.centerIn: wsItem
                width:   wsItem.width + 4
                height:  wsItem.height + 4
                radius:  (wsItem.height + 4) / 2
                color:   App.Constants.accent
                opacity: wsWrapper.active ? 0.30 : 0
                visible: wsWrapper.active
                layer.enabled: true

                Behavior on opacity {
                    NumberAnimation { duration: App.Constants.animationFast }
                }
            }

            // ── Pill ─────────────────────────────────────────────────────────
            Rectangle {
                id: wsItem
                anchors.centerIn: parent

                height: 22
                // Active workspace gets a slightly wider pill so the number breathes
                width:  active ? 30 : 24
                radius: height / 2

                // Active → mauve accent  |  Hover → surface1  |  Idle → surface0
                color: active  ? App.Constants.accent
                     : hovered ? App.Constants.surface1
                     :           App.Constants.surface

                scale: active ? 1.0 : (hovered ? 1.05 : 1.0)

                Behavior on width  { NumberAnimation { duration: App.Constants.animationFast; easing.type: Easing.InOutQuad } }
                Behavior on scale  { NumberAnimation { duration: App.Constants.animationFast; easing.type: Easing.OutQuad  } }
                Behavior on color  { ColorAnimation  { duration: App.Constants.animationFast } }

                // Workspace number
                Text {
                    anchors.fill:               parent
                    text:                       wsWrapper.modelData.id
                    // Dark text on mauve, dimmed light text on surface pills
                    color:                      wsWrapper.active
                                                    ? App.Constants.mantle
                                                    : Qt.rgba(202 / 255, 211 / 255, 245 / 255, 0.65)
                    horizontalAlignment:        Text.AlignHCenter
                    verticalAlignment:          Text.AlignVCenter
                    font.pixelSize:             10
                    font.weight:                wsWrapper.active ? Font.SemiBold : Font.Normal
                    font.family:                App.Constants.fontFamily

                    Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
                }
            }

            MouseArea {
                id:           wsMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    Hyprland.dispatch("workspace " + wsWrapper.modelData.id)
            }
        }
    }
}
