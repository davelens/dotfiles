import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import "../.."

// Notification popups window - displays in top-right corner
Variants {
  model: DisplayConfig.primaryScreen ? [DisplayConfig.primaryScreen] : []

  PanelWindow {
    required property var modelData

    id: popupWindow
    screen: modelData
    visible: NotificationManager.visibleNotifications.count > 0

    anchors {
      top: true
      right: true
    }

    // Position below the bar with margin
    margins {
      top: 44  // Bar height (32) + gap (12)
      right: 12
    }

    implicitWidth: 360
    implicitHeight: notificationList.contentHeight

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    ListView {
      id: notificationList
      width: parent.width
      height: contentHeight
      spacing: 8
      interactive: false

      model: NotificationManager.visibleNotifications

      // Animate items sliding up/down when others are added/removed
      displaced: Transition {
        NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic }
      }

      delegate: Item {
        id: notificationItem
        required property int index
        required property int notificationId
        required property string appName
        required property string appIcon
        required property string summary
        required property string body
        required property var urgency

        width: notificationList.width
        height: card.height

        // Track if mouse is hovering (pauses timeout)
        property bool isHovered: cardMouseArea.containsMouse

        NotificationCard {
          id: card
          width: parent.width
          appName: notificationItem.appName
          appIcon: notificationItem.appIcon
          summary: notificationItem.summary
          body: notificationItem.body
          urgency: notificationItem.urgency
          showCloseButton: true
          compact: false

          // Slide-in animation on creation
          x: 400
          opacity: 0

          Component.onCompleted: {
            slideIn.start()
            fadeIn.start()
          }

          NumberAnimation on x {
            id: slideIn
            to: 0
            duration: 200
            easing.type: Easing.OutCubic
            running: false
          }

          NumberAnimation on opacity {
            id: fadeIn
            to: 1
            duration: 200
            running: false
          }

          onDismissed: {
            NotificationManager.dismissPopup(notificationItem.notificationId)
          }

          onClicked: {
            NotificationManager.invokeDefaultAction(notificationItem.notificationId)
          }

          MouseArea {
            id: cardMouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onClicked: function(event) {
              event.accepted = false
            }
            onPressed: function(event) {
              event.accepted = false
            }
            onReleased: function(event) {
              event.accepted = false
            }
          }
        }

        // Auto-dismiss timer
        Timer {
          id: dismissTimer
          interval: NotificationManager.popupTimeout
          running: !notificationItem.isHovered && notificationItem.visible
          repeat: false
          onTriggered: {
            NotificationManager.expirePopup(notificationItem.notificationId)
          }
        }

        // Reset timer when hover ends
        onIsHoveredChanged: {
          if (!isHovered) {
            dismissTimer.restart()
          }
        }
      }
    }
  }
}
