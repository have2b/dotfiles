import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../" as App

Rectangle {
    id: root
    height:        26
    radius:        12
    implicitWidth: batteryRow.implicitWidth + 20
    visible:       batteryDevice.ready
    color:         App.Constants.surface
    border.width:  1
    border.color:  Qt.rgba(202 / 255, 211 / 255, 245 / 255, 0.08)

    property var  batteryDevice: UPower.displayDevice
    // UPowerDevice.percentage is 0–1; multiply to display value
    property real percentage:    batteryDevice.ready ? batteryDevice.percentage * 100 : 0
    property bool charging:      batteryDevice.ready
                                     ? batteryDevice.state === UPowerDeviceState.Charging
                                     : false

    property color levelColor: {
        if (charging)              return App.Constants.teal    // charging → teal
        if (percentage > 60)       return App.Constants.success  // green
        if (percentage > 20)       return App.Constants.warning  // yellow
        return App.Constants.error                               // red
    }

    property string batteryIcon: {
        if (charging)               return "󰖓"
        if (percentage > 75)        return "󱊣"
        if (percentage > 50)        return "󱊢"
        if (percentage > 20)        return "󱊡"
        if (percentage > 0)         return "󰂎"
        return "󱟩"
    }

    Row {
        id: batteryRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text:           root.batteryIcon
            color:          root.levelColor
            font.pixelSize: App.Constants.iconSize
            font.family:    App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: App.Constants.animationNormal } }
        }

        Text {
            text:           Math.round(root.percentage) + "%"
            color:          root.levelColor
            font.pixelSize: 10
            font.family:    App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: App.Constants.animationNormal } }
        }
    }
}
