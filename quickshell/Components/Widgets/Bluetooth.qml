import QtQuick
import Quickshell
import "../../" as App

Rectangle {
    id: root
    height:        26
    radius:        12
    implicitWidth: btRow.implicitWidth + 20

    property bool powered:        App.BluetoothService.powered
    property int  connectedCount: App.BluetoothService.connectedCount
    property bool hasConnected:   App.BluetoothService.hasConnected

    readonly property var firstConnectedDevice: {
        const devs = App.BluetoothService.devices
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].connected) return devs[i]
        }
        return null
    }

    property string btIcon: {
        if (!powered)     return "\udb80\udcb2"    // 󰂲 bluetooth_off
        if (hasConnected) return "\udb80\udcb1"    // 󰂱 bluetooth_connect
        return "\udb80\udcaf"                       // 󰂯 bluetooth
    }

    // #c6a0f6 (mauve) when connected; surface0 (#363a4f) when not
    color: hasConnected ? App.Constants.accent : App.Constants.surface

    border.width: 1
    border.color: hasConnected
        ? Qt.rgba(198 / 255, 160 / 255, 246 / 255, 0.30)
        : Qt.rgba(202 / 255, 211 / 255, 245 / 255, 0.08)

    Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

    Row {
        id: btRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text:           root.btIcon
            // Dark crust text on mauve; light text when idle
            color:          root.hasConnected ? App.Constants.mantle : App.Constants.textDim
            font.pixelSize: App.Constants.iconSize
            font.family:    App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id:      deviceNameLabel
            visible: root.firstConnectedDevice !== null
            text:    root.firstConnectedDevice ? root.firstConnectedDevice.name : ""
            color:   root.hasConnected ? App.Constants.mantle : App.Constants.light
            font.pixelSize: 10
            font.family:    App.Constants.fontFamily
            width:  Math.min(implicitWidth, 80)
            elide:  Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }

        // ✕ disconnect button
        Rectangle {
            id:      disconnectBtn
            visible: root.firstConnectedDevice !== null
            width: 14; height: 14; radius: 7
            color: disconnectArea.containsMouse
                ? Qt.rgba(237 / 255, 135 / 255, 150 / 255, 0.50)
                : Qt.rgba(24  / 255,  25 / 255,  38 / 255, 0.40)
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

            Text {
                anchors.centerIn: parent
                text:  "✕"
                color: disconnectArea.containsMouse ? App.Constants.error : App.Constants.mantle
                font.pixelSize: 7
                font.bold:      true
                font.family:    App.Constants.fontFamily
                Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
            }

            MouseArea {
                id:           disconnectArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked: mouse => {
                    mouse.accepted = true
                    if (root.firstConnectedDevice)
                        App.BluetoothService.disconnectDevice(root.firstConnectedDevice.mac)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            App.NetworkService.closePanel()
            App.NotificationService.closePanel()
            App.BluetoothService.togglePanel()
        }
    }
}
