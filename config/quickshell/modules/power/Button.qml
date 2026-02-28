import QtQuick
import Quickshell.Io
import "../.."
import "../../core/components"

BarButton {
  icon: "󰐥"
  iconColor: Colors.blue

  Process {
    id: powerMenuProc
    command: ["sh", "-c", "~/.local/bin/rofi-start --powermenu"]
    running: false
  }

  onClicked: powerMenuProc.running = true
}
