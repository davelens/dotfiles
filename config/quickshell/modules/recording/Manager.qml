pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../.."

Singleton {
  id: recordingManager

  // Persisted setting
  property alias processName: settingsAdapter.processName

  // File-based persistence
  readonly property string statePath: DataManager.getStatePath("recording")
  readonly property string defaultsPath: Quickshell.shellDir + "/modules/recording/defaults.json"
  property bool fileReady: false

  // Copy defaults if state file doesn't exist
  Process {
    id: ensureDefaults
    command: ["sh", "-c", "test -f '" + recordingManager.statePath + "' || cp '" + recordingManager.defaultsPath + "' '" + recordingManager.statePath + "'"]
    running: DataManager.ready
    onExited: { recordingManager.fileReady = true }
  }

  FileView {
    id: settingsFile
    path: recordingManager.fileReady ? recordingManager.statePath : ""

    // Reload file when it changes on disk
    watchChanges: true
    onFileChanged: reload()

    // Save when adapter properties change
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: settingsAdapter
      property string processName: "gpu-screen-recorder"
    }
  }
}
