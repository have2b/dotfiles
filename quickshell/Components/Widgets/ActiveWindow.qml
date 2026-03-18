import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../" as App

Rectangle {
    id: root
    height: 20
    color: "transparent"
    implicitWidth: contentRow.implicitWidth + 8

    property string activeClass: ""
    property string activeTitle: ""

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow") {
                const data = event.data.toString().split(",")
                root.activeClass = data[0] || ""
                root.activeTitle = data.slice(1).join(",") || ""
            }
        }
    }

    Row {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 4
        spacing: 6

        Image {
            source: root.activeClass !== "" ? "image://icon/" + root.activeClass : ""
            width: 18
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            visible: root.activeClass !== ""

            Behavior on opacity {
                NumberAnimation { duration: App.Constants.animationNormal }
            }
        }

        Text {
            id: label
            width: Math.min(implicitWidth, 150)
            text: root.activeClass !== ""
                ? root.activeClass.charAt(0).toUpperCase() + root.activeClass.slice(1)
                : "Desktop"
            color: root.activeClass !== "" ? App.Constants.light : App.Constants.textDim
            font.pixelSize: 12
            font.family: App.Constants.fontFamily
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: App.Constants.animationNormal }
            }
        }
    }
}
