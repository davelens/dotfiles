import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

Variants {
  id: wirelessPopup

  property bool isOpen: PopupManager.isOpen("wireless")

  // Start scan when popup opens
  onIsOpenChanged: {
    if (isOpen && WirelessManager.enabled) {
      WirelessManager.startScan()
    }
  }

  model: isOpen && DisplayConfig.primaryScreen
         ? [DisplayConfig.primaryScreen] : []

  PanelWindow {
    required property var modelData

    id: panel
    screen: modelData

    anchors {
      top: true
      left: true
      right: true
      bottom: true
    }

    margins.top: 42
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    contentItem {
      focus: true
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape
            || (event.key === Qt.Key_BracketLeft && (event.modifiers & Qt.ControlModifier))) {
          PopupManager.close()
          event.accepted = true
        }
      }
    }

    // Click outside to close
    MouseArea {
      anchors.fill: parent
      onClicked: PopupManager.close()
    }

    // Popup content
    Rectangle {
      x: PopupManager.anchorRight - width
      y: 0
      width: 380
      height: {
        // Header (28) + spacing (12) + separator (1) + spacing (12)
        var h = 28 + 12 + 1 + 12

        if (!WirelessManager.enabled) {
          h += 50
        } else {
          if (WirelessManager.connectedNetwork) {
            h += 16 + 6 + 36 + 6 + 32 + 12
          }

          h += 20 + 12

          var visibleNetworks = WirelessManager.networks.filter(n => !n.active).length
          if (visibleNetworks > 0) {
            var displayCount = Math.min(visibleNetworks, 6)
            h += displayCount * 36 + (displayCount - 1) * 2
          } else {
            h += 40
          }
        }

        return h + 48
      }
      color: Colors.base
      border.width: 1
      border.color: Colors.surface2

      Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 24
        spacing: 12

        // Header with power toggle
        Row {
          width: parent.width
          height: 28
          spacing: 8

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: WirelessManager.getIcon()
            color: WirelessManager.enabled ? Colors.blue : Colors.overlay0
            font.pixelSize: 20
            font.family: "Symbols Nerd Font"
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Wi-Fi"
            color: Colors.text
            font.pixelSize: 16
          }

          Item { width: parent.width - 120; height: 1 }

          SwitchToggle {
            anchors.verticalCenter: parent.verticalCenter
            checked: WirelessManager.enabled
            onClicked: WirelessManager.toggleEnabled()
          }
        }

        // Separator
        Rectangle {
          width: parent.width
          height: 1
          color: Colors.surface1
          visible: WirelessManager.enabled
        }

        // Connected network
        Column {
          width: parent.width
          spacing: 6
          visible: WirelessManager.connectedNetwork !== null

          Text {
            text: "Connected network"
            color: Colors.overlay0
            font.pixelSize: 14
          }

          Rectangle {
            id: connectedNetworkRect
            width: parent.width
            height: 36
            radius: 4
            color: Colors.surface1

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 10
              anchors.verticalCenter: parent.verticalCenter
              text: WirelessManager.getIcon()
              color: Colors.green
              font.pixelSize: 18
              font.family: "Symbols Nerd Font"
            }

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 34
              anchors.right: disconnectBtn.left
              anchors.rightMargin: 10
              anchors.verticalCenter: parent.verticalCenter
              text: WirelessManager.connectedNetwork ? WirelessManager.connectedNetwork.ssid : ""
              color: Colors.text
              font.pixelSize: 15
              elide: Text.ElideRight
            }

            Text {
              id: disconnectBtn
              anchors.right: parent.right
              anchors.rightMargin: 10
              anchors.verticalCenter: parent.verticalCenter
              text: "󰅖"
              color: disconnectArea.containsMouse ? Colors.red : Colors.overlay0
              font.pixelSize: 16
              font.family: "Symbols Nerd Font"

              MouseArea {
                id: disconnectArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: WirelessManager.disconnect()
              }
            }
          }

          // Connection info
          Column {
            anchors.left: parent.left
            anchors.leftMargin: 10
            spacing: 2

            Text {
              text: "Uptime: " + WirelessManager.getConnectionDurationLong()
              color: Colors.overlay0
              font.pixelSize: 14
            }

            Text {
              text: "Down: " + WirelessManager.formatSpeed(WirelessManager.downloadSpeed) + "  Up: " + WirelessManager.formatSpeed(WirelessManager.uploadSpeed)
              color: Colors.overlay0
              font.pixelSize: 14
            }
          }
        }

        // Networks header
        Item {
          width: parent.width
          height: 20
          visible: WirelessManager.enabled

          Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: WirelessManager.scanning ? "Scanning..." : "Networks"
              color: Colors.overlay0
              font.pixelSize: 14
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "󰔟"
              color: Colors.blue
              font.pixelSize: 14
              font.family: "Symbols Nerd Font"
              visible: WirelessManager.scanning

              RotationAnimation on rotation {
                running: WirelessManager.scanning
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
              }
            }
          }

          // Refresh button
          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "󰑐"
            color: refreshArea.containsMouse ? Colors.blue : Colors.overlay0
            font.pixelSize: 16
            font.family: "Symbols Nerd Font"
            visible: !WirelessManager.scanning

            MouseArea {
              id: refreshArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: WirelessManager.startScan()
            }
          }
        }

        // Network list (scrollable, max 6 visible)
        ScrollView {
          width: parent.width
          visible: WirelessManager.enabled
          clip: true
          contentWidth: availableWidth

          height: {
            var visibleNetworks = WirelessManager.networks.filter(n => !n.active).length
            if (visibleNetworks === 0) return 40
            var displayCount = Math.min(visibleNetworks, 6)
            return displayCount * 36 + (displayCount - 1) * 2
          }

          Column {
            width: parent.width
            spacing: 2

            Repeater {
              model: WirelessManager.networks.filter(n => !n.active)

              Rectangle {
                required property var modelData
                width: parent.width
                height: 36
                radius: 4
                color: networkArea.containsMouse ? Colors.surface0 : "transparent"

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  text: WirelessManager.getSignalIcon(modelData.signal)
                  color: Colors.overlay0
                  font.pixelSize: 18
                  font.family: "Symbols Nerd Font"
                }

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 34
                  anchors.right: securityIcon.left
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.ssid
                  color: Colors.text
                  font.pixelSize: 15
                  elide: Text.ElideRight
                }

                Text {
                  id: securityIcon
                  anchors.right: parent.right
                  anchors.rightMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.security ? "󰌾" : ""
                  color: Colors.overlay0
                  font.pixelSize: 14
                  font.family: "Symbols Nerd Font"
                }

                MouseArea {
                  id: networkArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: WirelessManager.busy ? Qt.WaitCursor : Qt.PointingHandCursor
                  onClicked: {
                    if (!WirelessManager.busy) {
                      WirelessManager.connect(modelData.ssid)
                    }
                  }
                }
              }
            }

            // Empty state
            Text {
              width: parent.width
              text: WirelessManager.scanning ? "Looking for networks..." : "No networks found"
              color: Colors.overlay0
              font.pixelSize: 14
              horizontalAlignment: Text.AlignHCenter
              visible: WirelessManager.networks.filter(n => !n.active).length === 0
              topPadding: 8
              bottomPadding: 8
            }
          }
        }

        // WiFi off state
        Column {
          width: parent.width
          spacing: 8
          visible: !WirelessManager.enabled

          Text {
            width: parent.width
            text: "Wi-Fi is off"
            color: Colors.overlay0
            font.pixelSize: 15
            horizontalAlignment: Text.AlignHCenter
            topPadding: 8
          }

          Text {
            width: parent.width
            text: "Toggle the switch above to enable"
            color: Colors.overlay1
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            bottomPadding: 8
          }
        }
      }
    }
  }
}
