import QtQuick

Item {
    id: link

    property string text: ""
    property color textColor: Colors.overlay0
    property color hoverColor: Colors.red
    property int fontSize: 13

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

    width: label.width
    height: label.height

    // Focus underline
    Rectangle {
        anchors.bottom: label.bottom
        anchors.bottomMargin: -2
        anchors.horizontalCenter: label.horizontalCenter
        width: label.width + 4
        height: 2
        color: Colors.peach
        visible: link.focused
    }

    Text {
        id: label
        text: link.text
        color: link.hovered || link.focused ? link.hoverColor : link.textColor
        font.pixelSize: link.fontSize
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            link.forceActiveFocus()
            link.clicked()
        }
    }

    Keys.onSpacePressed: link.clicked()
    Keys.onReturnPressed: link.clicked()
    Keys.onEnterPressed: link.clicked()
}
