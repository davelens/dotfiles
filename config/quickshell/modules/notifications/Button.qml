import Quickshell
import QtQuick
import "../.."
import "../../core/components"

BarButton {
  id: button

  // Required: screen for positioning
  required property var screen

  // NotificationManager can be passed from shell.qml or fallback to import
  property var notificationManager: NotificationManager

  icon: notificationManager.getIcon()
  iconColor: notificationManager.isDndActive ? Colors.overlay0 : Colors.text

  onClicked: notificationManager.togglePanel()

  // Unread badge
  Rectangle {
    id: badge
    visible: button.notificationManager.unreadCount > 0 && !button.notificationManager.isDndActive
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
      text: button.notificationManager.unreadCount > 99 ? "99+" : button.notificationManager.unreadCount.toString()
      color: Colors.crust
      font.pixelSize: 9
      font.bold: true
    }
  }
}
