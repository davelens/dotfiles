import Quickshell
import Quickshell.Io
import QtQuick
import "../.."
import "../../core/components"

BarButton {
  id: button

  property bool recording: false
  property bool stopping: false
  property bool showInBar: recording

  icon: "󰑊"
  iconColor: Colors.red

  onClicked: {
    stopping = true
    recording = false
    stopProcess.command = ["pkill", "-f", "-SIGINT", RecordingManager.processName]
    stopProcess.running = true
  }

  // Poll for the configured recording process
  Timer {
    interval: 2000
    running: !button.stopping
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

  // Wait for the process to actually exit before resuming polling
  Process {
    id: stopProcess
    onExited: function(exitCode, exitStatus) {
      waitProcess.command = ["bash", "-c", "while pidof " + RecordingManager.processName + " > /dev/null 2>&1; do sleep 0.2; done"]
      waitProcess.running = true
    }
  }

  // Once the process has fully exited, copy the path and resume polling
  Process {
    id: waitProcess
    onExited: function(exitCode, exitStatus) {
      button.recording = false
      button.stopping = false
      copyPathProcess.running = true
    }
  }

  // Copy the absolute path of the latest screencast to clipboard
  Process {
    id: copyPathProcess
    command: ["bash", "-c", "ls -t \"$HOME/Videos/screencasts/\"*.mp4 2>/dev/null | head -1 | tr -d '\\n' | wl-copy"]
  }
}
