import QtQuick
import "../.."
import "../../core/components"

BarButton {
  id: button

  icon: IdleInhibitorManager.inhibited ? "󰈈" : "󰈉"
  iconColor: IdleInhibitorManager.inhibited ? Colors.blue : Colors.text

  onClicked: {
    IdleInhibitorManager.toggle()
  }
}
