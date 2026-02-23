import Quickshell
import QtQuick
import "../.."
import "../../core/components"

BarButton {
  popupId: "bluetooth"
  icon: BluetoothManager.getIcon()
  iconColor: BluetoothManager.powered ? Colors.text : Colors.overlay0
}
