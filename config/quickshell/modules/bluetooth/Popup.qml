import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../.."
import "../../core/components"

Variants {
  id: bluetoothPopup

  property bool isOpen: PopupManager.isOpen("bluetooth")

  // Start/stop scan when popup opens/closes
  onIsOpenChanged: {
    if (isOpen && BluetoothManager.powered) {
      BluetoothManager.startScan()
    } else {
      BluetoothManager.stopScan()
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
        if (event.key === Qt.Key_Escape) {
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

        if (!BluetoothManager.powered) {
          h += 50
        } else {
          var connectedCount = BluetoothManager.connectedDevices.length
          if (connectedCount > 0) {
            h += 16 + 4 + connectedCount * 36 + (connectedCount - 1) * 4 + 12
          }

          h += 20 + 12

          var visibleDevices = BluetoothManager.devices.filter(d => !d.connected).length
          if (visibleDevices > 0) {
            var displayCount = Math.min(visibleDevices, 6)
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
            text: BluetoothManager.getIcon()
            color: BluetoothManager.powered ? Colors.blue : Colors.overlay0
            font.pixelSize: 20
            font.family: "Symbols Nerd Font"
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Bluetooth"
            color: Colors.text
            font.pixelSize: 16
          }

          Item { width: parent.width - 140; height: 1 }

          SwitchToggle {
            anchors.verticalCenter: parent.verticalCenter
            checked: BluetoothManager.powered
            onClicked: BluetoothManager.togglePower()
          }
        }

        // Separator
        Rectangle {
          width: parent.width
          height: 1
          color: Colors.surface1
          visible: BluetoothManager.powered
        }

        // Connected devices
        Column {
          width: parent.width
          spacing: 4
          visible: BluetoothManager.connectedDevices.length > 0

          Text {
            text: "Connected devices"
            color: Colors.overlay0
            font.pixelSize: 14
          }

          Repeater {
            model: BluetoothManager.connectedDevices

            Rectangle {
              required property var modelData
              required property int index
              width: parent.width
              height: 36
              radius: 4
              color: Colors.surface1

              Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "󰂱"
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
                text: modelData.name
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
                  onClicked: BluetoothManager.disconnect(modelData.address)
                }
              }
            }
          }
        }

        // Scanning indicator / devices header
        Item {
          width: parent.width
          height: 20
          visible: BluetoothManager.powered

          Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: BluetoothManager.scanning ? "Scanning..." : "Devices"
              color: Colors.overlay0
              font.pixelSize: 14
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "󰔟"
              color: Colors.blue
              font.pixelSize: 14
              font.family: "Symbols Nerd Font"
              visible: BluetoothManager.scanning

              RotationAnimation on rotation {
                running: BluetoothManager.scanning
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
            visible: !BluetoothManager.scanning

            MouseArea {
              id: refreshArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: BluetoothManager.startScan()
            }
          }
        }

        // Device list (scrollable, max 6 visible)
        ScrollView {
          width: parent.width
          visible: BluetoothManager.powered
          clip: true
          contentWidth: availableWidth

          height: {
            var visibleDevices = BluetoothManager.devices.filter(d => !d.connected).length
            if (visibleDevices === 0) return 40
            var displayCount = Math.min(visibleDevices, 6)
            return displayCount * 36 + (displayCount - 1) * 2
          }

          Column {
            width: parent.width
            spacing: 2

            Repeater {
              model: BluetoothManager.devices

              Rectangle {
                required property var modelData
                width: parent.width
                height: 36
                radius: 4
                color: deviceArea.containsMouse ? Colors.surface0 : "transparent"

                visible: !modelData.connected

                Row {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 10

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.paired ? "󰂰" : "󰂯"
                    color: modelData.paired ? Colors.blue : Colors.overlay0
                    font.pixelSize: 18
                    font.family: "Symbols Nerd Font"
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    color: Colors.text
                    font.pixelSize: 15
                    width: parent.width - 50
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: deviceArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: BluetoothManager.busy ? Qt.WaitCursor : Qt.PointingHandCursor
                  onClicked: {
                    if (!BluetoothManager.busy) {
                      BluetoothManager.connect(modelData.address)
                    }
                  }
                }
              }
            }

            // Empty state
            Text {
              width: parent.width
              text: BluetoothManager.scanning ? "Looking for devices..." : "No devices found"
              color: Colors.overlay0
              font.pixelSize: 14
              horizontalAlignment: Text.AlignHCenter
              visible: BluetoothManager.devices.length === 0
              topPadding: 8
              bottomPadding: 8
            }
          }
        }

        // Bluetooth off state
        Column {
          width: parent.width
          spacing: 8
          visible: !BluetoothManager.powered

          Text {
            width: parent.width
            text: "Bluetooth is off"
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
