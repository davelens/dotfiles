import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Controls
import "../.."
import "../../components"

ScrollView {
  id: settingsRoot
  anchors.fill: parent
  clip: true
  contentWidth: availableWidth

  // Search query passed from SettingsPanel
  property string searchQuery: ""

  // Highlight matching text with yellow background
  function highlightText(text, query) {
    if (!query) return text
    var lowerText = text.toLowerCase()
    var lowerQuery = query.toLowerCase()
    var idx = lowerText.indexOf(lowerQuery)
    if (idx === -1) return text
    var before = text.substring(0, idx)
    var match = text.substring(idx, idx + query.length)
    var after = text.substring(idx + query.length)
    return before + '<span style="background-color: ' + Colors.yellow + '; color: ' + Colors.crust + ';">' + match + '</span>' + after
  }

  Column {
    width: parent.width
    spacing: 20

    Text {
      text: "Notifications"
      color: Colors.text
      font.pixelSize: 24
      font.bold: true
    }

    // Preview section
    Rectangle {
      width: parent.width
      height: previewColumn.height + 32
      radius: 8
      color: Colors.mantle

      Column {
        id: previewColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 12

        Text {
          text: "Preview"
          color: Colors.overlay0
          font.pixelSize: 12
        }

        // Preview notification card
        NotificationCard {
          width: Math.min(parent.width, 360)
          appName: "Example App"
          appIcon: ""
          summary: "This is a notification"
          body: "Here's what your notifications look like when they appear."
          urgency: NotificationUrgency.Normal
          showCloseButton: true
          compact: false
        }

        // Test notification button
        FocusButton {
          text: "Send Test Notification"
          onClicked: testNotifyProc.running = true
        }

        Process {
          id: testNotifyProc
          command: ["notify-send", "-a", "Quickshell", "Test Notification", "This is a test notification from the settings panel."]
        }
      }
    }

    // Popup Settings
    Text {
      text: settingsRoot.highlightText("Popup Settings", settingsRoot.searchQuery)
      textFormat: Text.RichText
      color: Colors.subtext0
      font.pixelSize: 14
    }

    Rectangle {
      width: parent.width
      height: popupSettingsColumn.height + 24
      radius: 8
      color: Colors.surface0

      Column {
        id: popupSettingsColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 16

        // Timeout slider
        Column {
          width: parent.width
          spacing: 8

          Item {
            width: parent.width
            height: 20

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "Auto-dismiss timeout"
              color: Colors.subtext1
              font.pixelSize: 15
            }

            Text {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: (NotificationManager.popupTimeout / 1000) + "s"
              color: Colors.text
              font.pixelSize: 15
            }
          }

          FocusSlider {
            width: parent.width
            from: 1000
            to: 30000
            stepSize: 1000
            value: NotificationManager.popupTimeout
            onValueChanged: NotificationManager.popupTimeout = value
          }
        }
      }
    }

    // History Settings
    Text {
      text: settingsRoot.highlightText("History", settingsRoot.searchQuery)
      textFormat: Text.RichText
      color: Colors.subtext0
      font.pixelSize: 15
    }

    Rectangle {
      width: parent.width
      height: historySettingsColumn.height + 24
      radius: 8
      color: Colors.surface0

      Column {
        id: historySettingsColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 16

        // Max history size slider
        Column {
          width: parent.width
          spacing: 8

          Item {
            width: parent.width
            height: 20

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "Maximum history size"
              color: Colors.subtext1
              font.pixelSize: 15
            }

            Text {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: NotificationManager.maxHistorySize + " notifications"
              color: Colors.text
              font.pixelSize: 15
            }
          }

          FocusSlider {
            width: parent.width
            from: 10
            to: 200
            stepSize: 10
            value: NotificationManager.maxHistorySize
            onValueChanged: NotificationManager.maxHistorySize = value
          }
        }

        // Clear history button
        FocusButton {
          width: 140
          text: "Clear History"
          backgroundColor: Colors.surface2
          textHoverColor: Colors.red
          visible: NotificationManager.getTotalHistoryCount() > 0
          onClicked: NotificationManager.clearHistory()
        }
      }
    }

    // Do Not Disturb Settings
    Text {
      text: settingsRoot.highlightText("Do Not Disturb", settingsRoot.searchQuery)
      textFormat: Text.RichText
      color: Colors.subtext0
      font.pixelSize: 14
    }

    Rectangle {
      width: parent.width
      height: dndSettingsColumn.height + 24
      radius: 8
      color: Colors.surface0

      Column {
        id: dndSettingsColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 16

        // DND Schedule toggle
        Row {
          width: parent.width
          spacing: 12

          SwitchToggle {
            anchors.verticalCenter: parent.verticalCenter
            checked: NotificationManager.dndScheduleEnabled
            onClicked: NotificationManager.dndScheduleEnabled = !NotificationManager.dndScheduleEnabled
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Enable DND schedule"
            color: Colors.text
            font.pixelSize: 14
          }
        }

        // Time pickers (visible when schedule enabled)
        Column {
          width: parent.width
          spacing: 16
          visible: NotificationManager.dndScheduleEnabled

          // Start time
          Row {
            spacing: 16

            Text {
              width: 80
              text: "Start time"
              color: Colors.text
              font.pixelSize: 14
              anchors.verticalCenter: parent.verticalCenter
            }

            TimePicker {
              hours: NotificationManager.dndStartHour
              minutes: NotificationManager.dndStartMinute
              onHoursChanged: NotificationManager.dndStartHour = hours
              onMinutesChanged: NotificationManager.dndStartMinute = minutes
            }
          }

          // End time
          Row {
            spacing: 16

            Text {
              width: 80
              text: "End time"
              color: Colors.text
              font.pixelSize: 14
              anchors.verticalCenter: parent.verticalCenter
            }

            TimePicker {
              hours: NotificationManager.dndEndHour
              minutes: NotificationManager.dndEndMinute
              onHoursChanged: NotificationManager.dndEndHour = hours
              onMinutesChanged: NotificationManager.dndEndMinute = minutes
            }
          }

          // Schedule status
          Text {
            text: "DND will be active from " + NotificationManager.formatTime(NotificationManager.dndStartHour, NotificationManager.dndStartMinute) +
                " to " + NotificationManager.formatTime(NotificationManager.dndEndHour, NotificationManager.dndEndMinute)
            color: Colors.overlay0
            font.pixelSize: 12
          }
        }
      }
    }

    // Advanced Settings
    Text {
      text: settingsRoot.highlightText("Advanced", settingsRoot.searchQuery)
      textFormat: Text.RichText
      color: Colors.subtext0
      font.pixelSize: 14
    }

    Rectangle {
      width: parent.width
      height: advancedSettingsColumn.height + 24
      radius: 8
      color: Colors.surface0

      Column {
        id: advancedSettingsColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        // Critical bypass DND toggle
        Row {
          width: parent.width
          spacing: 12

          SwitchToggle {
            anchors.verticalCenter: parent.verticalCenter
            checked: NotificationManager.criticalBypassDnd
            onClicked: NotificationManager.criticalBypassDnd = !NotificationManager.criticalBypassDnd
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              text: "Critical notifications bypass DND"
              color: Colors.text
              font.pixelSize: 14
            }

            Text {
              text: "Show critical notifications even when Do Not Disturb is enabled"
              color: Colors.overlay0
              font.pixelSize: 11
            }
          }
        }
      }
    }
  }
}
