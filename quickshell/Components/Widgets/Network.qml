import QtQuick
import Quickshell
import "../../" as App

Rectangle {
    id: root
    height: 20
    color: "transparent"
    implicitWidth: netRow.implicitWidth + 20

    // State is provided by the NetworkService singleton
    property string connectionType: App.NetworkService.connectionType
    property string ssid: App.NetworkService.ssid
    property int signalStrength: App.NetworkService.signalStrength
    property bool connected: App.NetworkService.connected

    property string networkIcon: {
        if (connectionType === "ethernet") return ""   // 󰈀 nf-md-ethernet
        if (connectionType === "wifi") {
            if (signalStrength > 75) return "󰤨"        // nf-md-wifi_strength_4
            if (signalStrength > 50) return "󰤥"        // nf-md-wifi_strength_3
            if (signalStrength > 25) return "󰤢"        // nf-md-wifi_strength_2
            return "󰤟"                                  // nf-md-wifi_strength_1
        }
        return "󰤮"                                      // nf-md-wifi_off
    }

    // Hover highlight
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 6
        color: clickArea.containsMouse
            ? (App.NetworkService.panelVisible
                ? Qt.rgba(59/255, 130/255, 246/255, 0.15)
                : Qt.rgba(1, 1, 1, 0.06))
            : "transparent"
        Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
    }

    Row {
        id: netRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.networkIcon
            color: App.NetworkService.panelVisible
                ? App.Constants.primary
                : root.connected ? App.Constants.light : App.Constants.textDim
            font.pixelSize: App.Constants.iconSize
            font.family: App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: App.Constants.animationNormal }
            }
        }

        Text {
            text: root.ssid
            visible: root.connected && text !== ""
            color: App.NetworkService.panelVisible
                ? App.Constants.primary
                : App.Constants.textDim
            font.pixelSize: 10
            font.family: App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: App.Constants.animationNormal }
            }
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            // Close the other panel before toggling this one
            App.BluetoothService.closePanel()
            App.NotificationService.closePanel()
            App.NetworkService.togglePanel()
        }
    }
}
