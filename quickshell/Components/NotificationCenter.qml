import QtQuick
import QtQuick.Layouts
import Quickshell
import "../" as App

PopupWindow {
    id: popup

    visible: App.NotificationService.panelVisible
    anchor {
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
    }

    implicitWidth: 360
    implicitHeight: Math.min(panelContent.implicitHeight, 640)

    color: "transparent"

    onVisibleChanged: {
        if (visible) App.NotificationService.markAllRead()
    }

    Rectangle {
        id: panelContent
        anchors.fill: parent
        color: App.Constants.surface
        radius: 12
        border.color: App.Constants.panelBorder
        border.width: 1
        implicitHeight: contentColumn.implicitHeight + 24

        opacity: popup.visible ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: App.Constants.animationNormal; easing.type: Easing.OutQuad }
        }

        property real _slideY: popup.visible ? 0 : 8
        Behavior on _slideY {
            NumberAnimation { duration: App.Constants.animationNormal; easing.type: Easing.OutCubic }
        }
        transform: Translate { y: panelContent._slideY }

        // Drop shadow simulation
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
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Notifications"
                    color: App.Constants.light
                    font.pixelSize: 14
                    font.bold: true
                    font.family: App.Constants.fontFamily
                    Layout.fillWidth: true
                }

                Text {
                    text: App.NotificationService.count + ""
                    color: App.Constants.textDim
                    font.pixelSize: 11
                    font.family: App.Constants.fontFamily
                    visible: App.NotificationService.count > 0
                }

                // Clear all — trash icon button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 6
                    color: clearAllArea.containsMouse
                        ? App.Constants.errorTintHover
                        : App.Constants.cardNormal
                    visible: App.NotificationService.count > 0

                    Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf1f8"
                        color: clearAllArea.containsMouse
                            ? App.Constants.error
                            : App.Constants.textDim
                        font.pixelSize: 12
                        font.family: App.Constants.fontFamily
                        Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
                    }

                    MouseArea {
                        id: clearAllArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.NotificationService.dismissAll()
                    }
                }

                // Close button
                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: closeNotifArea.containsMouse ? App.Constants.surfaceHover : "transparent"
                    Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: App.Constants.textDim
                        font.pixelSize: 9
                        font.family: App.Constants.fontFamily
                    }
                    MouseArea {
                        id: closeNotifArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.NotificationService.closePanel()
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: App.Constants.separator
            }

            // Notification list or empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 60
                Layout.maximumHeight: 560

                // Empty state
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: App.NotificationService.count === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "\udb80\ude5a"
                        color: App.Constants.textDim
                        font.pixelSize: 28
                        font.family: App.Constants.fontFamily
                        opacity: 0.5
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No notifications"
                        color: App.Constants.textDim
                        font.pixelSize: 12
                        font.family: App.Constants.fontFamily
                    }
                }

                // Scrollable list
                Flickable {
                    anchors.fill: parent
                    contentHeight: notifColumn.implicitHeight
                    clip: true
                    visible: App.NotificationService.count > 0
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: notifColumn
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: App.NotificationService.notifications.values

                            Rectangle {
                                id: notifCard
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: cardContent.implicitHeight + 16
                                radius: 8
                                color: cardHover.containsMouse
                                    ? App.Constants.cardHover
                                    : App.Constants.cardNormal
                                border.color: App.Constants.cardBorder
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

                                // Entrance animation: slide up + fade in
                                opacity: 0
                                property real _slideY: 12
                                transform: Translate { y: notifCard._slideY }

                                Component.onCompleted: {
                                    entranceOpacity.start()
                                    entranceSlide.start()
                                }
                                NumberAnimation {
                                    id: entranceOpacity
                                    target: notifCard; property: "opacity"
                                    from: 0; to: 1
                                    duration: App.Constants.animationNormal
                                    easing.type: Easing.OutQuad
                                }
                                NumberAnimation {
                                    id: entranceSlide
                                    target: notifCard; property: "_slideY"
                                    from: 12; to: 0
                                    duration: App.Constants.animationNormal
                                    easing.type: Easing.OutCubic
                                }

                                MouseArea {
                                    id: cardHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }

                                ColumnLayout {
                                    id: cardContent
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 8
                                    }
                                    spacing: 4

                                    // App name + dismiss
                                    RowLayout {
                                        Layout.fillWidth: true

                                        Image {
                                            source: notifCard.modelData.appIcon
                                                ? "image://icon/" + notifCard.modelData.appIcon
                                                : ""
                                            width: 14
                                            height: 14
                                            visible: notifCard.modelData.appIcon !== ""
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: notifCard.modelData.appName || "Unknown"
                                            color: App.Constants.textDim
                                            font.pixelSize: 9
                                            font.family: App.Constants.fontFamily
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        // Dismiss button
                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            color: dismissArea.containsMouse
                                                ? App.Constants.surfaceHover
                                                : "transparent"
                                            Layout.alignment: Qt.AlignVCenter

                                            Text {
                                                anchors.centerIn: parent
                                                text: "\uf00d"
                                                color: App.Constants.textDim
                                                font.pixelSize: 8
                                                font.family: App.Constants.fontFamily
                                            }

                                            MouseArea {
                                                id: dismissArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: App.NotificationService.dismiss(notifCard.modelData)
                                            }
                                        }
                                    }

                                    // Summary (title)
                                    Text {
                                        text: notifCard.modelData.summary || ""
                                        color: App.Constants.light
                                        font.pixelSize: 12
                                        font.bold: true
                                        font.family: App.Constants.fontFamily
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        visible: text !== ""
                                    }

                                    // Body
                                    Text {
                                        text: notifCard.modelData.body || ""
                                        color: App.Constants.textDim
                                        font.pixelSize: 11
                                        font.family: App.Constants.fontFamily
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        visible: text !== ""
                                    }

                                    // Notification image
                                    Image {
                                        source: notifCard.modelData.image || ""
                                        Layout.fillWidth: true
                                        Layout.maximumHeight: 120
                                        fillMode: Image.PreserveAspectFit
                                        visible: source !== "" && status === Image.Ready
                                    }

                                    // Action buttons
                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        visible: notifCard.modelData.actions && notifCard.modelData.actions.length > 0

                                        Repeater {
                                            model: notifCard.modelData.actions || []

                                            Rectangle {
                                                required property var modelData
                                                width: actionText.implicitWidth + 12
                                                height: 22
                                                radius: 6
                                                color: actionArea.containsMouse
                                                    ? App.Constants.primary
                                                    : App.Constants.surfaceMuted

                                                Behavior on color { ColorAnimation { duration: App.Constants.animationFast } }

                                                Text {
                                                    id: actionText
                                                    anchors.centerIn: parent
                                                    text: modelData.text || modelData.identifier || ""
                                                    color: App.Constants.light
                                                    font.pixelSize: 10
                                                    font.family: App.Constants.fontFamily
                                                }

                                                MouseArea {
                                                    id: actionArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: modelData.invoke()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
