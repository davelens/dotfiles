import QtQuick
import Quickshell
import ".."

Item {
    id: clock
    anchors.verticalCenter: parent.verticalCenter
    width: timeText.width
    height: timeText.height

    Text {
        id: timeText
        text: Time.time
        color: Colors.text
        font.pixelSize: 14
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }

    PopupWindow {
        visible: hoverArea.containsMouse

        anchor.item: clock
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.bottom: -10

        implicitWidth: dateText.implicitWidth + 24
        implicitHeight: dateText.implicitHeight + 16
        color: Colors.crust

        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Colors.surface2; z: 100 }

        Text {
            id: dateText
            anchors.centerIn: parent
            text: Time.date
            color: Colors.text
            font.pixelSize: 14
        }
    }
}
