pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Singleton {
  id: settings

  // Whether settings have loaded
  property bool ready: false

  // Ordered list of module IDs for the settings panel sidebar.
  // Modules not listed here appear after listed ones, sorted by their
  // module.json order field.
  property var settingsCategoryOrder: []

  // File-based persistence
  readonly property string statePath: DataManager.getStatePath("general")
  readonly property string defaultsPath: Quickshell.shellDir + "/core/defaults.json"
  property bool fileReady: false

  // Copy defaults if state file doesn't exist
  Process {
    id: ensureDefaults
    command: ["sh", "-c", "test -f '" + settings.statePath + "' || cp '" + settings.defaultsPath + "' '" + settings.statePath + "'"]
    running: DataManager.ready
    onExited: { settings.fileReady = true }
  }

  FileView {
    id: configFile
    path: settings.fileReady ? settings.statePath : ""
    watchChanges: true
    onFileChanged: reload()

    onLoaded: {
      settings.parseConfig(configFile.text())
    }

    onLoadFailed: error => {
      console.error("[GeneralSettings] Failed to load config:", error)
    }
  }

  function parseConfig(text) {
    if (!text || text.trim() === "") return

    try {
      var config = JSON.parse(text)
      settingsCategoryOrder = config.settingsCategoryOrder || []
      ready = true
    } catch (e) {
      console.error("[GeneralSettings] Failed to parse config:", e)
    }
  }
}
