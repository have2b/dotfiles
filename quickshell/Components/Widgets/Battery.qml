import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../" as App

Rectangle {
    id: root
    height: 20
    color: "transparent"
    implicitWidth: batteryRow.implicitWidth + 8
    visible: batteryDevice.ready

    property var batteryDevice: UPower.displayDevice

    // UPowerDevice.percentage is 0–1 on this system; multiply to get display value
    property real percentage: batteryDevice.ready ? batteryDevice.percentage * 100 : 0
    property bool charging: batteryDevice.ready ? batteryDevice.state === UPowerDeviceState.Charging : false

    property color levelColor: {
        if (charging) return App.Constants.accent
        if (percentage > 60 && percentage <= 100) return App.Constants.success
        if (percentage > 20 && percentage <= 60) return App.Constants.warning
        return App.Constants.error
    }

    property string batteryIcon: {
        if (charging) return "󰖓"
        if (percentage <= 100 && percentage > 75) return "󱊣"
        if (percentage <= 75 && percentage > 50) return "󱊢"
        if (percentage <= 50 && percentage > 20) return "󱊡"
        if (percentage <= 20 && percentage > 0) return "󰂎"
        return "󱟩"
    }

    Row {
        id: batteryRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.batteryIcon
            color: root.levelColor
            font.pixelSize: App.Constants.iconSize
            font.family: App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: App.Constants.animationNormal }
            }
        }

        Text {
            text: Math.round(root.percentage) + "%"
            color: root.levelColor
            font.pixelSize: 11
            font.family: App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: App.Constants.animationNormal }
            }
        }
    }
}
