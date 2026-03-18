import QtQuick
import Quickshell
import "../../" as App

Rectangle {
    id: root
    height: 20
    color: "transparent"
    implicitWidth: clockCol.implicitWidth

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Column {
        id: clockCol
        anchors.centerIn: parent
        spacing: 0

        // Time — prominent
        Text {
            id: timePart
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "hh:mm AP")
            color: App.Constants.light
            font.pixelSize: 13
            font.weight: Font.Medium
            font.family: App.Constants.fontFamily
        }

        // Date — subtle, below the time
        Text {
            id: datePart
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            color: App.Constants.textDim
            font.pixelSize: 9
            font.family: App.Constants.fontFamily
        }
    }
}
