import Quickshell
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

  PopupBase {
    popupWidth: 380
    contentSpacing: 12

    popupHeight: {
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
      }

      SwitchToggle {
        anchors.right: parent.right
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

        FocusListItem {
          required property var modelData

          itemHeight: 36
          bodyMargins: 0
          bodyRadius: 4
          icon: "󰂱"
          iconSize: 18
          iconColor: Colors.green
          text: modelData.name
          fontSize: 15
          rightIcon: "󰅖"
          rightIconColor: Colors.overlay0
          rightIconHoverColor: Colors.red
          backgroundColor: Colors.surface1
          hoverBackgroundColor: Colors.surface1
          onClicked: BluetoothManager.disconnect(modelData.address)
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
          text: BluetoothManager.scanning ? "Scanning..." : "Available devices"
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

      FocusIconButton {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        icon: "󰑐"
        iconSize: 16
        hoverColor: Colors.blue
        visible: !BluetoothManager.scanning
        onClicked: BluetoothManager.startScan()
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

          FocusListItem {
            required property var modelData

            visible: !modelData.connected
            itemHeight: 36
            bodyMargins: 0
            bodyRadius: 4
            icon: modelData.paired ? "󰂰" : "󰂯"
            iconSize: 18
            iconColor: modelData.paired ? Colors.blue : Colors.overlay0
            text: modelData.name
            fontSize: 15
            hoverBackgroundColor: Colors.surface0
            onClicked: {
              if (!BluetoothManager.busy) BluetoothManager.connect(modelData.address)
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
