import QtQuick

Item {
    id: button

    property string icon: ""
    property color iconColor: Colors.overlay0
    property color hoverColor: Colors.blue
    property int iconSize: 14

    // Allow parent to control whether focus ring is shown
    property bool showFocusRing: true

    // Track if focus came from keyboard (not mouse)
    property bool keyboardFocus: false

    // Focus support - only show ring for keyboard focus
    property bool focused: activeFocus && showFocusRing && keyboardFocus
    property bool hovered: mouseArea.containsMouse
    focus: true
    activeFocusOnTab: true

    onActiveFocusChanged: {
        if (!activeFocus) keyboardFocus = false
    }

    signal clicked()

    width: iconSize + 8
    height: iconSize + 8

    // Focus ring
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 4
        height: parent.height + 4
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: Colors.peach
        visible: button.focused
    }

    Text {
        anchors.centerIn: parent
        text: button.icon
        color: button.hovered || button.focused ? button.hoverColor : button.iconColor
        font.pixelSize: button.iconSize
        font.family: "Symbols Nerd Font"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            button.forceActiveFocus()
            button.clicked()
        }
    }

    Keys.onSpacePressed: button.clicked()
    Keys.onReturnPressed: button.clicked()
    Keys.onEnterPressed: button.clicked()
}
