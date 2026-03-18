import QtQuick
import Quickshell
import "../../" as App

Rectangle {
    id: root
    height: 20
    color: "transparent"
    implicitWidth: btRow.implicitWidth + 8

    // State is provided by the BluetoothService singleton
    property bool powered: App.BluetoothService.powered
    property int connectedCount: App.BluetoothService.connectedCount
    property bool hasConnected: App.BluetoothService.hasConnected

    property string btIcon: {
        if (!powered) return "\udb80\udcb2"       // 󰂲 nf-md-bluetooth_off
        if (hasConnected) return "\udb80\udcb1"   // 󰂱 nf-md-bluetooth_connect
        return "\udb80\udcaf"                      // 󰂯 nf-md-bluetooth
    }

    // Hover highlight
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 6
        color: clickArea.containsMouse
            ? (App.BluetoothService.panelVisible
                ? Qt.rgba(147/255, 197/255, 253/255, 0.15)
                : Qt.rgba(1, 1, 1, 0.06))
            : "transparent"
        Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
    }

    Row {
        id: btRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.btIcon
            color: App.BluetoothService.panelVisible
                ? App.Constants.accent
                : root.hasConnected ? App.Constants.accent
                : root.powered ? App.Constants.light
                : App.Constants.textDim
            font.pixelSize: App.Constants.iconSize
            font.family: App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: App.Constants.animationNormal }
            }
        }

        // Connected device count badge
        Rectangle {
            width: 14
            height: 14
            radius: 7
            color: App.BluetoothService.panelVisible
                ? App.Constants.primary
                : App.Constants.accent
            visible: root.hasConnected
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: App.Constants.animationNormal } }

            Text {
                anchors.centerIn: parent
                text: root.connectedCount
                color: App.Constants.background
                font.pixelSize: 8
                font.bold: true
                font.family: App.Constants.fontFamily
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
            App.NetworkService.closePanel()
            App.NotificationService.closePanel()
            App.BluetoothService.togglePanel()
        }
    }
}
