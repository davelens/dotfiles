import Quickshell
import QtQuick
import "../.."
import "../../core/components"

BarButton {
  id: button

  // Required: screen for popup management
  required property var screen

  // PopupManager passed from shell.qml for singleton consistency
  property var popupManager: PopupManager

  icon: BluetoothManager.getIcon()
  iconColor: BluetoothManager.powered ? Colors.text : Colors.overlay0

  onClicked: {
    var mapped = mapToItem(null, width, 0)
    popupManager.toggle("bluetooth", screen, mapped.x)
  }
}
