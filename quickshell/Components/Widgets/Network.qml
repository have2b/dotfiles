import QtQuick
import Quickshell
import "../../" as App

Rectangle {
    id: root
    height:        26
    radius:        12
    implicitWidth: netRow.implicitWidth + 20

    property string connectionType: App.NetworkService.connectionType
    property string ssid:           App.NetworkService.ssid
    property int    signalStrength: App.NetworkService.signalStrength
    property bool   connected:      App.NetworkService.connected

    property string networkIcon: {
        if (connectionType === "ethernet") return ""    // nf-md-ethernet
        if (connectionType === "wifi") {
            if (signalStrength > 75) return "󰤨"         // strength_4
            if (signalStrength > 50) return "󰤥"         // strength_3
            if (signalStrength > 25) return "󰤢"         // strength_2
            return "󰤟"                                   // strength_1
        }
        return "󰤮"                                       // wifi_off
    }

    // #8aadf4 (blue) when connected; surface0 (#363a4f) when not
    color: connected ? App.Constants.primary : App.Constants.surface

    border.width: 1
    border.color: connected
        ? Qt.rgba(138 / 255, 173 / 255, 244 / 255, 0.25)
        : Qt.rgba(202 / 255, 211 / 255, 245 / 255, 0.08)

    Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

    Row {
        id: netRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text:           root.networkIcon
            color:          root.connected ? App.Constants.mantle : App.Constants.textDim
            font.pixelSize: App.Constants.iconSize
            font.family:    App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: App.Constants.animationNormal } }
        }

        Text {
            text:    root.ssid
            visible: root.connected && text !== ""
            color:   root.connected ? App.Constants.mantle : App.Constants.light
            font.pixelSize: 10
            font.family:    App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 90)
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            App.BluetoothService.closePanel()
            App.NotificationService.closePanel()
            App.NetworkService.togglePanel()
        }
    }
}
