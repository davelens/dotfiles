import QtQuick

Rectangle {
    id: button

    // Required
    required property string icon

    // Optional customization
    property int iconSize: 18
    property color iconColor: Colors.text
    property color iconColorHover: iconColor
    property bool iconColorOnHover: false

    // Expose hover state and click signal
    readonly property bool hovered: mouseArea.containsMouse
    signal clicked()

    // Also support scroll wheel
    signal wheel(var event)

    width: 28
    height: 24
    radius: 4
    color: mouseArea.containsMouse ? Colors.surface1 : Colors.surface0

    Text {
        anchors.centerIn: parent
        text: button.icon
        color: button.iconColorOnHover && mouseArea.containsMouse ? button.iconColorHover : button.iconColor
        font.pixelSize: button.iconSize
        font.family: "Symbols Nerd Font"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
        onWheel: event => button.wheel(event)
    }
}
