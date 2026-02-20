import QtQuick

Item {
    id: toggle

    property bool checked: false
    
    // Allow parent to control whether focus ring is shown
    property bool showFocusRing: true
    
    // Focus support
    property bool focused: activeFocus && showFocusRing
    focus: true
    activeFocusOnTab: true

    signal clicked()

    width: 44
    height: 22

    // Focus ring (visible when focused)
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 6
        height: parent.height + 6
        radius: 14
        color: "transparent"
        border.width: 2
        border.color: Colors.peach
        visible: toggle.focused
    }

    // Main toggle body
    Rectangle {
        id: body
        anchors.fill: parent
        radius: 11
        color: toggle.checked ? Colors.blue : Colors.surface0
        border.width: 1
        border.color: Colors.text

        Rectangle {
            x: toggle.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: Colors.text

            Behavior on x { NumberAnimation { duration: 150 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggle.forceActiveFocus()
            toggle.clicked()
        }
    }

    Keys.onSpacePressed: toggle.clicked()
    Keys.onReturnPressed: toggle.clicked()
    Keys.onEnterPressed: toggle.clicked()
}
