pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../.."

Singleton {
  id: manager

  // Persisted settings
  property string backend: "auto"
  property bool autoDetect: false
  property string displayMode: "icons"
  property int count: 5
  property var icons: ({})

  // Resolved backend name ("sway" or "niri") based on auto-detection or explicit setting
  readonly property string resolvedBackend: {
    if (backend !== "auto") return backend
    return detectedCompositor
  }

  // Auto-detect compositor from environment
  readonly property string detectedCompositor: {
    var swaysock = Quickshell.env("SWAYSOCK")
    if (swaysock) return "sway"
    var i3sock = Quickshell.env("I3SOCK")
    if (i3sock) return "sway"
    var niriSocket = Quickshell.env("NIRI_SOCKET")
    if (niriSocket) return "niri"
    return "sway"
  }

  // File-based persistence
  readonly property string statePath: DataManager.getStatePath("workspaces")
  readonly property string defaultsPath: DataManager.getDefaultsPath("workspaces")
  property bool fileReady: false

  // Copy defaults if state file doesn't exist
  Process {
    id: ensureDefaults
    command: ["sh", "-c", "test -f '" + manager.statePath + "' || cp '" + manager.defaultsPath + "' '" + manager.statePath + "'"]
    running: DataManager.ready
    onExited: { manager.fileReady = true }
  }

  // Config file watcher
  FileView {
    id: configFile
    path: manager.fileReady ? manager.statePath : ""
    watchChanges: true
    onFileChanged: reload()

    onLoaded: {
      manager.parseConfig(configFile.text())
    }

    onLoadFailed: error => {
      console.error("[WorkspacesManager] Failed to load config:", error)
    }
  }

  function parseConfig(text) {
    if (!text || text.trim() === "") return

    try {
      var config = JSON.parse(text)
      backend = config.backend || "auto"
      autoDetect = config.autoDetect || false
      displayMode = config.displayMode || "icons"
      count = config.count || 5
      icons = config.icons || {}
    } catch (e) {
      console.error("[WorkspacesManager] Failed to parse config:", e)
    }
  }

  function setBackend(value) {
    backend = value
    saveConfig()
  }

  function setAutoDetect(enabled) {
    autoDetect = enabled
    saveConfig()
  }

  function setDisplayMode(mode) {
    displayMode = mode
    saveConfig()
  }

  function setCount(n) {
    count = Math.max(1, Math.min(10, n))
    saveConfig()
  }

  function setIcon(workspace, icon) {
    var updated = Object.assign({}, icons)
    updated[workspace] = icon
    icons = updated
    saveConfig()
  }

  function saveConfig() {
    var config = {
      backend: backend,
      autoDetect: autoDetect,
      displayMode: displayMode,
      count: count,
      icons: icons
    }
    saveProc.configJson = JSON.stringify(config, null, 2)
    saveProc.running = true
  }

  Process {
    id: saveProc
    property string configJson: ""
    command: ["sh", "-c", "cat > " + manager.statePath + " << 'WORKSPACES_EOF'\n" + configJson + "\nWORKSPACES_EOF"]
    onExited: (code) => {
      if (code !== 0) {
        console.error("[WorkspacesManager] Failed to save config")
      }
    }
  }
}
