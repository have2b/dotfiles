import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../" as App

PanelWindow {
    id: root

    // ── Dimensions ───────────────────────────────────────────────────────────
    readonly property int launcherW: 480
    readonly property int launcherH: 360

    // ── Center on screen via anchors + margins ───────────────────────────────
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    margins.top:    Math.max(0, Math.round((screen.height - launcherH) / 2))
    margins.bottom: Math.max(0, Math.round((screen.height - launcherH) / 2))
    margins.left:   Math.max(0, Math.round((screen.width  - launcherW) / 2))
    margins.right:  Math.max(0, Math.round((screen.width  - launcherW) / 2))

    // ── Window behaviour ─────────────────────────────────────────────────────
    visible: App.AppLauncherService.visible
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: -1
    color: "transparent"

    // Focus the search field as soon as the window appears
    onVisibleChanged: {
        if (visible) {
            searchField.text = ""
            searchField.forceActiveFocus()
        }
    }

    // ── Drop shadow ──────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        z: -1
        radius: 16
        color: "transparent"
        border.color: Qt.rgba(0, 0, 0, 0.45)
        border.width: 12
        layer.enabled: true
    }

    // ── Main panel ───────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: App.Constants.surface
        radius: 14
        border.color: App.Constants.panelBorder
        border.width: 1
        clip: true

        opacity: root.visible ? 1.0 : 0.0
        scale:   root.visible ? 1.0 : 0.96
        Behavior on opacity {
            NumberAnimation { duration: App.Constants.animationNormal; easing.type: Easing.OutQuad }
        }
        Behavior on scale {
            NumberAnimation { duration: App.Constants.animationNormal; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // ── Search bar ────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 10
                color: App.Constants.background
                border.color: searchField.activeFocus
                    ? App.Constants.primaryBorderActive
                    : App.Constants.panelBorder
                border.width: 1

                Behavior on border.color {
                    ColorAnimation { duration: App.Constants.animationFast }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    spacing: 10

                    // Search icon
                    Text {
                        text: ""
                        color: searchField.activeFocus
                            ? App.Constants.primary
                            : App.Constants.textDim
                        font.family: App.Constants.fontFamily
                        font.pixelSize: 14

                        Behavior on color {
                            ColorAnimation { duration: App.Constants.animationFast }
                        }
                    }

                    // Input
                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search applications…"
                        color: App.Constants.light
                        font.family: App.Constants.fontFamily
                        font.pixelSize: 13
                        background: null
                        placeholderTextColor: App.Constants.textDim
                        leftPadding: 0
                        rightPadding: 0
                        selectByMouse: true

                        onTextChanged: App.AppLauncherService.requestSearch(text)

                        Keys.onEscapePressed: App.AppLauncherService.close()
                        Keys.onReturnPressed: {
                            const apps = App.AppLauncherService.filteredApps
                            if (apps.length > 0) App.AppLauncherService.launch(apps[0])
                        }
                        Keys.onDownPressed: appList.forceActiveFocus()
                    }

                    // Clear button
                    Text {
                        visible: searchField.text.length > 0
                        text: ""
                        color: App.Constants.textDim
                        font.family: App.Constants.fontFamily
                        font.pixelSize: 12

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchField.text = ""
                                searchField.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: App.Constants.separator
            }

            // ── App list ──────────────────────────────────────────────────
            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: App.AppLauncherService.filteredApps
                spacing: 2
                currentIndex: 0

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                // Reset scroll + selection when filter changes
                onModelChanged: {
                    currentIndex = 0
                    positionViewAtBeginning()
                }

                Keys.onEscapePressed: App.AppLauncherService.close()
                Keys.onReturnPressed: {
                    const apps = App.AppLauncherService.filteredApps
                    if (currentIndex >= 0 && currentIndex < apps.length)
                        App.AppLauncherService.launch(apps[currentIndex])
                }
                Keys.onUpPressed: {
                    if (currentIndex <= 0) searchField.forceActiveFocus()
                    else decrementCurrentIndex()
                }

                delegate: Rectangle {
                    id: appRow
                    width: appList.width
                    height: 48
                    radius: 8
                    color: appList.currentIndex === index
                        ? App.Constants.primaryTint
                        : hoverArea.containsMouse
                            ? App.Constants.cardHover
                            : "transparent"
                    border.color: appList.currentIndex === index
                        ? App.Constants.primaryBorder
                        : "transparent"
                    border.width: 1

                    Behavior on color {
                        ColorAnimation { duration: App.Constants.animationFast }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // App icon
                        Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            Layout.maximumWidth: 16
                            Layout.maximumHeight: 16
                            Layout.alignment: Qt.AlignVCenter
                            sourceSize.width: 16
                            sourceSize.height: 16
                            source: modelData.icon !== ""
                                ? "image://icon/" + modelData.icon
                                : "image://icon/application-x-executable"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        // App name
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: App.Constants.light
                            font.family: App.Constants.fontFamily
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: App.AppLauncherService.launch(modelData)
                        onEntered: appList.currentIndex = index
                    }
                }

                // Empty state
                Text {
                    anchors.centerIn: parent
                    visible: appList.count === 0
                    text: App.AppLauncherService.apps.length === 0
                        ? "Loading applications…"
                        : "No results for \"" + App.AppLauncherService.searchText + "\""
                    color: App.Constants.textDim
                    font.family: App.Constants.fontFamily
                    font.pixelSize: 13
                }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: App.Constants.separator
            }

            // ── Footer ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: App.AppLauncherService.filteredApps.length
                        + (App.AppLauncherService.filteredApps.length === 1 ? " app" : " apps")
                    color: App.Constants.textDim
                    font.family: App.Constants.fontFamily
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "↵ launch  ·  esc close"
                    color: App.Constants.textDim
                    font.family: App.Constants.fontFamily
                    font.pixelSize: 11
                }
            }
        }
    }
}
