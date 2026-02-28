import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

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
    spacing: 16

    Row {
      spacing: 16

      Text {
        text: "Bluetooth"
        color: Colors.text
        font.pixelSize: 24
        font.bold: true
      }

      SwitchToggle {
        anchors.verticalCenter: parent.verticalCenter
        checked: BluetoothManager.powered
        onClicked: BluetoothManager.togglePower()
      }
    }

    // Connected devices list
    Column {
      width: parent.width
      spacing: 8
      visible: BluetoothManager.powered && BluetoothManager.connectedDevices.length > 0

      Text {
        text: settingsRoot.highlightText("Connected devices", settingsRoot.searchQuery)
        textFormat: Text.RichText
        color: Colors.subtext0
        font.pixelSize: 14
      }

      Repeater {
        model: BluetoothManager.connectedDevices

        Rectangle {
          required property var modelData
          required property int index

          width: parent.width
          height: 64
          radius: 8
          color: Colors.surface0

          Row {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "󰂱"
              color: Colors.blue
              font.pixelSize: 18
              font.family: "Symbols Nerd Font"
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              spacing: 2

              Text {
                text: modelData.name
                color: Colors.text
                font.pixelSize: 14
              }

              Text {
                text: settingsRoot.highlightText("Connected", settingsRoot.searchQuery)
                textFormat: Text.RichText
                color: Colors.green
                font.pixelSize: 12
              }
            }
          }

          FocusLink {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "Disconnect"
            onClicked: BluetoothManager.disconnect(modelData.address)
          }
        }
      }
    }

    // Separator after connected devices
    Rectangle {
      width: parent.width
      height: 1
      color: Colors.surface1
      visible: BluetoothManager.powered && BluetoothManager.connectedDevices.length > 0
    }

    // Devices section with header and list
    Column {
      width: parent.width
      spacing: 6
      visible: BluetoothManager.powered

      Row {
        spacing: 8

        Text {
          text: BluetoothManager.scanning ? "Scanning..." : settingsRoot.highlightText("Available Devices", settingsRoot.searchQuery)
          textFormat: Text.RichText
          color: Colors.subtext0
          font.pixelSize: 14
        }

        FocusIconButton {
          icon: "󰑐"
          visible: !BluetoothManager.scanning
          onClicked: BluetoothManager.startScan()
        }
      }

      // Device list (paired but not connected, and discovered)
      Column {
        width: parent.width
        spacing: 2

        Repeater {
          model: BluetoothManager.devices.filter(function(d) { return !d.connected })

          FocusListItem {
            required property var modelData

            icon: modelData.paired ? "󰂰" : "󰂯"
            iconColor: modelData.paired ? Colors.blue : Colors.overlay0
            text: modelData.name
            subtitle: modelData.paired ? "Paired" : "Not paired"
            onClicked: {
              if (!BluetoothManager.busy) {
                BluetoothManager.connect(modelData.address)
              }
            }
          }
        }

        // Empty state
        BodyText {
          text: BluetoothManager.scanning ? "Looking for devices..." : "No devices found"
          visible: BluetoothManager.devices.filter(function(d) { return !d.connected }).length === 0
          topPadding: 8
        }
      }
    }

    // Bluetooth off state
    Column {
      width: parent.width
      spacing: 8
      visible: !BluetoothManager.powered

      BodyText {
        text: "Bluetooth is off"
        topPadding: 16
      }

      BodyText {
        text: "Turn on Bluetooth to connect to devices"
      }
    }
  }
}
