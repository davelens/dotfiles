import QtQuick
import Quickshell.Io
import "../.."
import "../../core/components"

BarButton {
  id: button

  property var screen
  property bool inhibited: false

  icon: inhibited ? "󰈈" : "󰈉"
  iconColor: inhibited ? Colors.blue : Colors.text

  Process {
    id: inhibitProc
    command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=User requested", "sleep", "infinity"]
    running: false
  }

  onClicked: {
    inhibited = !inhibited
    if (inhibited) {
      inhibitProc.running = true
    } else {
      inhibitProc.signal(15)  // SIGTERM
    }
  }
}
