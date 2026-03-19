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
    implicitHeight: Math.min(panelContent.implicitHeight, 520)

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

                // Refreshing indicator (connect / disconnect / pair in progress)
                Text {
                    visible: App.BluetoothService.refreshing
                    text: "..."
                    color: App.Constants.textDim
                    font.pixelSize: 9
                    font.family: App.Constants.fontFamily
                }

                // ── Scan / Stop button ────────────────────────────────────
                Rectangle {
                    visible: App.BluetoothService.powered
                    implicitWidth: scanBtnLabel.implicitWidth + 12
                    height: 22; radius: 6
                    color: App.BluetoothService.scanning
                        ? App.Constants.primaryTint
                        : (scanBtnHover.containsMouse ? App.Constants.surfaceHover : "transparent")
                    border.color: App.BluetoothService.scanning
                        ? App.Constants.primaryBorder : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

                    Text {
                        id: scanBtnLabel
                        anchors.centerIn: parent
                        text: App.BluetoothService.scanning ? "Stop" : "Scan"
                        color: App.BluetoothService.scanning
                            ? App.Constants.primary : App.Constants.textDim
                        font.pixelSize: 9
                        font.family: App.Constants.fontFamily
                        Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
                    }

                    MouseArea {
                        id: scanBtnHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.BluetoothService.scanning
                            ? App.BluetoothService.stopScan()
                            : App.BluetoothService.startScan()
                    }
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

            // ── Paired Devices Header ─────────────────────────────────────
            Text {
                text: "Paired Devices"
                color: App.Constants.textDim
                font.pixelSize: 10
                font.family: App.Constants.fontFamily
                visible: App.BluetoothService.powered && App.BluetoothService.devices.length > 0
            }

            // ── Paired Devices List ───────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.min(devicesCol.implicitHeight, 200)
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

            // ── Separator between paired and available sections ───────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: App.Constants.separator
                visible: App.BluetoothService.powered
                    && App.BluetoothService.devices.length > 0
                    && (App.BluetoothService.scanning || App.BluetoothService.availableDevices.length > 0)
            }

            // ── No Paired Devices + Scan Prompt ───────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 88
                visible: App.BluetoothService.powered
                    && App.BluetoothService.devices.length === 0
                    && App.BluetoothService.availableDevices.length === 0
                    && !App.BluetoothService.refreshing
                    && !App.BluetoothService.scanning

                Column {
                    anchors.centerIn: parent
                    spacing: 8
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
                    // Scan prompt button
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: scanNowLabel.implicitWidth + 16
                        height: 24; radius: 6
                        color: scanNowArea.containsMouse
                            ? App.Constants.primaryTintHover
                            : App.Constants.primaryTint
                        border.color: App.Constants.primaryBorder
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

                        Text {
                            id: scanNowLabel
                            anchors.centerIn: parent
                            text: "Scan for devices"
                            color: App.Constants.primary
                            font.pixelSize: 9
                            font.family: App.Constants.fontFamily
                        }
                        MouseArea {
                            id: scanNowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: App.BluetoothService.startScan()
                        }
                    }
                }
            }

            // ── Available Devices Header ──────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: App.BluetoothService.powered
                    && (App.BluetoothService.scanning || App.BluetoothService.availableDevices.length > 0)

                Text {
                    text: "Available Devices"
                    color: App.Constants.textDim
                    font.pixelSize: 10
                    font.family: App.Constants.fontFamily
                    Layout.fillWidth: true
                }

                // Pulsing scan indicator dot
                Rectangle {
                    visible: App.BluetoothService.scanning
                    width: 6; height: 6; radius: 3
                    color: App.Constants.primary

                    SequentialAnimation on opacity {
                        running: App.BluetoothService.scanning
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.25; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.25; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }
            }

            // ── Available Devices List ────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.min(availableCol.implicitHeight, 180)
                visible: App.BluetoothService.powered && App.BluetoothService.availableDevices.length > 0

                Flickable {
                    anchors.fill: parent
                    contentHeight: availableCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: availableCol
                        width: parent.width
                        spacing: 3

                        Repeater {
                            model: App.BluetoothService.availableDevices

                            Rectangle {
                                id: availableItem
                                required property var modelData
                                width: availableCol.width
                                height: 48
                                radius: 8
                                color: availableItemHover.containsMouse
                                    ? App.Constants.cardHover
                                    : App.Constants.cardNormal
                                border.color: modelData.pairing
                                    ? App.Constants.primaryBorder
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
                                        text: "\udb80\udcaf"
                                        color: modelData.pairing
                                            ? App.Constants.primary
                                            : App.Constants.textDim
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
                                            font.family: App.Constants.fontFamily
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.pairing ? "Pairing\u2026" : "Available"
                                            color: modelData.pairing
                                                ? App.Constants.primary
                                                : App.Constants.textDim
                                            font.pixelSize: 9
                                            font.family: App.Constants.fontFamily
                                            Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
                                        }
                                    }

                                    // Pair button (hidden while pairing)
                                    Rectangle {
                                        implicitWidth: pairBtnText.implicitWidth + 12
                                        height: 22; radius: 6
                                        visible: !modelData.pairing
                                        color: pairBtnArea.containsMouse
                                            ? App.Constants.primaryTintHover
                                            : App.Constants.primaryTint
                                        border.color: App.Constants.primaryBorder
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

                                        Text {
                                            id: pairBtnText
                                            anchors.centerIn: parent
                                            text: "Pair"
                                            color: App.Constants.primary
                                            font.pixelSize: 9
                                            font.family: App.Constants.fontFamily
                                        }
                                        MouseArea {
                                            id: pairBtnArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: App.BluetoothService.pairDevice(modelData.mac)
                                        }
                                    }

                                    // Pairing in-progress indicator
                                    Text {
                                        visible: modelData.pairing
                                        text: "..."
                                        color: App.Constants.primary
                                        font.pixelSize: 11
                                        font.family: App.Constants.fontFamily
                                    }
                                }

                                MouseArea {
                                    id: availableItemHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }
            }

            // ── Scanning Empty State ──────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 40
                visible: App.BluetoothService.powered
                    && App.BluetoothService.scanning
                    && App.BluetoothService.availableDevices.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "Scanning for devices\u2026"
                    color: App.Constants.textDim
                    font.pixelSize: 11
                    font.family: App.Constants.fontFamily
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
