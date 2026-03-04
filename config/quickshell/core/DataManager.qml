pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import ".."

// Manages the data directory at $XDG_DATA_HOME/quickshell/.
// Provides profile-aware state paths and centralized defaults management.
//
// Bootstrap sequence:
//   1. Creates dataDir and defaultsDir (mkdir -p)
//   2. dataDirReady = true
//   3. GeneralSettings loads general.json, calls setActiveProfile(dir)
//   4. Once ModuleRegistry.ready, copies repo defaults into defaultsDir
//   5. Creates profile directory
//   6. ready = true (all modules can now load state)
Singleton {
  id: dataManager

  readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/quickshell"
  readonly property string defaultsDir: dataDir + "/defaults"

  // Active profile directory name (set by GeneralSettings)
  property string activeProfileDir: ""
  readonly property string profileDir: dataDir + "/" + activeProfileDir

  // Stage 1: data directory and defaults directory exist
  property bool dataDirReady: false

  // Stage 2: repo defaults copied to defaultsDir
  property bool defaultsReady: false

  // Stage 3: profile directory exists, all state paths are valid
  property bool ready: false

  // Get the state file path for a module within the active profile
  function getStatePath(moduleId) {
    return profileDir + "/" + moduleId + ".json"
  }

  // Get the defaults file path for a module
  function getDefaultsPath(moduleId) {
    return defaultsDir + "/" + moduleId + ".json"
  }

  // Called by GeneralSettings once the active profile is known.
  // Also called when switching profiles (ready cycles false -> true).
  function setActiveProfile(dir) {
    ready = false
    activeProfileDir = dir
    // If defaults are already copied, create profile dir immediately
    if (defaultsReady) {
      ensureProfileDir.command = ["mkdir", "-p", dataManager.profileDir]
      ensureProfileDir.running = true
    }
  }

  Component.onCompleted: {
    ensureDataDir.running = true
  }

  // Stage 1: create dataDir and defaultsDir
  Process {
    id: ensureDataDir
    command: ["mkdir", "-p", dataManager.dataDir, dataManager.defaultsDir]
    onExited: {
      dataManager.dataDirReady = true
    }
  }

  // Stage 2: copy repo defaults into defaultsDir (needs ModuleRegistry.ready)
  // Triggered when both dataDirReady and ModuleRegistry.ready
  property bool _copyTriggered: false
  onDataDirReadyChanged: tryStartDefaultsCopy()
  Connections {
    target: ModuleRegistry
    function onReadyChanged() { dataManager.tryStartDefaultsCopy() }
  }

  function tryStartDefaultsCopy() {
    if (_copyTriggered || !dataDirReady || !ModuleRegistry.ready) return
    _copyTriggered = true

    var cmds = []
    var modules = ModuleRegistry.modules
    for (var i = 0; i < modules.length; i++) {
      var m = modules[i]
      var repoDefaults = m.path + "/defaults.json"
      var targetDefaults = defaultsDir + "/" + m.id + ".json"
      cmds.push("[ -f '" + repoDefaults + "' ] && [ ! -f '" + targetDefaults + "' ] && cp '" + repoDefaults + "' '" + targetDefaults + "'")
    }

    if (cmds.length > 0) {
      copyRepoDefaults.command = ["sh", "-c", cmds.join(" ; ") + " ; true"]
      copyRepoDefaults.running = true
    } else {
      dataManager.defaultsReady = true
    }
  }

  Process {
    id: copyRepoDefaults
    onExited: {
      dataManager.defaultsReady = true
      // If activeProfileDir was already set, create profile dir now
      if (dataManager.activeProfileDir) {
        ensureProfileDir.command = ["mkdir", "-p", dataManager.profileDir]
        ensureProfileDir.running = true
      }
    }
  }

  // Stage 3: create profile directory
  Process {
    id: ensureProfileDir
    onExited: {
      dataManager.ready = true
    }
  }
}
