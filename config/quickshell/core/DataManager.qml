pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Manages the data directory at $XDG_DATA_HOME/quickshell/.
// Each module handles its own defaults copying via ensureStateFile().
Singleton {
  id: dataManager

  readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/quickshell"

  // Whether the data directory exists and is ready for use
  property bool ready: false

  // Get the data file path for a module by ID
  function getStatePath(moduleId) {
    return dataDir + "/" + moduleId + ".json"
  }

  Component.onCompleted: {
    ensureDataDir.running = true
  }

  Process {
    id: ensureDataDir
    command: ["mkdir", "-p", dataManager.dataDir]
    onExited: {
      dataManager.ready = true
    }
  }
}
