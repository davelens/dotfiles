import QtQuick

Rectangle {
    id: toggle

    property bool checked: false

    signal clicked()

    width: 44
    height: 22
    radius: 11
    color: checked ? Colors.blue : Colors.surface0
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

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.clicked()
    }
}
