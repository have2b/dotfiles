import QtQuick
import Quickshell
import "../../" as App

Rectangle {
    id: root
    height: 20
    color: "transparent"
    implicitWidth: clockRow.implicitWidth

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: datePart
            text: Qt.formatDateTime(clock.date, "d MMM yyyy")
            color: App.Constants.secondary
            font.pixelSize: 12
            font.family: App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 1
            height: 12
            color: App.Constants.secondary
            anchors.verticalCenter: parent.verticalCenter
            opacity: 0.5
        }

        Text {
            id: timePart
            text: Qt.formatDateTime(clock.date, "hh:mm AP")
            color: App.Constants.light
            font.pixelSize: 12
            font.bold: true
            font.family: App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
