import QtQuick
import Quickshell
import "../../" as App

Rectangle {
    id: root

    implicitWidth: clockCol.implicitWidth
    height:        28
    color:         "transparent"

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Column {
        id: clockCol
        anchors.centerIn: parent
        spacing: 1

        // Time — hh:mm:ss AP
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           Qt.formatDateTime(clock.date, "hh:mm:ss AP")
            color:          App.Constants.light
            font.pixelSize: 13
            font.weight:    Font.Medium
            font.family:    App.Constants.fontFamily
        }

        // Date — "Wednesday, March 04"  (≈ 0.7 × time size)
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           Qt.formatDateTime(clock.date, "dddd, MMMM dd")
            color:          App.Constants.textDim
            font.pixelSize: 9
            font.family:    App.Constants.fontFamily
        }
    }
}
