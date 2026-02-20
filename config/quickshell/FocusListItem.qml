import QtQuick

Item {
    id: item

    property string icon: ""
    property string text: ""
    property string subtitle: ""  // Optional subtitle below main text
    property string rightIcon: ""
    property int iconSize: 16
    property int fontSize: 14
    property int subtitleFontSize: 11
    property color iconColor: Colors.overlay0  // Default icon color
    property color subtitleColor: Colors.overlay0  // Subtitle text color

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

    width: parent ? parent.width : 200
    height: subtitle ? 56 : 48  // Taller when subtitle present

    // Focus ring
    Rectangle {
        anchors.fill: body
        anchors.margins: -3
        radius: body.radius + 3
        color: "transparent"
        border.width: 2
        border.color: Colors.peach
        visible: item.focused
    }

    Rectangle {
        id: body
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        radius: 6
        color: item.hovered || item.focused ? Colors.surface0 : "transparent"

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: item.icon
                color: item.iconColor
                font.pixelSize: item.iconSize
                font.family: "Symbols Nerd Font"
                visible: item.icon !== ""
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: item.subtitle ? 2 : 0

                Text {
                    text: item.text
                    color: Colors.text
                    font.pixelSize: item.fontSize
                }

                Text {
                    text: item.subtitle
                    color: item.subtitleColor
                    font.pixelSize: item.subtitleFontSize
                    visible: item.subtitle !== ""
                }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: item.rightIcon
            color: Colors.overlay0
            font.pixelSize: item.iconSize
            font.family: "Symbols Nerd Font"
            visible: item.rightIcon !== ""
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            item.forceActiveFocus()
            item.clicked()
        }
    }

    Keys.onSpacePressed: item.clicked()
    Keys.onReturnPressed: item.clicked()
    Keys.onEnterPressed: item.clicked()
}
