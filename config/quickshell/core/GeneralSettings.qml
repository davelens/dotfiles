pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Singleton {
  id: settings

  // Whether settings have loaded
  property bool ready: false

  // Ordered list of module IDs for the settings panel sidebar
  property var settingsCategoryOrder: []

  // Active profile
  property string activeProfile: ""
  property string activeProfileName: ""
  property var profiles: []

  // File-based persistence (general.json lives at dataDir root, not in a profile)
  readonly property string statePath: DataManager.dataDir + "/general.json"
  readonly property string defaultsPath: Quickshell.shellDir + "/core/defaults.json"
  property bool fileReady: false

  // Copy defaults if state file doesn't exist
  Process {
    id: ensureDefaults
    command: ["sh", "-c", "test -f '" + settings.statePath + "' || cp '" + settings.defaultsPath + "' '" + settings.statePath + "'"]
    running: DataManager.dataDirReady
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
      profiles = config.profiles || []

      var profile = config.activeProfile || ""
      var profileName = config.activeProfileName || ""

      if (!profile) {
        // First run or migration: auto-create default profile
        initDefaultProfile()
      } else {
        activeProfile = profile
        activeProfileName = profileName
        DataManager.setActiveProfile(profile)
        ready = true
      }
    } catch (e) {
      console.error("[GeneralSettings] Failed to parse config:", e)
    }
  }

  // Generate a 10-character UUID fragment
  function generateId() {
    var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    var result = ""
    for (var i = 0; i < 10; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }

  // Sanitize a display name into a directory name
  function sanitizeName(displayName) {
    var base = displayName.toLowerCase()
      .replace(/[^a-z0-9\s-]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "")
    if (!base) base = "profile"
    return base + "-" + generateId()
  }

  // First-run: auto-create "Default" profile and migrate existing flat state files
  function initDefaultProfile() {
    activeProfile = "defaults"
    activeProfileName = "Default"
    profiles = [{ name: "Default", dir: "defaults" }]

    // Migrate existing flat state files into defaults/ dir, then save config
    var profilePath = DataManager.dataDir + "/defaults"
    var moduleIds = ["statusbar", "notifications", "display", "recording"]
    var cmds = ["mkdir -p '" + profilePath + "'"]
    for (var i = 0; i < moduleIds.length; i++) {
      var flatFile = DataManager.dataDir + "/" + moduleIds[i] + ".json"
      var profileFile = profilePath + "/" + moduleIds[i] + ".json"
      // Move existing flat file into defaults dir if it exists
      cmds.push("[ -f '" + flatFile + "' ] && mv '" + flatFile + "' '" + profileFile + "'")
    }
    migrationProc.command = ["sh", "-c", cmds.join(" ; ") + " ; true"]
    migrationProc.running = true
  }

  Process {
    id: migrationProc
    onExited: {
      settings.saveConfig()
      DataManager.setActiveProfile(settings.activeProfile)
      settings.ready = true
    }
  }

  // Save current state to general.json
  function saveConfig() {
    var config = {
      settingsCategoryOrder: settingsCategoryOrder,
      activeProfile: activeProfile,
      activeProfileName: activeProfileName,
      profiles: profiles
    }
    saveProc.command = ["sh", "-c", "cat > '" + statePath + "' << 'JSONEOF'\n" + JSON.stringify(config, null, 2) + "\nJSONEOF"]
    saveProc.running = true
  }

  Process {
    id: saveProc
  }

  // Profile IPC: qs ipc call profile {list,current,enable}
  IpcHandler {
    target: "profile"

    function list(): string {
      var names = []
      for (var i = 0; i < settings.profiles.length; i++) {
        names.push(settings.profiles[i].name)
      }
      return names.join("\n")
    }

    function current(): string {
      return settings.activeProfileName
    }

    function enable(displayName: string): void {
      for (var i = 0; i < settings.profiles.length; i++) {
        if (settings.profiles[i].name === displayName) {
          settings.switchProfile(settings.profiles[i].dir)
          return
        }
      }
    }
  }

  // Create a new profile by copying the current profile's state
  function createProfile(displayName) {
    var dir = sanitizeName(displayName)
    var sourcePath = DataManager.profileDir
    var targetPath = DataManager.dataDir + "/" + dir

    var newProfiles = profiles.slice()
    newProfiles.push({ name: displayName, dir: dir })
    profiles = newProfiles

    // Copy current profile state to new profile
    createProfileProc.newDir = dir
    createProfileProc.newName = displayName
    createProfileProc.command = ["sh", "-c", "mkdir -p '" + targetPath + "' && cp '" + sourcePath + "'/*.json '" + targetPath + "/' 2>/dev/null ; true"]
    createProfileProc.running = true
  }

  Process {
    id: createProfileProc
    property string newDir: ""
    property string newName: ""
    onExited: {
      // Auto-switch to the new profile
      settings.switchProfile(newDir)
    }
  }

  // Switch to a different profile
  function switchProfile(profileDir) {
    activeProfile = profileDir
    // Find the display name
    for (var i = 0; i < profiles.length; i++) {
      if (profiles[i].dir === profileDir) {
        activeProfileName = profiles[i].name
        break
      }
    }
    saveConfig()

    // Tell DataManager to switch paths; this triggers ready = false then true
    DataManager.setActiveProfile(profileDir)
  }

  // Delete a profile (cannot delete the default profile or the active profile)
  function deleteProfile(profileDir) {
    // Guard: cannot delete the first profile (default)
    if (profiles.length > 0 && profiles[0].dir === profileDir) return
    // Guard: cannot delete active profile
    if (profileDir === activeProfile) return

    var newProfiles = profiles.filter(function(p) { return p.dir !== profileDir })
    profiles = newProfiles
    saveConfig()

    // Remove the profile directory
    var targetPath = DataManager.dataDir + "/" + profileDir
    deleteProfileProc.command = ["rm", "-rf", targetPath]
    deleteProfileProc.running = true
  }

  Process {
    id: deleteProfileProc
  }
}
