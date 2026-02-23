import QtQuick 2.0

Text {
    id: root
    
    property bool showHelpTips: false
    property bool fadeInComplete: false
    property int fadeInDuration: 300
    property real elementOpacity: 1.0
    
    visible: root.showHelpTips
    text: "F10 - suspend\nF11 - shutdown\nF12 - restart"
    color: config.stringValue("helpTipsColor") || "#666666"
    font.pixelSize: config.intValue("helpTipsFontSize") || 11
    font.family: config.stringValue("fontFamily") || "JetBrains Mono Nerd Font"
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.margins: 20
    opacity: ((root.fadeInComplete ? 1 : 0) * root.elementOpacity)
    
    Behavior on opacity {
        NumberAnimation { duration: root.fadeInDuration; easing.type: Easing.OutCubic }
    }
}

