import Quickshell
import QtQuick
import ".."
import "../components"

BarButton {
    id: button

    // Required: screen for positioning
    required property var screen

    icon: NotificationManager.getIcon()
    iconColor: NotificationManager.isDndActive ? Colors.overlay0 : Colors.text

    onClicked: NotificationManager.togglePanel()

    // Unread badge
    Rectangle {
        id: badge
        visible: NotificationManager.unreadCount > 0 && !NotificationManager.isDndActive
        anchors.right: parent.right
        anchors.rightMargin: -2
        anchors.top: parent.top
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
}
