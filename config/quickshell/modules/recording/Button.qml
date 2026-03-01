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

  onClicked: {
    stopProcess.command = ["pkill", "-SIGINT", RecordingManager.processName]
    stopProcess.running = true
  }

  // Poll for the configured recording process
  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      checkProcess.command = ["pidof", RecordingManager.processName]
      checkProcess.running = true
    }
  }

  Process {
    id: checkProcess
    onExited: function(exitCode, exitStatus) {
      button.recording = (exitCode === 0)
    }
  }

  Process {
    id: stopProcess
    onExited: function(exitCode, exitStatus) {
      button.recording = false
      copyPathProcess.running = true
    }
  }

  // Copy the absolute path of the latest screencast to clipboard
  Process {
    id: copyPathProcess
    command: ["bash", "-c", "ls -t \"$HOME/Videos/screencasts/\"*.mp4 2>/dev/null | head -1 | tr -d '\\n' | wl-copy"]
  }
}
