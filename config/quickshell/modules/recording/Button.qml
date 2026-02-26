import Quickshell
import Quickshell.Io
import QtQuick
import "../.."
import "../../core/components"

BarButton {
  id: button

  property bool recording: false
  property bool showInBar: recording

  icon: "󰑊"
  iconColor: Colors.red

  onClicked: stopProcess.running = true

  // Poll for gpu-screen-recorder process
  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: checkProcess.running = true
  }

  Process {
    id: checkProcess
    command: ["pidof", "gpu-screen-recorder"]
    onExited: function(exitCode, exitStatus) {
      button.recording = (exitCode === 0)
    }
  }

  Process {
    id: stopProcess
    command: ["pkill", "-SIGINT", "gpu-screen-reco"]
    onExited: function(exitCode, exitStatus) {
      button.recording = false
    }
  }
}
