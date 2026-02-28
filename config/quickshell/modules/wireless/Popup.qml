import Quickshell
import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

Variants {
  id: wirelessPopup

  property bool isOpen: PopupManager.isOpen("wireless")

  // Start scan when popup opens, clear pending state when it closes
  onIsOpenChanged: {
    if (isOpen && WirelessManager.enabled) {
      WirelessManager.startScan()
    } else if (!isOpen) {
      WirelessManager.cancelPending()
    }
  }

  model: isOpen && DisplayConfig.primaryScreen
         ? [DisplayConfig.primaryScreen] : []

  PopupBase {
    popupWidth: 380
    contentSpacing: 12

    popupHeight: {
      // Header (28) + spacing (12) + separator (1) + spacing (12)
      var h = 28 + 12 + 1 + 12

      if (!WirelessManager.enabled) {
        h += 50
      } else {
        if (WirelessManager.connectedNetwork) {
          // Label (16) + spacing (6) + row (36) + spacing (6) + info (32) + spacing (12)
          // + separator (1) + spacing (12)
          h += 16 + 6 + 36 + 6 + 32 + 12 + 1 + 12
        }

        h += 20 + 12

        var visibleNetworks = WirelessManager.networks.filter(n => !n.active).length
        if (visibleNetworks > 0) {
          var displayCount = Math.min(visibleNetworks, 6)
          h += displayCount * 36 + (displayCount - 1) * 2
          // Password input row: padding (4) + input (36) + spacing (4) + optional error (20)
          if (WirelessManager.pendingSSID) {
            h += 44
            if (WirelessManager.connectError) h += 20
          }
        } else {
          h += 40
        }
      }

      return h + 48
    }

    // Header with power toggle
    Item {
      width: parent.width
      height: 28

      Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
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
      }

      SwitchToggle {
        anchors.right: parent.right
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

      FocusListItem {
        itemHeight: 36
        bodyMargins: 0
        bodyRadius: 4
        icon: WirelessManager.getIcon()
        iconSize: 18
        iconColor: Colors.green
        text: WirelessManager.connectedNetwork ? WirelessManager.connectedNetwork.ssid : ""
        fontSize: 15
        rightIcon: "󰅖"
        rightIconColor: Colors.overlay0
        rightIconHoverColor: Colors.red
        backgroundColor: Colors.surface1
        hoverBackgroundColor: Colors.surface1
        onClicked: WirelessManager.disconnect()
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

    Rectangle {
      width: parent.width
      height: 1
      color: Colors.surface1
      visible: WirelessManager.connectedNetwork !== null
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
          text: WirelessManager.scanning ? "Scanning..." : "Available networks"
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

      FocusIconButton {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        icon: "󰑐"
        iconSize: 16
        hoverColor: Colors.blue
        visible: !WirelessManager.scanning
        onClicked: WirelessManager.startScan()
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
        var h = displayCount * 36 + (displayCount - 1) * 2
        if (WirelessManager.pendingSSID) {
          h += 44
          if (WirelessManager.connectError) h += 20
        }
        return h
      }

      Column {
        width: parent.width
        spacing: 2

        Repeater {
          model: WirelessManager.networks.filter(n => !n.active)

          Column {
            required property var modelData

            width: parent.width
            spacing: 0

            property bool isPending: WirelessManager.pendingSSID === modelData.ssid

            FocusListItem {
              property bool isConnecting: WirelessManager.connectingSSID === modelData.ssid

              itemHeight: 36
              bodyMargins: 0
              bodyRadius: 4
              icon: WirelessManager.getSignalIcon(modelData.signal)
              iconSize: 18
              iconColor: isConnecting ? Colors.blue : Colors.overlay0
              text: isConnecting ? modelData.ssid + "  —  Connecting..." : modelData.ssid
              fontSize: 15
              rightIcon: modelData.security ? "󰌾" : ""
              hoverBackgroundColor: Colors.surface0
              onClicked: {
                if (!WirelessManager.busy) WirelessManager.connect(modelData.ssid)
              }
            }

            // Inline password input
            Column {
              id: passwordColumn
              width: parent.width
              spacing: 4
              visible: parent.isPending
              topPadding: 4

              onVisibleChanged: {
                if (visible) {
                  passwordInput.text = ""
                  WirelessManager.connectError = ""
                  passwordInput.forceActiveFocus()
                }
              }

              Rectangle {
                width: parent.width
                height: 36
                radius: 4
                color: Colors.surface0
                border.width: 1
                border.color: passwordInput.activeFocus ? Colors.blue : Colors.surface1

                Row {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 4
                  spacing: 4

                  TextInput {
                    id: passwordInput
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - toggleVisibility.width - connectBtn.width - 12
                    color: Colors.text
                    font.pixelSize: 14
                    clip: true
                    echoMode: TextInput.Password

                    Text {
                      anchors.fill: parent
                      anchors.verticalCenter: parent.verticalCenter
                      text: "Enter password"
                      color: Colors.overlay0
                      font.pixelSize: 14
                      visible: !passwordInput.text && !passwordInput.activeFocus
                    }

                    Keys.onReturnPressed: {
                      if (passwordInput.text) {
                        WirelessManager.connect(modelData.ssid, passwordInput.text)
                      }
                    }
                    Keys.onEnterPressed: {
                      if (passwordInput.text) {
                        WirelessManager.connect(modelData.ssid, passwordInput.text)
                      }
                    }
                    Keys.onEscapePressed: WirelessManager.cancelPending()
                  }

                  // Show/hide password toggle
                  Text {
                    id: toggleVisibility
                    anchors.verticalCenter: parent.verticalCenter
                    text: passwordInput.echoMode === TextInput.Password ? "󰈈" : "󰈉"
                    color: toggleMouse.containsMouse ? Colors.text : Colors.overlay0
                    font.pixelSize: 16
                    font.family: "Symbols Nerd Font"
                    width: 28
                    horizontalAlignment: Text.AlignHCenter

                    MouseArea {
                      id: toggleMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        passwordInput.echoMode = passwordInput.echoMode === TextInput.Password
                          ? TextInput.Normal
                          : TextInput.Password
                      }
                    }
                  }

                  // Connect button
                  Rectangle {
                    id: connectBtn
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 4
                    color: connectBtnMouse.containsMouse && passwordInput.text
                      ? Colors.blue : "transparent"

                    Text {
                      anchors.centerIn: parent
                      text: "󰁔"
                      color: passwordInput.text
                        ? (connectBtnMouse.containsMouse ? Colors.base : Colors.blue)
                        : Colors.surface2
                      font.pixelSize: 16
                      font.family: "Symbols Nerd Font"
                    }

                    MouseArea {
                      id: connectBtnMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: passwordInput.text ? Qt.PointingHandCursor : Qt.ArrowCursor
                      onClicked: {
                        if (passwordInput.text) {
                          WirelessManager.connect(modelData.ssid, passwordInput.text)
                        }
                      }
                    }
                  }
                }
              }

              // Error message
              Text {
                width: parent.width
                text: WirelessManager.connectError
                color: Colors.red
                font.pixelSize: 12
                leftPadding: 10
                visible: WirelessManager.connectError !== ""
              }
            }
          }
        }

        // Empty state
        BodyText {
          width: parent.width
          text: WirelessManager.scanning ? "Looking for networks..." : "No networks found"
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
