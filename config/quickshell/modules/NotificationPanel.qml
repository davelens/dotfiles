import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Controls
import ".."
import "../components"

// Notification history panel - slides in from right
Variants {
  model: DisplayConfig.primaryScreen ? [DisplayConfig.primaryScreen] : []

  PanelWindow {
    required property var modelData

    id: panel
    screen: modelData

    // Keep visible during close animation
    visible: NotificationManager.panelOpen || slideAnimation.running

    anchors {
      top: true
      left: true
      right: true
      bottom: true
    }

    // Leave room for status bar at top
    margins.top: 36

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell-notification-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: NotificationManager.panelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ESC key handling
    contentItem {
      focus: NotificationManager.panelOpen
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          NotificationManager.closePanel()
          event.accepted = true
        }
      }
    }

    // Click-outside overlay (only active when panel is open)
    MouseArea {
      anchors.fill: parent
      enabled: NotificationManager.panelOpen
      onClicked: NotificationManager.closePanel()
    }

    // Panel content with slide animation
    Rectangle {
      id: panelContent
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.right: parent.right
      anchors.rightMargin: NotificationManager.panelOpen ? 0 : -width
      width: 380
      color: Colors.base

      Behavior on anchors.rightMargin {
        NumberAnimation {
          id: slideAnimation
          duration: 250
          easing.type: Easing.OutCubic
        }
      }

      // Left border
      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Colors.surface0
      }

      Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Header
        Item {
          width: parent.width
          height: 32

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            color: Colors.text
            font.pixelSize: 20
            font.bold: true
          }

          // Close button
          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "󰅖"
            color: closeArea.containsMouse ? Colors.red : Colors.overlay0
            font.pixelSize: 18
            font.family: "Symbols Nerd Font"

            MouseArea {
              id: closeArea
              anchors.fill: parent
              anchors.margins: -8
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: NotificationManager.closePanel()
            }
          }
        }

        // DND toggle section
        Rectangle {
          width: parent.width
          height: dndColumn.height + 24
          radius: 8
          color: Colors.surface0

          Column {
            id: dndColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            Item {
              width: parent.width
              height: 40

              Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // DND toggle switch
                SwitchToggle {
                  id: dndToggle
                  anchors.verticalCenter: parent.verticalCenter
                  checked: NotificationManager.dndEnabled
                  onClicked: NotificationManager.toggleDnd()
                }

                Column {
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 2

                  Text {
                    text: "Do Not Disturb"
                    color: Colors.text
                    font.pixelSize: 14
                  }

                  Text {
                    text: NotificationManager.isDndActive
                      ? (NotificationManager.dndEnabled ? "Enabled manually" : "Until " + NotificationManager.formatTime(NotificationManager.dndEndHour, NotificationManager.dndEndMinute))
                      : NotificationManager.dndScheduleText
                    color: Colors.overlay0
                    font.pixelSize: 12
                  }
                }
              }

              // Configure button (aligned right)
              Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Configure"
                color: configArea.containsMouse ? Colors.blue : Colors.overlay0
                font.pixelSize: 12

                MouseArea {
                  id: configArea
                  anchors.fill: parent
                  anchors.margins: -4
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: NotificationManager.openSettingsNotifications()
                }
              }
            }
          }
        }

        // Notifications list
        ScrollView {
          width: parent.width
          height: parent.height - 32 - 16 - dndColumn.height - 24 - 16 - clearButton.height - 16
          clip: true

          Column {
            width: parent.width
            spacing: 8

            // Empty state
            Item {
              width: parent.width
              height: 120
              visible: NotificationManager.history.length === 0

              Column {
                anchors.centerIn: parent
                spacing: 8

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "󰂚"
                  color: Colors.overlay0
                  font.pixelSize: 48
                  font.family: "Symbols Nerd Font"
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "All caught up!"
                  color: Colors.overlay0
                  font.pixelSize: 14
                }
              }
            }

            // Grouped notifications
            Repeater {
              model: NotificationManager.history

              Column {
                id: groupColumn
                required property var modelData
                required property int index

                width: parent.width
                spacing: 4

                // Group header (app name)
                Rectangle {
                  width: parent.width
                  height: 36
                  radius: 6
                  color: groupHeaderArea.containsMouse ? Colors.surface0 : "transparent"

                  Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    // Expand/collapse arrow
                    Text {
                      text: groupColumn.modelData.expanded ? "󰅀" : "󰅂"
                      color: Colors.overlay0
                      font.pixelSize: 12
                      font.family: "Symbols Nerd Font"
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: groupColumn.modelData.appName
                      color: Colors.text
                      font.pixelSize: 13
                      font.bold: true
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: "(" + groupColumn.modelData.notifications.length + ")"
                      color: Colors.overlay0
                      font.pixelSize: 12
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }

                  MouseArea {
                    id: groupHeaderArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationManager.toggleGroup(groupColumn.modelData.appName)
                  }
                }

                // Notifications in group (collapsed)
                Column {
                  width: parent.width
                  spacing: 4
                  visible: groupColumn.modelData.expanded

                  Repeater {
                    model: groupColumn.modelData.notifications

                    NotificationCard {
                      required property var modelData
                      required property int index

                      width: parent.width
                      appName: modelData.appName
                      appIcon: modelData.appIcon
                      summary: modelData.summary
                      body: modelData.body
                      urgency: modelData.urgency
                      showCloseButton: true
                      compact: true

                      onDismissed: {
                        NotificationManager.removeFromHistory(modelData.id)
                      }

                      onClicked: {
                        // Could open the app or do something else
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // Clear all button
        Rectangle {
          id: clearButton
          width: parent.width
          height: 40
          radius: 8
          color: clearButtonArea.containsMouse ? Colors.surface1 : Colors.surface0
          visible: NotificationManager.history.length > 0

          Text {
            anchors.centerIn: parent
            text: "Clear All Notifications"
            color: clearButtonArea.containsMouse ? Colors.red : Colors.text
            font.pixelSize: 13
          }

          MouseArea {
            id: clearButtonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationManager.clearHistory()
          }

          Behavior on color {
            ColorAnimation { duration: 100 }
          }
        }
      }
    }
  }
}
