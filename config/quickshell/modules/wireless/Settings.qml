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
        text: "Wireless"
        color: Colors.text
        font.pixelSize: 24
        font.bold: true
      }

      SwitchToggle {
        anchors.verticalCenter: parent.verticalCenter
        checked: WirelessManager.enabled
        onClicked: WirelessManager.toggleEnabled()
      }
    }

    Column {
      width: parent.width
      spacing: 8
      visible: WirelessManager.connectedNetwork !== null

      TitleText {
        text: settingsRoot.highlightText("Connected network", settingsRoot.searchQuery)
        textFormat: Text.RichText
      }

      Rectangle {
        width: parent.width
        height: 80
        radius: 8
        color: Colors.surface0

        Column {
          anchors.left: parent.left
          anchors.leftMargin: 16
          anchors.verticalCenter: parent.verticalCenter
          spacing: 4

          Text {
            text: WirelessManager.connectedNetwork ? WirelessManager.connectedNetwork.ssid : ""
            color: Colors.text
            font.pixelSize: 16
          }

          Text {
            text: settingsRoot.highlightText("Connected", settingsRoot.searchQuery)
            textFormat: Text.RichText
            color: Colors.green
            font.pixelSize: 12
          }

          Row {
            spacing: 16

            Text {
              text: "Down: " + WirelessManager.formatSpeed(WirelessManager.downloadSpeed)
              color: Colors.overlay0
              font.pixelSize: 12
            }

            Text {
              text: "Up: " + WirelessManager.formatSpeed(WirelessManager.uploadSpeed)
              color: Colors.overlay0
              font.pixelSize: 12
            }
          }
        }

        FocusLink {
          anchors.right: parent.right
          anchors.rightMargin: 16
          anchors.verticalCenter: parent.verticalCenter
          text: "Disconnect"
          onClicked: WirelessManager.disconnect()
        }
      }
    }

    // Separator after connected network
    Rectangle {
      width: parent.width
      height: 1
      color: Colors.surface1
      visible: WirelessManager.connectedNetwork !== null
    }

    Column {
      width: parent.width
      spacing: 6
      visible: WirelessManager.enabled

      Row {
        spacing: 8

        TitleText {
          text: WirelessManager.scanning ? "Scanning..." : settingsRoot.highlightText("Available Networks", settingsRoot.searchQuery)
          textFormat: Text.RichText
        }

        FocusIconButton {
          icon: "󰑐"
          visible: !WirelessManager.scanning
          onClicked: WirelessManager.startScan()
        }
      }

      Column {
        width: parent.width
        spacing: 2

        Repeater {
          model: WirelessManager.networks.filter(function(n) { return !n.active })

          FocusListItem {
            required property var modelData

            icon: WirelessManager.getSignalIcon(modelData.signal)
            text: modelData.ssid
            rightIcon: modelData.security ? "󰌾" : ""
            onClicked: WirelessManager.connect(modelData.ssid)
          }
        }
      }
    }
  }
}
