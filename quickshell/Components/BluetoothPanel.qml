import QtQuick
import QtQuick.Layouts
import Quickshell
import "../" as App

PopupWindow {
    id: popup

    visible: App.BluetoothService.panelVisible
    anchor {
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
    }

    implicitWidth: 280
    implicitHeight: Math.min(panelContent.implicitHeight, 460)

    color: "transparent"

    Rectangle {
        id: panelContent
        anchors.fill: parent
        color: App.Constants.surface
        radius: 12
        border.color: App.Constants.panelBorder
        border.width: 1
        implicitHeight: contentCol.implicitHeight + 24

        opacity: popup.visible ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: App.Constants.animationNormal; easing.type: Easing.OutQuad }
        }

        property real _slideY: popup.visible ? 0 : 8
        Behavior on _slideY {
            NumberAnimation { duration: App.Constants.animationNormal; easing.type: Easing.OutCubic }
        }
        transform: Translate { y: panelContent._slideY }

        // Drop shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: 13
            color: "transparent"
            border.color: App.Constants.panelShadow
            border.width: 1
            z: -1
        }

        ColumnLayout {
            id: contentCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 8

            // ── Header ───────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: !App.BluetoothService.powered ? "\udb80\udcb2"
                        : App.BluetoothService.hasConnected ? "\udb80\udcb1"
                        : "\udb80\udcaf"
                    color: App.BluetoothService.hasConnected ? App.Constants.accent
                        : App.BluetoothService.powered ? App.Constants.light
                        : App.Constants.textDim
                    font.pixelSize: 16
                    font.family: App.Constants.fontFamily
                    Behavior on color { ColorAnimation { duration: App.Constants.animationNormal } }
                }

                Text {
                    text: "Bluetooth"
                    color: App.Constants.light
                    font.pixelSize: 13
                    font.bold: true
                    font.family: App.Constants.fontFamily
                    Layout.fillWidth: true
                }

                // Refreshing indicator
                Text {
                    visible: App.BluetoothService.refreshing
                    text: "..."
                    color: App.Constants.textDim
                    font.pixelSize: 9
                    font.family: App.Constants.fontFamily
                }

                // ── Power toggle switch ───────────────────────────────────
                Rectangle {
                    id: powerToggle
                    width: 38
                    height: 22
                    radius: 11
                    color: App.BluetoothService.powered
                        ? App.Constants.primary
                        : App.Constants.textDim
                    opacity: toggleArea.containsMouse ? 0.82 : 1.0

                    Behavior on color {
                        ColorAnimation { duration: App.Constants.animationFast }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: App.Constants.animationFast }
                    }

                    // Thumb
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        anchors.verticalCenter: parent.verticalCenter
                        x: App.BluetoothService.powered
                            ? parent.width - width - 3
                            : 3
                        color: "white"

                        Behavior on x {
                            NumberAnimation {
                                duration: App.Constants.animationFast
                                easing.type: Easing.OutQuad
                            }
                        }
                    }

                    MouseArea {
                        id: toggleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.BluetoothService.togglePower()
                    }
                }

                // Close button
                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: closeBtArea.containsMouse ? App.Constants.surfaceHover : "transparent"
                    Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: App.Constants.textDim
                        font.pixelSize: 9
                        font.family: App.Constants.fontFamily
                    }
                    MouseArea {
                        id: closeBtArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.BluetoothService.closePanel()
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: App.Constants.separator
            }

            // ── Bluetooth Off State ───────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 72
                visible: !App.BluetoothService.powered

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "\udb80\udcb2"
                        color: App.Constants.textDim
                        font.pixelSize: 26
                        font.family: App.Constants.fontFamily
                        opacity: 0.45
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Bluetooth is off"
                        color: App.Constants.textDim
                        font.pixelSize: 11
                        font.family: App.Constants.fontFamily
                    }
                }
            }

            // ── Devices Header ────────────────────────────────────────────
            Text {
                text: "Paired Devices"
                color: App.Constants.textDim
                font.pixelSize: 10
                font.family: App.Constants.fontFamily
                visible: App.BluetoothService.powered && App.BluetoothService.devices.length > 0
            }

            // ── Devices List ──────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.min(devicesCol.implicitHeight, 300)
                visible: App.BluetoothService.powered && App.BluetoothService.devices.length > 0

                Flickable {
                    anchors.fill: parent
                    contentHeight: devicesCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: devicesCol
                        width: parent.width
                        spacing: 3

                        Repeater {
                            model: App.BluetoothService.devices

                            Rectangle {
                                id: deviceItem
                                required property var modelData
                                width: devicesCol.width
                                height: 48
                                radius: 8
                                color: deviceHover.containsMouse
                                    ? (modelData.connected
                                        ? App.Constants.accentTintHover
                                        : App.Constants.cardHover)
                                    : (modelData.connected
                                        ? App.Constants.accentTint
                                        : App.Constants.cardNormal)
                                border.color: modelData.connected
                                    ? App.Constants.accentBorder
                                    : App.Constants.cardBorder
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

                                RowLayout {
                                    anchors {
                                        left: parent.left; right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 10; rightMargin: 10
                                    }
                                    spacing: 8

                                    // Device icon
                                    Text {
                                        text: modelData.connected ? "\udb80\udcb1" : "\udb80\udcaf"
                                        color: modelData.connected ? App.Constants.accent : App.Constants.textDim
                                        font.pixelSize: 16
                                        font.family: App.Constants.fontFamily
                                        Behavior on color { ColorAnimation { duration: App.Constants.animationNormal } }
                                    }

                                    // Name + status
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: modelData.name
                                            color: App.Constants.light
                                            font.pixelSize: 11
                                            font.bold: modelData.connected
                                            font.family: App.Constants.fontFamily
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.connected ? "Connected" : "Paired"
                                            color: modelData.connected ? App.Constants.accent : App.Constants.textDim
                                            font.pixelSize: 9
                                            font.family: App.Constants.fontFamily
                                        }
                                    }

                                    // Connect / Disconnect button
                                    Rectangle {
                                        implicitWidth: deviceBtnText.implicitWidth + 12
                                        height: 22; radius: 6
                                        color: deviceBtnArea.containsMouse
                                            ? (modelData.connected
                                                ? App.Constants.errorTintHover
                                                : App.Constants.primaryTintHover)
                                            : (modelData.connected
                                                ? App.Constants.errorTint
                                                : App.Constants.primaryTint)
                                        border.color: modelData.connected
                                            ? App.Constants.errorBorder
                                            : App.Constants.primaryBorder
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

                                        Text {
                                            id: deviceBtnText
                                            anchors.centerIn: parent
                                            text: modelData.connected ? "Disconnect" : "Connect"
                                            color: modelData.connected ? App.Constants.error : App.Constants.primary
                                            font.pixelSize: 9
                                            font.family: App.Constants.fontFamily
                                        }
                                        MouseArea {
                                            id: deviceBtnArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.connected) {
                                                    App.BluetoothService.disconnectDevice(modelData.mac)
                                                } else {
                                                    App.BluetoothService.connectDevice(modelData.mac)
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: deviceHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }
            }

            // ── No Paired Devices State ───────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 64
                visible: App.BluetoothService.powered
                    && App.BluetoothService.devices.length === 0
                    && !App.BluetoothService.refreshing

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "\udb80\udcaf"
                        color: App.Constants.textDim
                        font.pixelSize: 26
                        font.family: App.Constants.fontFamily
                        opacity: 0.45
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No paired devices"
                        color: App.Constants.textDim
                        font.pixelSize: 11
                        font.family: App.Constants.fontFamily
                    }
                }
            }

            // ── Status Message ────────────────────────────────────────────
            Text {
                Layout.fillWidth: true
                text: App.BluetoothService.statusMessage
                color: App.Constants.accent
                font.pixelSize: 10
                font.family: App.Constants.fontFamily
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
                bottomPadding: 2
            }

            // Bottom spacer
            Item { implicitHeight: 4 }
        }
    }
}
