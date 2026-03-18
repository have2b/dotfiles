import QtQuick
import Quickshell
import "../../" as App

Rectangle {
    id: root
    height: 20
    color: "transparent"
    implicitWidth: volRow.implicitWidth + 8

    property real volume: App.AudioService.volume
    property bool muted: App.AudioService.muted

    property string volumeIcon: {
        if (muted || volume <= 0) return "󰝟"   // nf-md-volume_off
        if (volume < 33)          return "󰕿"   // nf-md-volume_low
        if (volume < 66)          return "󰖀"   // nf-md-volume_medium
        return "󰕾"                              // nf-md-volume_high
    }

    property color iconColor: {
        if (muted || volume <= 0) return App.Constants.textDim
        if (volume < 33)          return App.Constants.secondary
        return App.Constants.light
    }

    // Hover background
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 6
        color: clickArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
        Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
    }

    Row {
        id: volRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.volumeIcon
            color: root.iconColor
            font.pixelSize: App.Constants.iconSize
            font.family: App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: App.Constants.animationNormal }
            }
        }

        Text {
            text: root.muted ? "Muted" : Math.round(root.volume) + "%"
            color: root.muted ? App.Constants.textDim : App.Constants.light
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
