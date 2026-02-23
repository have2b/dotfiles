import QtQuick 2.0

Text {
    id: root
    
    property bool showCapsLockIndicator: false
    property bool capsLockActive: false
    property int animationDuration: 200
    property real elementOpacity: 1.0
    
    visible: root.showCapsLockIndicator && root.capsLockActive
    text: "CAPS LOCK"
    color: config.stringValue("capsLockIndicatorColor") || "#ffaa00"
    font.pixelSize: config.intValue("capsLockIndicatorFontSize") || 12
    font.family: config.stringValue("fontFamily") || "JetBrains Mono Nerd Font"
    opacity: (root.visible ? 1 : 0) * root.elementOpacity
    
    Behavior on opacity {
        NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic }
    }
}

