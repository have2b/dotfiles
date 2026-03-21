import QtQuick
import Quickshell
import "../../" as App

Rectangle {
    id: root
    height:        26
    radius:        12
    border.width:  1
    border.color:  Qt.rgba(202 / 255, 211 / 255, 245 / 255, 0.08)

    // Bind directly to the service
    readonly property bool   fcitxAvailable: App.KeyboardService.fcitxAvailable
    readonly property string currentLayout:  App.KeyboardService.currentLayout

    // Collapse to icon-only width when fcitx5 is unavailable
    implicitWidth: kbRow.implicitWidth + 20

    color: App.Constants.surface

    Row {
        id: kbRow
        anchors.centerIn: parent
        spacing: 5

        // Keyboard icon — always shown; acts as the sole indicator when fcitx5
        // is not running (fallback mode).
        Text {
            text:           "󰌌"   // nf-md-keyboard
            color:          root.fcitxAvailable
                                ? App.Constants.primary
                                : App.Constants.overlay
            font.pixelSize: App.Constants.iconSize
            font.family:    App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: App.Constants.animationNormal } }
        }

        // Layout label — only rendered when fcitx5 is available
        Text {
            visible:        root.fcitxAvailable
            text:           root.currentLayout
            color:          App.Constants.light
            font.pixelSize: 10
            font.weight:    Font.Medium
            font.family:    App.Constants.fontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
    }
}
