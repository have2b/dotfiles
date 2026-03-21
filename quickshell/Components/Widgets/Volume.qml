import QtQuick
import Quickshell
import "../../" as App

Rectangle {
    id: root
    height:        26
    radius:        12
    implicitWidth: volRow.implicitWidth + 20
    color:         App.Constants.surface
    border.width:  1
    border.color:  Qt.rgba(202 / 255, 211 / 255, 245 / 255, 0.08)

    property real volume: App.AudioService.volume
    property bool muted:  App.AudioService.muted

    property string volumeIcon: {
        if (muted || volume <= 0) return "󰝟"   // volume_off
        if (volume < 33)          return "󰕿"   // volume_low
        if (volume < 66)          return "󰖀"   // volume_medium
        return "󰕾"                              // volume_high
    }

    Row {
        id: volRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text:           root.volumeIcon
            color:          root.muted ? App.Constants.overlay : App.Constants.textDim
            font.pixelSize: App.Constants.iconSize
            font.family:    App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: App.Constants.animationNormal } }
        }

        Text {
            text:           root.muted ? "Muted" : Math.round(root.volume) + "%"
            color:          root.muted ? App.Constants.overlay : App.Constants.light
            font.pixelSize: 10
            font.family:    App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: App.Constants.animationNormal } }
        }
    }

    MouseArea {
        anchors.fill:    parent
        hoverEnabled:    true
        cursorShape:     Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        onClicked: App.AudioService.toggleMute()

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                App.AudioService.increaseVolume()
            else
                App.AudioService.decreaseVolume()
        }
    }
}
