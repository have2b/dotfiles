import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../" as App

Item {
    id: root
    implicitWidth: hasMedia ? pill.implicitWidth : nothingPill.implicitWidth
    implicitHeight: 24
    height: 24

    property bool hasMedia: App.MediaService.hasPlayer
    // Directly bound — MediaService.qml polls positionChanged() every 500ms while
    // playing, so this binding re-evaluates automatically without any extra timer here.
    property real displayProgress: App.MediaService.progress

    // No media state
    Rectangle {
        id: nothingPill
        visible: !root.hasMedia
        anchors.centerIn: parent
        implicitWidth: nothingRow.implicitWidth + 16
        height: 22
        radius: 11
        color: Qt.rgba(1, 1, 1, 0.04)
        border.color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1

        Row {
            id: nothingRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: "\uf001"
                color: App.Constants.textDim
                font.pixelSize: 11
                font.family: App.Constants.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "No media"
                color: App.Constants.textDim
                font.pixelSize: 11
                font.family: App.Constants.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Active media player
    Rectangle {
        id: pill
        visible: root.hasMedia
        anchors.centerIn: parent
        implicitWidth: playerLayout.implicitWidth + 16
        height: 22
        radius: 11
        color: pillHover.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.05)
        border.color: Qt.rgba(1, 1, 1, 0.07)
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
            id: pillHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        RowLayout {
            id: playerLayout
            anchors.centerIn: parent
            spacing: 8

            // Sound wave icon (animated when playing, static music note when paused)
            Item {
                width: 12
                height: 12
                Layout.alignment: Qt.AlignVCenter

                // Static music note — shown when paused / stopped
                Text {
                    anchors.centerIn: parent
                    text: "󰤽"
                    color: App.Constants.secondary
                    font.pixelSize: 12
                    font.family: App.Constants.fontFamily
                    visible: !App.MediaService.isPlaying
                }

                // Animated sound wave bars — shown while playing
                // Three bars anchored to the bottom, each with a different phase
                Rectangle {
                    id: soundBar1
                    x: 0; width: 2; radius: 1
                    color: App.Constants.secondary
                    visible: App.MediaService.isPlaying
                    height: 5
                    y: parent.height - height
                    SequentialAnimation on height {
                        running: App.MediaService.isPlaying
                        loops: Animation.Infinite
                        NumberAnimation { to: 10; duration: 400; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 3;  duration: 400; easing.type: Easing.InOutSine }
                    }
                }
                Rectangle {
                    id: soundBar2
                    x: 4; width: 2; radius: 1
                    color: App.Constants.secondary
                    visible: App.MediaService.isPlaying
                    height: 10
                    y: parent.height - height
                    SequentialAnimation on height {
                        running: App.MediaService.isPlaying
                        loops: Animation.Infinite
                        PauseAnimation  { duration: 140 }
                        NumberAnimation { to: 2;  duration: 320; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 10; duration: 320; easing.type: Easing.InOutSine }
                    }
                }
                Rectangle {
                    id: soundBar3
                    x: 8; width: 2; radius: 1
                    color: App.Constants.secondary
                    visible: App.MediaService.isPlaying
                    height: 4
                    y: parent.height - height
                    SequentialAnimation on height {
                        running: App.MediaService.isPlaying
                        loops: Animation.Infinite
                        PauseAnimation  { duration: 70 }
                        NumberAnimation { to: 10; duration: 500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1;  duration: 500; easing.type: Easing.InOutSine }
                    }
                }
            }

            // Track info column
            Item {
                Layout.preferredWidth: 130
                Layout.maximumWidth: 130
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter
                clip: true

                Text {
                    id: titleText
                    text: App.MediaService.trackTitle
                    color: App.Constants.light
                    font.pixelSize: 11
                    font.family: App.Constants.fontFamily
                    anchors.verticalCenter: parent.verticalCenter

                    // Scrolling animation when text is too long
                    SequentialAnimation {
                        id: scrollAnimation
                        running: titleText.implicitWidth > 130
                        loops: Animation.Infinite

                        PauseAnimation { duration: 1500 }

                        NumberAnimation {
                            target: titleText
                            property: "x"
                            from: 0
                            to: -(titleText.implicitWidth - 130)
                            duration: Math.max(titleText.implicitWidth - 130, 100) * 40
                            easing.type: Easing.Linear
                        }

                        PauseAnimation { duration: 800 }

                        NumberAnimation {
                            target: titleText
                            property: "x"
                            from: -(titleText.implicitWidth - 130)
                            to: 0
                            duration: Math.max(titleText.implicitWidth - 130, 100) * 40
                            easing.type: Easing.Linear
                        }
                    }
                }
            }

            // Progress bar
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 2
                Layout.alignment: Qt.AlignVCenter
                radius: 1
                color: App.Constants.surface

                Rectangle {
                    height: parent.height
                    width: parent.width * root.displayProgress
                    radius: 1
                    color: App.Constants.accent
                }
            }

            // Transport controls
            Row {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                // Previous
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: prevArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    visible: App.MediaService.canPrevious
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "\uf048"
                        color: App.Constants.light
                        font.pixelSize: 8
                        font.family: App.Constants.fontFamily
                    }
                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.MediaService.previous()
                    }
                }

                // Play/Pause
                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: playArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: App.MediaService.isPlaying ? "\uf04c" : "\uf04b"
                        color: App.Constants.accent
                        font.pixelSize: 9
                        font.family: App.Constants.fontFamily
                    }
                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.MediaService.togglePlaying()
                    }
                }

                // Next
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: nextArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    visible: App.MediaService.canNext
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "\uf051"
                        color: App.Constants.light
                        font.pixelSize: 8
                        font.family: App.Constants.fontFamily
                    }
                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.MediaService.next()
                    }
                }
            }
        }
    }
}
