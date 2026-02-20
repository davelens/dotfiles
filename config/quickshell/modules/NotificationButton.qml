import Quickshell
import QtQuick
import ".."

Item {
    id: button

    // Required: screen for positioning
    required property var screen

    width: iconText.width + (badge.visible ? badge.width + 2 : 0)
    height: 32

    // Bell icon
    Text {
        id: iconText
        anchors.verticalCenter: parent.verticalCenter
        text: NotificationManager.getIcon()
        color: NotificationManager.isDndActive ? Colors.overlay0 : Colors.text
        font.pixelSize: 16
        font.family: "Symbols Nerd Font"
    }

    // Unread badge
    Rectangle {
        id: badge
        visible: NotificationManager.unreadCount > 0 && !NotificationManager.isDndActive
        anchors.left: iconText.right
        anchors.leftMargin: 2
        anchors.top: iconText.top
        anchors.topMargin: -2
        width: Math.max(badgeText.width + 6, height)
        height: 14
        radius: 7
        color: Colors.red

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: NotificationManager.unreadCount > 99 ? "99+" : NotificationManager.unreadCount.toString()
            color: Colors.crust
            font.pixelSize: 9
            font.bold: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationManager.togglePanel()
    }
}
