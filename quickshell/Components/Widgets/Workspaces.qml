import Quickshell.Hyprland
import QtQuick
import "../../" as App

Row {
    id: workspaces
    spacing: 6
    height: 20
    leftPadding: 4
    rightPadding: 4

    Repeater {
        model: {
            const ws = Hyprland.workspaces.values
            const arr = []
            for (let i = 0; i < ws.length; i++) arr.push(ws[i])
            arr.sort((a, b) => a.id - b.id)
            return arr
        }

        Rectangle {
            id: wsItem
            required property var modelData

            property bool active: Hyprland.focusedWorkspace?.id === modelData.id
            property bool hovered: wsMouseArea.containsMouse

            height: 14
            width: active ? 32 : 14
            radius: 7
            color: active ? App.Constants.primary : (hovered ? Qt.rgba(1, 1, 1, 0.15) : App.Constants.light)
            scale: active ? 1.1 : (hovered ? 1.05 : 1.0)
            opacity: active ? 1.0 : (hovered ? 0.9 : 1.0)

            Behavior on width {
                NumberAnimation {
                    duration: App.Constants.animationFast
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: App.Constants.animationFast
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on color {
                ColorAnimation { duration: App.Constants.animationFast }
            }

            Behavior on opacity {
                NumberAnimation { duration: App.Constants.animationFast }
            }

            Text {
                anchors.fill: parent
                text: wsItem.modelData.id
                color: App.Constants.light
                opacity: wsItem.active ? 1 : 0
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 10
                font.family: App.Constants.fontFamily

                Behavior on opacity {
                    NumberAnimation { duration: App.Constants.animationNormal }
                }
            }

            MouseArea {
                id: wsMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + wsItem.modelData.id)
            }
        }
    }
}
