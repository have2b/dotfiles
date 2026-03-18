import QtQuick
import QtQuick.Layouts
import Quickshell
import "../" as App

PopupWindow {
    id: popup

    visible: App.NetworkService.panelVisible
    anchor {
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
    }

    implicitWidth: 300
    implicitHeight: Math.min(panelContent.implicitHeight, 480)

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
                    text: App.NetworkService.connectionType === "ethernet" ? ""
                        : App.NetworkService.connected ? "󰤨" : "󰤮"
                    color: App.NetworkService.connected ? App.Constants.primary : App.Constants.textDim
                    font.pixelSize: 16
                    font.family: App.Constants.fontFamily
                    Behavior on color { ColorAnimation { duration: App.Constants.animationNormal } }
                }

                Text {
                    text: "Network"
                    color: App.Constants.light
                    font.pixelSize: 13
                    font.bold: true
                    font.family: App.Constants.fontFamily
                    Layout.fillWidth: true
                }

                // Scanning indicator
                Text {
                    visible: App.NetworkService.scanning
                    text: "Scanning..."
                    color: App.Constants.textDim
                    font.pixelSize: 9
                    font.family: App.Constants.fontFamily
                }

                // Refresh/scan button
                Rectangle {
                    width: 24; height: 22; radius: 6
                    color: scanArea.containsMouse ? App.Constants.surfaceHover : App.Constants.surfaceMuted
                    visible: !App.NetworkService.scanning && App.NetworkService.connectionType !== "ethernet"
                    Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: App.Constants.textDim
                        font.pixelSize: 12
                        font.family: App.Constants.fontFamily
                    }
                    MouseArea {
                        id: scanArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.NetworkService.scan()
                    }
                }

                // Close button
                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: closeArea.containsMouse ? App.Constants.surfaceHover : "transparent"
                    Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: App.Constants.textDim
                        font.pixelSize: 9
                        font.family: App.Constants.fontFamily
                    }
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.NetworkService.closePanel()
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: App.Constants.separator
            }

            // ── Active Connection Card ────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: activeConnRow.implicitHeight + 18
                radius: 8
                color: App.Constants.primaryTint
                border.color: App.Constants.primaryBorder
                border.width: 1
                visible: App.NetworkService.connected

                RowLayout {
                    id: activeConnRow
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10; rightMargin: 10
                    }
                    spacing: 8

                    // Signal / ethernet icon
                    Text {
                        text: {
                            if (App.NetworkService.connectionType === "ethernet") return ""
                            const s = App.NetworkService.signalStrength
                            if (s > 75) return "󰤨"
                            if (s > 50) return "󰤥"
                            if (s > 25) return "󰤢"
                            return "󰤟"
                        }
                        color: App.Constants.primary
                        font.pixelSize: 14
                        font.family: App.Constants.fontFamily
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: App.NetworkService.ssid
                            color: App.Constants.light
                            font.pixelSize: 12
                            font.bold: true
                            font.family: App.Constants.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: App.NetworkService.connectionType === "wifi"
                                ? App.NetworkService.signalStrength + "% signal strength"
                                : "Wired connection"
                            color: App.Constants.textDim
                            font.pixelSize: 9
                            font.family: App.Constants.fontFamily
                        }
                    }

                    // Disconnect button
                    Rectangle {
                        implicitWidth: disconnText.implicitWidth + 14
                        height: 24; radius: 6
                        color: disconnArea.containsMouse
                            ? App.Constants.errorTintHover
                            : App.Constants.errorTint
                        border.color: App.Constants.errorBorder
                        border.width: 1
                        visible: !App.NetworkService.connecting
                        Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

                        Text {
                            id: disconnText
                            anchors.centerIn: parent
                            text: "Disconnect"
                            color: App.Constants.error
                            font.pixelSize: 10
                            font.family: App.Constants.fontFamily
                        }
                        MouseArea {
                            id: disconnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: App.NetworkService.disconnectNetwork()
                        }
                    }
                }
            }

            // ── Available Networks Header ─────────────────────────────────
            Text {
                text: "Available Networks"
                color: App.Constants.textDim
                font.pixelSize: 10
                font.family: App.Constants.fontFamily
                topPadding: App.NetworkService.connected ? 2 : 0
                visible: App.NetworkService.networks.length > 0
            }

            // ── Networks List ─────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.min(networksCol.implicitHeight, 280)
                visible: App.NetworkService.networks.length > 0

                Flickable {
                    anchors.fill: parent
                    contentHeight: networksCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: networksCol
                        width: parent.width
                        spacing: 3

                        Repeater {
                            model: App.NetworkService.networks

                            Rectangle {
                                id: netItem
                                required property var modelData
                                width: networksCol.width
                                height: 44
                                radius: 8
                                color: netHover.containsMouse
                                    ? (modelData.inUse
                                        ? App.Constants.primaryTintHover
                                        : App.Constants.cardHover)
                                    : (modelData.inUse
                                        ? App.Constants.primaryTint
                                        : App.Constants.cardNormal)
                                border.color: modelData.inUse
                                    ? App.Constants.primaryBorderActive
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

                                    // Signal strength icon
                                    Text {
                                        text: {
                                            const s = modelData.signal
                                            if (s > 75) return "󰤨"
                                            if (s > 50) return "󰤥"
                                            if (s > 25) return "󰤢"
                                            return "󰤟"
                                        }
                                        color: modelData.inUse ? App.Constants.primary : App.Constants.textDim
                                        font.pixelSize: 14
                                        font.family: App.Constants.fontFamily
                                    }

                                    // SSID + security row
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: modelData.ssid
                                            color: App.Constants.light
                                            font.pixelSize: 11
                                            font.bold: modelData.inUse
                                            font.family: App.Constants.fontFamily
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.security !== "" ? modelData.security : "Open"
                                            color: App.Constants.textDim
                                            font.pixelSize: 9
                                            font.family: App.Constants.fontFamily
                                        }
                                    }

                                    // Signal percentage
                                    Text {
                                        text: modelData.signal + "%"
                                        color: App.Constants.textDim
                                        font.pixelSize: 9
                                        font.family: App.Constants.fontFamily
                                    }

                                    // Lock icon for secured networks
                                    Text {
                                        text: "\uf023"
                                        color: App.Constants.textDim
                                        font.pixelSize: 9
                                        font.family: App.Constants.fontFamily
                                        visible: modelData.security !== ""
                                        opacity: 0.6
                                    }
                                }

                                MouseArea {
                                    id: netHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: modelData.inUse ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    onClicked: {
                                        if (!modelData.inUse && !App.NetworkService.connecting) {
                                            App.NetworkService.connectNetwork(modelData.ssid)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Empty State (no networks and not scanning) ────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 64
                visible: App.NetworkService.networks.length === 0 && !App.NetworkService.scanning

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰤮"
                        color: App.Constants.textDim
                        font.pixelSize: 26
                        font.family: App.Constants.fontFamily
                        opacity: 0.45
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No networks found"
                        color: App.Constants.textDim
                        font.pixelSize: 11
                        font.family: App.Constants.fontFamily
                    }
                }
            }

            // ── Status Message ────────────────────────────────────────────
            Text {
                Layout.fillWidth: true
                text: App.NetworkService.statusMessage
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
